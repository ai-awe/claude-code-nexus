# Claude Code Nexus 故障诊断指南

## 🔍 问题：Claude Code CLI 收不到回复

### 可能原因和解决方案：

## 1. 检查 API Key 是否有效

```bash
# 测试 API Key
curl -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Hi"}],
    "max_tokens": 10
  }'
```

如果返回 "Invalid API key"，请：
1. 访问 https://claudeapi-1.satoshitech.xyz
2. 使用 GitHub 登录
3. 复制您的 API Key

## 2. 检查后端 API 配置

登录后在用户设置中检查：
- **API 供应商**：是否选择了正确的供应商（如"谷歌Gemini"）
- **API Key**：是否输入了有效的第三方 API Key（如 Gemini API Key）

## 3. 检查环境变量配置

```bash
# 检查当前环境变量
echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
echo "ANTHROPIC_AUTH_TOKEN: $ANTHROPIC_AUTH_TOKEN"

# 正确的配置应该是：
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
export ANTHROPIC_AUTH_TOKEN="您的API_KEY"
```

## 4. 测试直接 API 调用

```bash
# 使用您的 API Key 测试
API_KEY="您的API_KEY"

# 非流式测试
curl -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-sonnet-20241022",
    "messages": [{"role": "user", "content": "请用一句话介绍自己"}],
    "max_tokens": 100,
    "stream": false
  }'

# 流式测试
curl -N -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-sonnet-20241022",
    "messages": [{"role": "user", "content": "数到5"}],
    "max_tokens": 100,
    "stream": true
  }'
```

## 5. 常见错误和解决方案

### 错误：Invalid API key
- 确认已登录并获取了有效的 API Key
- 检查环境变量是否正确设置

### 错误：User has not configured an API key
- 登录网站，在用户设置中配置第三方 API Key
- 选择 API 供应商（推荐选择"谷歌Gemini"）
- 输入对应的 API Key

### 错误：No model mapping found
- 确保使用支持的模型名称
- 支持的模型：包含 haiku、sonnet 或 opus 的模型名

### Claude Code 无响应
1. 检查网络连接
2. 尝试使用 `claude --debug` 查看详细日志
3. 确认环境变量已正确设置

## 6. 调试命令

```bash
# 开启 Claude Code 调试模式
claude --debug "测试消息"

# 查看 Claude Code 版本
claude --version

# 检查配置
claude config
```

## 7. 完整测试流程

1. **获取 API Key**
   ```bash
   # 访问网站登录
   open https://claudeapi-1.satoshitech.xyz
   ```

2. **配置环境变量**
   ```bash
   export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
   export ANTHROPIC_AUTH_TOKEN="您的API_KEY"
   ```

3. **测试连接**
   ```bash
   claude "Hello, are you working?"
   ```

如果仍有问题，请提供：
- 错误信息截图
- `claude --debug` 的输出
- 您的 API Key（前8位）以便查看日志