#!/bin/bash

# Claude Code Nexus 自动部署脚本
# 目标: 日本预发服务器 /root/02-production
# 服务器: 103.53.81.33
# 域名: https://claudeapi.satoshitech.xyz

set -e

# 配置信息
SERVER_IP="103.53.81.33"
SERVER_USER="root"
SERVER_PASSWORD="Zhxc6545398@"
DEPLOY_PATH="/root/02-production/claude-code-nexus"
PROJECT_NAME="claude-code-nexus"
DOMAIN="claudeapi.satoshitech.xyz"
CONTAINER_PORT="3009"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
step() { echo -e "${CYAN}[STEP] $1${NC}"; }

# SSH执行函数
ssh_exec() {
    local cmd="$1"
    if command -v sshpass &> /dev/null; then
        sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$cmd"
    else
        echo "需要手动输入密码: $SERVER_PASSWORD"
        ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$cmd"
    fi
}

# 显示部署信息
show_deploy_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}🚀 Claude Code Nexus 自动部署脚本${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}📍 目标服务器:${NC} $SERVER_IP"
    echo -e "${GREEN}📂 部署目录:${NC} $DEPLOY_PATH"
    echo -e "${GREEN}🌐 域名:${NC} https://$DOMAIN"
    echo -e "${GREEN}🐳 容器端口:${NC} $CONTAINER_PORT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 检查本地环境
check_local_env() {
    step "检查本地环境"
    
    # 检查必要文件
    local required_files=("docker-compose.yml" "Dockerfile" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            error "缺少必要文件: $file"
        fi
    done
    
    # 检查工具
    if ! command -v rsync &> /dev/null; then
        error "rsync 未安装，请安装: brew install rsync"
    fi
    
    info "本地环境检查通过"
}

# 创建部署包
create_deploy_package() {
    step "创建部署包"
    
    local package_name="${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    tar -czf "$package_name" \
        --exclude=node_modules \
        --exclude=dist \
        --exclude=.git \
        --exclude=logs \
        --exclude='*.log' \
        --exclude=.DS_Store \
        --exclude=.env \
        --exclude=.env.local \
        --exclude=changes/ \
        --exclude='*.tar.gz' \
        --exclude=claude-code-nexus-deploy.tar.gz \
        .
    
    echo "$package_name"
}

# 上传文件到服务器
upload_to_server() {
    local package_name="$1"
    step "上传部署包到服务器"
    
    # 创建服务器目录结构
    ssh_exec "mkdir -p /root/02-production"
    
    # 上传部署包
    if command -v sshpass &> /dev/null; then
        sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no "$package_name" "$SERVER_USER@$SERVER_IP:/root/02-production/"
    else
        echo "需要输入密码: $SERVER_PASSWORD"
        scp -o StrictHostKeyChecking=no "$package_name" "$SERVER_USER@$SERVER_IP:/root/02-production/"
    fi
    
    info "文件上传完成"
}

# 在服务器上执行部署
deploy_on_server() {
    local package_name="$1"
    step "在服务器上执行部署"
    
    # 创建服务器端部署脚本
    ssh_exec "cd /root/02-production && cat > deploy_claude_nexus.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

PROJECT_NAME=\"$PROJECT_NAME\"
PACKAGE_NAME=\"$package_name\"
DEPLOY_PATH=\"$DEPLOY_PATH\"
CONTAINER_PORT=\"$CONTAINER_PORT\"
DOMAIN=\"$DOMAIN\"

echo \"🚀 开始部署 Claude Code Nexus...\"

# 备份旧版本
if [ -d \"\$DEPLOY_PATH\" ]; then
    echo \"📦 备份旧版本...\"
    mv \"\$DEPLOY_PATH\" \"\$DEPLOY_PATH-backup-\$(date +%Y%m%d-%H%M%S)\" || true
fi

# 创建新部署目录
echo \"📁 创建部署目录...\"
mkdir -p \"\$DEPLOY_PATH\"

# 解压部署包
echo \"📦 解压部署包...\"
tar -xzf \"/root/02-production/\$PACKAGE_NAME\" -C \"\$DEPLOY_PATH\" --strip-components=0

# 进入部署目录
cd \"\$DEPLOY_PATH\"

# 检查并安装Docker
echo \"🐳 检查Docker环境...\"
if ! command -v docker &> /dev/null; then
    echo \"安装Docker...\"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo \"安装Docker Compose...\"
    curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 停止旧容器
echo \"🛑 停止旧容器...\"
docker-compose down || true
docker system prune -f || true

# 构建并启动新容器
echo \"🏗️ 构建并启动服务...\"
docker-compose up -d --build

# 等待服务启动
echo \"⏳ 等待服务启动...\"
sleep 30

# 检查服务状态
echo \"🔍 检查服务状态...\"
docker-compose ps

# 健康检查
echo \"🩺 健康检查...\"
for i in {1..10}; do
    if curl -f http://localhost:\$CONTAINER_PORT/api/health > /dev/null 2>&1; then
        echo \"✅ 服务启动成功！\"
        break
    else
        echo \"等待服务启动... (\$i/10)\"
        sleep 5
    fi
    
    if [ \$i -eq 10 ]; then
        echo \"❌ 服务启动失败，查看日志:\"
        docker-compose logs \$PROJECT_NAME
        exit 1
    fi
done

echo \"🎉 服务部署成功！\"
echo \"📍 本地访问: http://localhost:\$CONTAINER_PORT\"
echo \"🌐 域名访问: https://\$DOMAIN (需要配置Caddy)\"

DEPLOY_SCRIPT"
    
    # 执行部署脚本
    ssh_exec "cd /root/02-production && chmod +x deploy_claude_nexus.sh && ./deploy_claude_nexus.sh"
    
    info "服务器部署完成"
}

# 配置Caddy反向代理
configure_caddy() {
    step "配置Caddy反向代理"
    
    ssh_exec "mkdir -p /etc/caddy/conf.d"
    
    ssh_exec "cat > /etc/caddy/conf.d/${PROJECT_NAME}.conf << 'CADDY_CONFIG'
$DOMAIN {
    reverse_proxy localhost:$CONTAINER_PORT
    
    # API健康检查
    handle /api/health {
        reverse_proxy localhost:$CONTAINER_PORT
    }
    
    # 静态资源缓存
    handle /assets/* {
        reverse_proxy localhost:$CONTAINER_PORT
        header Cache-Control \"public, max-age=31536000\"
    }
    
    # API路由
    handle /api/* {
        reverse_proxy localhost:$CONTAINER_PORT
    }
    
    # 安全头
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        X-XSS-Protection \"1; mode=block\"
        -Server
    }
    
    # 日志配置
    log {
        output file /var/log/caddy/${PROJECT_NAME}.log {
            roll_size 100MiB
            roll_keep 5
        }
        level INFO
    }
}
CADDY_CONFIG"
    
    # 重新加载Caddy配置
    ssh_exec "systemctl reload caddy || caddy reload"
    
    info "Caddy反向代理配置完成"
}

# 验证部署
verify_deployment() {
    step "验证部署结果"
    
    # 检查容器状态
    info "检查容器状态..."
    ssh_exec "cd $DEPLOY_PATH && docker-compose ps"
    
    # 本地健康检查
    info "本地健康检查..."
    if ssh_exec "curl -f -s http://localhost:$CONTAINER_PORT/api/health"; then
        info "✅ 本地健康检查通过"
    else
        error "❌ 本地健康检查失败"
    fi
    
    # 等待域名生效
    info "等待域名配置生效..."
    sleep 10
    
    # 域名健康检查
    info "域名健康检查..."
    for i in {1..5}; do
        if curl -f -s "https://$DOMAIN/api/health" > /dev/null 2>&1; then
            info "✅ 域名访问检查通过"
            break
        else
            warn "域名访问检查失败，重试中... ($i/5)"
            sleep 5
        fi
        
        if [ $i -eq 5 ]; then
            warn "⚠️ 域名访问可能需要更多时间生效"
        fi
    done
}

# 显示部署结果
show_deployment_result() {
    echo ""
    log "🎉 Claude Code Nexus 部署完成！"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}📋 部署信息总结${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}🌐 应用访问地址:${NC} https://$DOMAIN"
    echo -e "${CYAN}🖥️ 服务器地址:${NC} $SERVER_IP"
    echo -e "${CYAN}📂 部署目录:${NC} $DEPLOY_PATH"
    echo -e "${CYAN}🐳 容器端口:${NC} $CONTAINER_PORT"
    echo -e "${CYAN}📊 本地访问:${NC} http://$SERVER_IP:$CONTAINER_PORT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}📋 下一步操作:${NC}"
    echo "1. 访问 https://$DOMAIN 测试应用"
    echo "2. 使用 GitHub 登录测试 OAuth 功能"
    echo "3. 配置 API 提供商和模型映射"
    echo "4. 测试 Claude Code CLI 集成"
    echo ""
    echo -e "${GREEN}🔧 管理命令:${NC}"
    echo "# 查看服务日志"
    echo "ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose logs -f'"
    echo ""
    echo "# 重启服务"  
    echo "ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose restart'"
    echo ""
    echo "# 停止服务"
    echo "ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker-compose down'"
    echo ""
    echo "# 更新服务"
    echo "./auto-deploy-production.sh"
    echo ""
}

# 清理临时文件
cleanup() {
    step "清理临时文件"
    rm -f ${PROJECT_NAME}-*.tar.gz
    info "临时文件清理完成"
}

# 主执行流程
main() {
    show_deploy_info
    
    # 确认部署
    echo -e "${YELLOW}确认开始部署吗? (y/N):${NC} \c"
    read -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "部署已取消"
        exit 0
    fi
    
    echo ""
    log "开始自动部署流程..."
    
    # 执行部署步骤
    check_local_env
    
    local package_name
    package_name=$(create_deploy_package)
    
    upload_to_server "$package_name"
    deploy_on_server "$package_name"
    configure_caddy
    verify_deployment
    show_deployment_result
    cleanup
    
    log "🚀 自动部署流程完成！"
}

# 错误处理
trap 'error "部署过程中发生错误，请检查日志"' ERR

# 执行主程序
main "$@"