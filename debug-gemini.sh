#!/bin/bash

echo "=== Gemini API 集成调试 ==="
echo ""

API_KEY="${1:-ak-7e9b893ea4b324d6374e3ac520e493b45fd8715c90d3200e2749c108ea7d4498}"

echo "1. 直接测试 Gemini API (验证基础连接)"
echo "========================================="
GEMINI_RESPONSE=$(curl -s -X POST "https://gemini.satoshitech.xyz/gemini/v1beta/models/gemini-2.5-flash:generateContent" \
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

echo "Gemini 直接响应:"
echo "$GEMINI_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null || echo "解析失败"
echo ""

echo "2. 通过 Claude Code Nexus 测试 (haiku -> gemini-2.5-flash)"
echo "==========================================================="
NEXUS_RESPONSE=$(curl -s -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 50,
    "stream": false
  }')

echo "Claude Nexus 响应:"
echo "$NEXUS_RESPONSE" | jq . 2>/dev/null || echo "$NEXUS_RESPONSE"
echo ""

# 提取错误信息
if echo "$NEXUS_RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$NEXUS_RESPONSE" | jq -r '.error.message' 2>/dev/null)
    ERROR_MSG_ZH=$(echo "$NEXUS_RESPONSE" | jq -r '.error.message_zh' 2>/dev/null)
    
    echo "错误信息: $ERROR_MSG"
    echo "中文说明: $ERROR_MSG_ZH"
    echo ""
fi

echo "3. 测试请求转换 (模拟 Claude -> Gemini 格式转换)"
echo "=================================================="
echo "Claude 格式请求:"
cat << 'EOF' | jq .
{
  "model": "claude-3-haiku-20240307",
  "messages": [{"role": "user", "content": "Hello"}],
  "max_tokens": 50
}
EOF

echo ""
echo "应该转换为的 Gemini 格式:"
cat << 'EOF' | jq .
{
  "contents": [{
    "role": "user",
    "parts": [{"text": "Hello"}]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "topP": 0.9,
    "maxOutputTokens": 50
  }
}
EOF

echo ""
echo "4. 检查可能的问题"
echo "=================="

# 检查是否是模型名称问题
echo "- 检查模型映射："
echo "  haiku -> gemini-2.5-flash"
echo "  sonnet -> gemini-2.5-pro"
echo "  opus -> gemini-2.5-pro"
echo ""

# 测试具体的错误来源
echo "5. 测试错误来源"
echo "==============="

# 构造一个会失败的请求
BAD_RESPONSE=$(curl -s -X POST "https://gemini.satoshitech.xyz/gemini/v1beta/models/gemini-2.5-pro:generateContent" \
  -H "x-goog-api-key: sk-gemini-balance-2025" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "Hello"}]
    }],
    "generationConfig": {
      "maxOutputTokens": 50
    }
  }')

echo "直接调用 gemini-2.5-pro 的结果:"
echo "$BAD_RESPONSE" | jq . 2>/dev/null || echo "$BAD_RESPONSE"
echo ""

# 诊断总结
echo "=== 诊断总结 ==="
echo ""

if echo "$BAD_RESPONSE" | grep -q "No available channels"; then
    echo "❌ 问题确认：您的 Gemini 服务不支持 gemini-2.5-pro 模型"
    echo ""
    echo "📌 解决方案："
    echo "1. 在控制台切换到【自定义映射】模式"
    echo "2. 将所有模型都映射到 gemini-2.5-flash："
    echo "   - haiku -> gemini-2.5-flash"
    echo "   - sonnet -> gemini-2.5-flash"
    echo "   - opus -> gemini-2.5-flash"
    echo ""
    echo "或者使用云雾API："
    echo "1. API 服务提供商：https://yunwu.ai/v1"
    echo "2. API Key：sk-BeajA02CdOJOmbUu9vamtmdE0p4tojqXgukNG6LjvtdQBPvJ"
    echo "3. 模型映射：全部映射到 gpt-4o"
fi