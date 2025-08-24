#!/bin/bash

# 简化版自动部署脚本
set -e

SERVER="103.53.81.33"
USER="root"
PASSWORD="Zhxc6545398@"
DEPLOY_DIR="/root/02-production/claude-code-nexus"

echo "🚀 开始部署 Claude Code Nexus"
echo "服务器: $SERVER"
echo "目录: $DEPLOY_DIR"
echo "域名: https://claudeapi.satoshitech.xyz"
echo ""

# 创建部署包
echo "📦 创建部署包..."
tar -czf claude-nexus-deploy.tar.gz \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=.git \
  --exclude=logs \
  --exclude='*.log' \
  --exclude=.DS_Store \
  --exclude=.env \
  --exclude=changes/ \
  --exclude='*.tar.gz' \
  .

echo "✅ 部署包创建完成"

# 上传文件
echo "⬆️ 上传文件到服务器..."
if command -v sshpass &> /dev/null; then
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no claude-nexus-deploy.tar.gz $USER@$SERVER:/root/02-production/
else
    echo "请输入密码: $PASSWORD"
    scp -o StrictHostKeyChecking=no claude-nexus-deploy.tar.gz $USER@$SERVER:/root/02-production/
fi

# 执行远程部署
echo "🔧 执行远程部署..."
if command -v sshpass &> /dev/null; then
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'REMOTE_SCRIPT'
set -e
cd /root/02-production

echo "📁 准备部署目录..."
# 备份旧版本
if [ -d "claude-code-nexus" ]; then
    mv claude-code-nexus claude-code-nexus-backup-$(date +%Y%m%d-%H%M%S) || true
fi

# 创建新目录并解压
mkdir -p claude-code-nexus
tar -xzf claude-nexus-deploy.tar.gz -C claude-code-nexus --strip-components=0

cd claude-code-nexus

echo "🐳 检查Docker环境..."
# 安装Docker (如果需要)
if ! command -v docker &> /dev/null; then
    echo "安装Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "安装Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo "🛑 停止旧服务..."
docker-compose down || true

echo "🏗️ 构建并启动服务..."
docker-compose up -d --build

echo "⏳ 等待服务启动..."
sleep 30

echo "🔍 检查服务状态..."
docker-compose ps

echo "🩺 健康检查..."
if curl -f http://localhost:3009/api/health; then
    echo "✅ 服务启动成功!"
else
    echo "❌ 服务启动失败，查看日志:"
    docker-compose logs claude-code-nexus
fi

REMOTE_SCRIPT
else
    echo "请手动SSH连接并执行部署命令"
fi

# 配置Caddy
echo "🌐 配置域名访问..."
if command -v sshpass &> /dev/null; then
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'CADDY_SCRIPT'
mkdir -p /etc/caddy/conf.d

cat > /etc/caddy/conf.d/claude-code-nexus.conf << 'EOF'
claudeapi.satoshitech.xyz {
    reverse_proxy localhost:3009
    
    handle /api/health {
        reverse_proxy localhost:3009
    }
    
    handle /assets/* {
        reverse_proxy localhost:3009
        header Cache-Control "public, max-age=31536000"
    }
    
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        -Server
    }
    
    log {
        output file /var/log/caddy/claude-nexus.log {
            roll_size 100MiB
            roll_keep 5
        }
    }
}
EOF

caddy reload || systemctl reload caddy
echo "✅ Caddy配置完成"
CADDY_SCRIPT
fi

# 验证部署
echo "🧪 验证部署..."
sleep 10

if curl -f -s "https://claudeapi.satoshitech.xyz/api/health"; then
    echo "✅ 域名访问正常"
else
    echo "⚠️ 域名访问可能需要等待生效"
fi

# 清理
rm -f claude-nexus-deploy.tar.gz

echo ""
echo "🎉 部署完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 访问地址: https://claudeapi.satoshitech.xyz"
echo "🖥️ 服务器: $SERVER"
echo "📂 部署目录: $DEPLOY_DIR"
echo "🐳 容器端口: 3009"
echo ""
echo "📋 下一步："
echo "1. 访问应用并测试GitHub登录"
echo "2. 配置API提供商"
echo "3. 测试Claude Code CLI集成"
echo ""