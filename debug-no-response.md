# Claude Code 无响应问题排查

## 问题描述
使用Claude Code CLI时没有收到响应

## 排查步骤

### 1. 检查您是否已经获取API Key

请访问 https://claudeapi-1.satoshitech.xyz 
1. 使用GitHub登录
2. 在控制台页面复制您的API Key（格式：`ak-xxx...`）

### 2. 检查您是否配置了第三方API

登录后，在控制台页面检查：
- **API服务提供商**：是否选择了供应商（推荐"谷歌Gemini"）
- **API Key**：是否输入了第三方API Key（如您的Gemini API Key）

⚠️ **重要**：如果没有配置第三方API，系统无法处理请求！

### 3. 验证环境变量设置

```bash
# 检查当前环境变量
echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
echo "ANTHROPIC_AUTH_TOKEN: $ANTHROPIC_AUTH_TOKEN"

# 应该显示：
# ANTHROPIC_BASE_URL: https://claudeapi-1.satoshitech.xyz
# ANTHROPIC_AUTH_TOKEN: ak-xxxxx（您的API Key）
```

### 4. 测试API连接

```bash
# 使用您的实际API Key替换 YOUR_API_KEY
API_KEY="YOUR_API_KEY"

# 测试非流式响应
curl -X POST "https://claudeapi-1.satoshitech.xyz/v1/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 50,
    "stream": false
  }'
```

### 5. 可能的错误和解决方案

#### 错误：Invalid API key
- **原因**：API Key无效
- **解决**：确认已登录并复制正确的API Key

#### 错误：User has not configured an API key
- **原因**：未配置第三方API服务
- **解决**：
  1. 登录 https://claudeapi-1.satoshitech.xyz
  2. 在控制台选择"谷歌Gemini"
  3. 输入您的Gemini API Key（或其他第三方API Key）
  4. 点击"保存配置"

#### 错误：No model mapping found
- **原因**：使用了不支持的模型名称
- **解决**：使用包含haiku、sonnet或opus的模型名

#### 无任何响应
- **原因1**：网络连接问题
- **解决**：检查是否能访问 https://claudeapi-1.satoshitech.xyz

- **原因2**：Claude Code版本问题
- **解决**：
  ```bash
  # 更新Claude Code
  npm update -g @anthropic-ai/claude-code
  claude --version
  ```

- **原因3**：环境变量未生效
- **解决**：
  ```bash
  # 重新设置并立即使用
  export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
  export ANTHROPIC_AUTH_TOKEN="您的API_KEY"
  claude "测试消息"
  ```

### 6. 使用调试模式

```bash
# 开启调试模式查看详细信息
claude --debug "Hello, are you there?"
```

### 7. 完整配置示例

假设您的API Key是 `ak-7e9b893ea4b324d6374e3ac520e493b45fd8715c90d3200e2749c108ea7d4498`

```bash
# 临时使用
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
export ANTHROPIC_AUTH_TOKEN="ak-7e9b893ea4b324d6374e3ac520e493b45fd8715c90d3200e2749c108ea7d4498"
claude "你好"

# 永久配置（添加到 ~/.zshrc 或 ~/.bashrc）
echo 'export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"' >> ~/.zshrc
echo 'export ANTHROPIC_AUTH_TOKEN="ak-7e9b893ea4b324d6374e3ac520e493b45fd8715c90d3200e2749c108ea7d4498"' >> ~/.zshrc
source ~/.zshrc
```

## 快速检查清单

- [ ] 已在 https://claudeapi-1.satoshitech.xyz 登录
- [ ] 已获取API Key（ak-开头）
- [ ] 已配置第三方API（如Gemini）
- [ ] 已设置环境变量 ANTHROPIC_BASE_URL
- [ ] 已设置环境变量 ANTHROPIC_AUTH_TOKEN
- [ ] Claude Code版本是最新的

如果以上都确认无误仍无响应，请提供：
1. `claude --debug "test"` 的完整输出
2. 您的API Key前8位字符
3. 错误信息截图