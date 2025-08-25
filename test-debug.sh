#!/bin/bash

# Claude Code Nexus 调试脚本

echo "=== Claude Code Nexus 调试测试 ==="
echo ""

# 测试参数
API_KEY="${1:-请输入您的API_KEY}"
if [ "$API_KEY" == "请输入您的API_KEY" ]; then
    echo "使用方法: ./test-debug.sh YOUR_API_KEY"
    echo "请从 https://claudeapi-1.satoshitech.xyz 控制台获取您的 API Key"
    exit 1
fi

echo "1. 测试非流式请求..."
echo "================================"
echo "请求 URL: https://claudeapi-1.satoshitech.xyz/v1/messages"
echo "API Key: ${API_KEY:0:8}...${API_KEY: -8}"
echo ""

# 发送请求并保存响应
RESPONSE=$(curl -s -w "\n---\nHTTP_CODE:%{http_code}\n" \
  -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Say hello in 5 words"}],
    "max_tokens": 50,
    "stream": false
  }')

# 提取HTTP状态码
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed -n '1,/---/p' | head -n -1)

echo "HTTP 状态码: $HTTP_CODE"
echo "响应内容:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
echo ""

# 分析响应
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ API 调用成功!"
    echo ""
    
    # 检查是否有实际内容
    if echo "$BODY" | grep -q '"content"'; then
        echo "✅ 收到 AI 响应内容"
    else
        echo "⚠️  响应中没有内容字段"
    fi
elif [ "$HTTP_CODE" == "401" ]; then
    echo "❌ 认证失败 - 请检查 API Key 是否正确"
elif [ "$HTTP_CODE" == "400" ]; then
    echo "❌ 请求错误"
    ERROR_MSG=$(echo "$BODY" | jq -r '.message // .error.message // "未知错误"' 2>/dev/null)
    echo "错误信息: $ERROR_MSG"
    
    if echo "$ERROR_MSG" | grep -q "not configured"; then
        echo ""
        echo "📌 解决方案："
        echo "1. 访问 https://claudeapi-1.satoshitech.xyz"
        echo "2. 登录后在控制台选择 '谷歌Gemini'"
        echo "3. 输入 API Key: sk-gemini-balance-2025"
        echo "4. 点击 '保存配置'"
    fi
elif [ "$HTTP_CODE" == "500" ]; then
    echo "❌ 服务器内部错误"
    echo "可能原因："
    echo "- 后端 Gemini API 连接失败"
    echo "- 格式转换错误"
    echo "- 请检查 Cloudflare Workers 日志"
else
    echo "❌ 未知错误 (HTTP $HTTP_CODE)"
fi

echo ""
echo "2. 测试流式请求..."
echo "================================"
echo "发送流式请求..."

# 流式请求测试
echo "请求内容:"
echo '{
  "model": "claude-3-haiku-20240307",
  "messages": [{"role": "user", "content": "Count from 1 to 3"}],
  "max_tokens": 50,
  "stream": true
}'
echo ""
echo "流式响应（前10行）:"
curl -N -s \
  -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307", 
    "messages": [{"role": "user", "content": "Count from 1 to 3"}],
    "max_tokens": 50,
    "stream": true
  }' 2>/dev/null | head -20

echo ""
echo ""
echo "=== 诊断总结 ==="
echo ""

# 直接测试 Gemini API
echo "3. 直接测试您的 Gemini API..."
echo "================================"
GEMINI_RESPONSE=$(curl -s -w "\n---\nHTTP_CODE:%{http_code}\n" \
  -X POST "https://gemini.satoshitech.xyz/gemini/v1beta/models/gemini-2.5-flash:generateContent" \
  -H "x-goog-api-key: sk-gemini-balance-2025" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "Say hello"}]
    }],
    "generationConfig": {
      "temperature": 0.7,
      "maxOutputTokens": 50
    }
  }')

GEMINI_HTTP_CODE=$(echo "$GEMINI_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
echo "Gemini API 状态: $GEMINI_HTTP_CODE"

if [ "$GEMINI_HTTP_CODE" == "200" ]; then
    echo "✅ Gemini API 正常工作"
else
    echo "❌ Gemini API 连接失败"
fi

echo ""
echo "诊断建议："
echo "----------"
if [ "$HTTP_CODE" != "200" ]; then
    echo "1. 确保已在控制台配置了 Gemini API"
    echo "2. API Key 设置为: sk-gemini-balance-2025"
    echo "3. 选择的供应商为: 谷歌Gemini"
fi
echo ""
echo "如果问题持续，请提供以上输出信息以便进一步诊断。"