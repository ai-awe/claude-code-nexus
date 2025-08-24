#!/bin/bash

# 手动部署脚本 - 分步执行
set -e

SERVER="103.53.81.33"
USER="root"
APP_NAME="claude-code-nexus"

echo "🚀 手动部署 Claude Code Nexus 到日本预发服务器"
echo "服务器: $SERVER"
echo "域名: https://claudeapi.satoshitech.xyz"
echo ""

echo "步骤1: 创建项目压缩包..."
tar -czf claude-code-nexus-deploy.tar.gz \
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
  .

echo "✅ 压缩包创建完成"

echo ""
echo "步骤2: 上传文件到服务器 (需要输入密码: Zhxc6545398@)"
scp claude-code-nexus-deploy.tar.gz $USER@$SERVER:/root/

echo ""
echo "步骤3: 连接到服务器执行部署 (需要输入密码)"
echo "请在服务器上执行以下命令:"
echo ""
echo "cd /root"
echo "tar -xzf claude-code-nexus-deploy.tar.gz"
echo "mv claude-code-nexus claude-code-nexus-backup-\$(date +%Y%m%d) 2>/dev/null || true"
echo "mkdir -p claude-code-nexus"
echo "tar -xzf claude-code-nexus-deploy.tar.gz -C claude-code-nexus --strip-components=1"
echo "cd claude-code-nexus"
echo ""
echo "# 安装 Docker (如果没有)"
echo "curl -fsSL https://get.docker.com | sh"
echo "systemctl enable docker && systemctl start docker"
echo ""
echo "# 部署服务"
echo "docker-compose down || true"
echo "docker-compose up -d --build"
echo ""
echo "# 等待启动并检查"
echo "sleep 30"
echo "docker-compose ps"
echo "curl http://localhost:3009/api/health"
echo ""

ssh $USER@$SERVER