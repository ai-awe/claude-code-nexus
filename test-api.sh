#!/bin/bash

echo "=== Claude Code Nexus API 测试脚本 ==="
echo ""

# 配置
API_KEY="${1:-请输入您的API_KEY}"
BASE_URL="https://claudeapi-1.satoshitech.xyz"

if [ "$API_KEY" == "请输入您的API_KEY" ]; then
    echo "使用方法: ./test-api.sh YOUR_API_KEY"
    echo ""
    echo "请先访问 $BASE_URL 登录并获取您的 API Key"
    exit 1
fi

echo "1. 测试基本连通性..."
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" "$BASE_URL/"
echo ""

echo "2. 测试API认证..."
RESPONSE=$(curl -s -X POST "$BASE_URL/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Say hello in 5 words"}],
    "max_tokens": 20
  }')

echo "响应: $RESPONSE"
echo ""

# 检查是否包含错误
if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ API调用失败"
    echo "可能的原因："
    echo "1. API Key无效"
    echo "2. 未配置后端API服务"
    echo "3. 后端服务连接失败"
else
    echo "✅ API调用成功"
fi

echo ""
echo "3. 测试流式响应..."
echo "发送流式请求..."
curl -N -X POST "$BASE_URL/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Count from 1 to 5"}],
    "max_tokens": 50,
    "stream": true
  }' 2>/dev/null | head -20

echo ""
echo ""
echo "=== 测试完成 ==="
echo ""
echo "如果您在Claude Code中收不到回复，请检查："
echo "1. 确保已设置正确的环境变量："
echo "   export ANTHROPIC_BASE_URL=\"$BASE_URL\""
echo "   export ANTHROPIC_AUTH_TOKEN=\"$API_KEY\""
echo ""
echo "2. 在网站上检查您的API配置："
echo "   - 是否选择了正确的API供应商"
echo "   - 是否输入了有效的第三方API Key"
echo ""
echo "3. 尝试使用curl直接测试："
echo "   claude --debug \"Hello\""