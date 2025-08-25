# Claude Code Nexus - Claude API 代理服务

## 🚀 项目简介

Claude Code Nexus 是一个强大的 Claude API 代理服务，允许您使用 Claude Code CLI 连接到任何第三方 AI API（如 Gemini、OpenAI、通义千问等）。

## 🏗️ 架构流程

```
Claude Code CLI
    ↓
您的代理服务 (claudeapi-1.satoshitech.xyz)
    ↓
任意第三方 AI API (Gemini/OpenAI/Kimi/etc)
    ↓
格式转换后返回
```

## 📋 快速开始

### 1. 注册账户

访问 https://claudeapi-1.satoshitech.xyz 并使用 GitHub 登录。

### 2. 获取 API Key

登录后，在用户面板中找到并复制您的 API Key。

### 3. 配置 Claude Code CLI

```bash
# 临时使用（当前终端会话）
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
export ANTHROPIC_AUTH_TOKEN="您的API Key"

# 永久配置（推荐）
# 将以下内容添加到 ~/.bashrc 或 ~/.zshrc 文件末尾
echo 'export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"' >> ~/.zshrc
echo 'export ANTHROPIC_AUTH_TOKEN="您的API Key"' >> ~/.zshrc
source ~/.zshrc

# 测试连接
claude "你好，请介绍一下你自己"
```

## 🔧 支持的第三方 API

- **谷歌 Gemini** - 默认使用优化中转服务
- **NekroAI 中转** - 高性能 API 中转
- **通义千问** - 阿里云 AI 服务
- **Kimi** - 月之暗面 AI
- **豆包** - 字节跳动 AI
- **智谱清言** - 智谱 AI
- **百度千帆** - 百度大模型
- **腾讯混元** - 腾讯 AI
- 更多服务持续添加中...

## 📝 模型映射

| Claude 模型 | 默认映射到 |
|------------|-----------|
| claude-3-haiku-* | gemini-2.5-flash |
| claude-3-sonnet-* | gemini-2.5-pro |
| claude-3-opus-* | gemini-2.5-pro |

## 🎯 核心特性

- ✅ **完全兼容** - 100% 兼容 Claude API 格式
- ✅ **多供应商** - 支持连接任意 AI API 服务
- ✅ **智能转换** - 自动处理请求/响应格式转换
- ✅ **流式响应** - 支持实时流式输出
- ✅ **用户管理** - 基于 GitHub OAuth 的安全认证
- ✅ **配额控制** - 每个用户独立的 API 配额管理

## 🛠️ 高级配置

### 在用户面板中配置

1. 登录后访问用户设置页面
2. 选择您的 API 供应商
3. 输入对应的 API Key
4. 保存设置

### 自定义模型映射

您可以在设置中自定义模型映射关系，将 Claude 的模型名称映射到您选择的第三方 API 模型。

## 🔍 故障排查

### 常见问题

**Q: 提示 "Invalid API key"**
A: 请确认您已经在 https://claudeapi-1.satoshitech.xyz 注册并获取了有效的 API Key。

**Q: 连接超时**
A: 检查网络连接，确保可以访问 claudeapi-1.satoshitech.xyz。

**Q: 模型不支持**
A: 只支持 haiku、sonnet 和 opus 三个模型系列。

### 调试模式

```bash
# 开启详细日志
claude --debug "测试消息"
```

## 📞 联系支持

如有问题，请通过以下方式联系：
- GitHub Issues: [项目地址]
- 邮件: support@satoshitech.xyz

## 📄 许可证

本项目采用 MIT 许可证。