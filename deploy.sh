#!/bin/bash

# Claude Code Nexus 部署脚本 - 日本预发环境
# 服务器: 103.53.81.33
# 域名: https://claudeapi.satoshitech.xyz

set -e

echo "🚀 开始部署 Claude Code Nexus 到日本预发服务器..."

# 服务器配置
SERVER_IP="103.53.81.33"
SERVER_USER="root"
SERVER_PASSWORD="Zhxc6545398@"
APP_NAME="claude-code-nexus"
DEPLOY_PATH="/root/claude-code-nexus"
DOMAIN="claudeapi.satoshitech.xyz"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# 检查本地环境
check_local_env() {
    log "检查本地环境..."
    
    if ! command -v sshpass &> /dev/null; then
        warn "sshpass 未安装，将使用交互式SSH连接"
    fi
    
    if ! command -v rsync &> /dev/null; then
        error "rsync 未安装，请先安装: brew install rsync"
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        error "docker-compose.yml 文件不存在"
    fi
    
    info "本地环境检查完成"
}

# 连接到服务器并执行命令
ssh_exec() {
    local cmd="$1"
    if command -v sshpass &> /dev/null; then
        sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$cmd"
    else
        ssh "$SERVER_USER@$SERVER_IP" "$cmd"
    fi
}

# 上传文件到服务器
upload_files() {
    log "上传项目文件到服务器..."
    
    # 创建部署目录
    ssh_exec "mkdir -p $DEPLOY_PATH"
    
    # 排除不必要的文件
    local rsync_excludes=(
        "--exclude=node_modules"
        "--exclude=dist"
        "--exclude=.git"
        "--exclude=logs"
        "--exclude=*.log"
        "--exclude=.DS_Store"
        "--exclude=.env"
        "--exclude=.env.local"
        "--exclude=changes/"
        "--exclude=*.tar.gz"
    )
    
    if command -v sshpass &> /dev/null; then
        rsync -avz --progress "${rsync_excludes[@]}" \
            -e "sshpass -p $SERVER_PASSWORD ssh -o StrictHostKeyChecking=no" \
            ./ "$SERVER_USER@$SERVER_IP:$DEPLOY_PATH/"
    else
        rsync -avz --progress "${rsync_excludes[@]}" \
            ./ "$SERVER_USER@$SERVER_IP:$DEPLOY_PATH/"
    fi
    
    info "文件上传完成"
}

# 在服务器上部署
deploy_on_server() {
    log "在服务器上执行部署..."
    
    ssh_exec "cd $DEPLOY_PATH && cat > deploy_server.sh << 'EOF'
#!/bin/bash
set -e

echo '🐳 检查 Docker 环境...'
if ! command -v docker &> /dev/null; then
    echo '安装 Docker...'
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo '安装 Docker Compose...'
    curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo '🛑 停止旧容器 (如果存在)...'
docker-compose down || true
docker system prune -f || true

echo '🏗️ 构建并启动新容器...'
docker-compose up -d --build

echo '⏳ 等待服务启动...'
sleep 30

echo '🔍 检查服务状态...'
docker-compose ps
docker-compose logs --tail=50 claude-code-nexus

echo '🩺 健康检查...'
if curl -f http://localhost:3009/api/health > /dev/null 2>&1; then
    echo '✅ 服务启动成功！'
else
    echo '❌ 服务启动失败，查看日志:'
    docker-compose logs claude-code-nexus
    exit 1
fi
EOF"

    ssh_exec "cd $DEPLOY_PATH && chmod +x deploy_server.sh && ./deploy_server.sh"
    
    info "服务器部署完成"
}

# 配置 Caddy 反向代理
configure_caddy() {
    log "配置 Caddy 反向代理..."
    
    ssh_exec "cat > /etc/caddy/conf.d/${APP_NAME}.conf << 'EOF'
$DOMAIN {
    reverse_proxy localhost:3009
    
    # 健康检查
    handle /api/health {
        reverse_proxy localhost:3009
    }
    
    # 静态资源缓存
    handle /assets/* {
        reverse_proxy localhost:3009
        header Cache-Control \"public, max-age=31536000\"
    }
    
    # 安全头
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        -Server
    }
    
    # 日志
    log {
        output file /var/log/caddy/${APP_NAME}.log {
            roll_size 100MiB
            roll_keep 5
        }
    }
}
EOF"
    
    # 重新加载 Caddy 配置
    ssh_exec "caddy reload"
    
    info "Caddy 反向代理配置完成"
}

# 验证部署
verify_deployment() {
    log "验证部署结果..."
    
    # 检查容器状态
    info "检查容器状态..."
    ssh_exec "docker-compose -f $DEPLOY_PATH/docker-compose.yml ps"
    
    # 检查健康状态
    info "检查服务健康状态..."
    if ssh_exec "curl -f http://localhost:3009/api/health"; then
        info "✅ 本地健康检查通过"
    else
        error "❌ 本地健康检查失败"
    fi
    
    # 检查域名访问
    info "检查域名访问..."
    sleep 5  # 等待 Caddy 配置生效
    if curl -f "https://$DOMAIN/api/health" > /dev/null 2>&1; then
        info "✅ 域名访问检查通过"
    else
        warn "⚠️ 域名访问可能需要稍等片刻生效"
    fi
    
    # 显示部署信息
    echo ""
    log "🎉 部署完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🌐 应用访问地址: https://$DOMAIN${NC}"
    echo -e "${BLUE}🔧 服务器地址: $SERVER_IP${NC}"
    echo -e "${BLUE}📊 本地端口: 3009${NC}"
    echo -e "${BLUE}🐳 容器名称: $APP_NAME${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 访问 https://$DOMAIN 测试应用"
    echo "2. 使用 GitHub 登录测试 OAuth"
    echo "3. 配置 API 提供商"
    echo "4. 测试 Claude Code CLI 集成"
    echo ""
    echo "🔍 监控命令:"
    echo "- 查看日志: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose logs -f'"
    echo "- 重启服务: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose restart'"
    echo ""
}

# 主执行流程
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Claude Code Nexus 部署脚本"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 目标服务器: $SERVER_IP"
    echo "🌐 域名: $DOMAIN"
    echo "📦 容器端口: 3009"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "确认开始部署? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "部署已取消"
        exit 0
    fi
    
    check_local_env
    upload_files
    deploy_on_server
    configure_caddy
    verify_deployment
}

# 执行主流程
main "$@"