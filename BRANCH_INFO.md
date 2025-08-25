# Cloudflare Deployment Branch

## 🚀 分支说明

这是专门用于 Cloudflare Workers 部署的分支。

### 部署信息
- **部署平台**: Cloudflare Workers
- **生产环境**: https://claudeapi-1.satoshitech.xyz
- **部署日期**: 2025-08-25

### 主要特性
- ✅ 完整的 Cloudflare Workers 配置
- ✅ 前端 URL 已更新为自定义域名
- ✅ 支持 Gemini 原生 API 格式
- ✅ GitHub OAuth 认证
- ✅ 多 API 供应商支持

### 配置要点
- **环境变量**: 在 Cloudflare Dashboard 中配置
- **D1 数据库**: claude-code-nexus
- **域名路由**: claudeapi-1.satoshitech.xyz

### 使用说明
```bash
# 部署到 Cloudflare
npm run deploy

# 本地开发
npm run dev
```

### Claude Code CLI 配置
```bash
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
export ANTHROPIC_AUTH_TOKEN="您的API_KEY"
```

---
⚠️ **注意**: 这个分支包含了所有 Cloudflare 特定的配置和优化。