#!/bin/bash

echo "=== 测试 Claude Code 流式响应问题 ==="
echo ""

API_KEY="${1:-请输入您的API_KEY}"
if [ "$API_KEY" == "请输入您的API_KEY" ]; then
    echo "使用方法: ./test-stream.sh YOUR_API_KEY"
    exit 1
fi

echo "1. 测试流式请求（Claude Code 默认模式）..."
echo "==========================================="
echo ""

# 测试流式请求
echo "发送流式请求..."
curl -N -H "Accept: text/event-stream" \
  -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Hi"}],
    "max_tokens": 50,
    "stream": true
  }' -v 2>&1 | grep -E "< HTTP|< |data:|event:|error"

echo ""
echo ""
echo "2. 测试非流式请求（调试用）..."
echo "================================"
echo ""

# 测试非流式请求
RESPONSE=$(curl -s -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Hi"}],
    "max_tokens": 50,
    "stream": false
  }')

echo "非流式响应："
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

echo ""
echo "3. 分析..."
echo "==========="
echo ""

if echo "$RESPONSE" | grep -q "User has not configured"; then
    echo "❌ 问题确认：您还没有在控制台配置 Gemini API"
    echo ""
    echo "📌 解决步骤："
    echo "1. 打开 https://claudeapi-1.satoshitech.xyz"
    echo "2. GitHub 登录"
    echo "3. 在控制台页面："
    echo "   - API 服务提供商：选择【谷歌Gemini】"
    echo "   - OpenAI 源站 API Key：输入【sk-gemini-balance-2025】"
    echo "   - 点击【保存配置】"
    echo ""
    echo "4. 保存后再次运行 Claude Code"
elif echo "$RESPONSE" | grep -q "Invalid API key"; then
    echo "❌ API Key 无效"
    echo "请确认您使用的是从控制台复制的 API Key"
elif echo "$RESPONSE" | grep -q "content"; then
    echo "✅ 非流式模式工作正常"
    echo "⚠️  但 Claude Code 使用的是流式模式，可能存在流式处理问题"
fi

echo ""
echo "💡 临时解决方案："
echo "=================="
echo "如果流式模式有问题，可以尝试强制使用非流式模式："
echo ""
echo "# 创建一个包装脚本"
echo 'cat > claude-nonstream.sh << '\''EOF'\'''
echo '#!/bin/bash'
echo 'export ANTHROPIC_STREAM=false'
echo 'claude "$@"'
echo 'EOF'
echo ""
echo "chmod +x claude-nonstream.sh"
echo "./claude-nonstream.sh \"你好\""