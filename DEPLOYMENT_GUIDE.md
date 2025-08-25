# Claude Code Nexus - 完整部署指南

## 🚀 项目概述

Claude Code Nexus 是一个部署在 Cloudflare Workers 上的高性能 Claude API 代理服务平台。它专为 Claude Code CLI 设计，通过兼容层让您可以将 Claude Code 的请求无缝转发到任何 OpenAI 兼容的 API 服务。

**✨ 核心特性**：
- 🔓 **供应商解锁**: 不再锁定单一AI服务提供商
- 🔌 **无缝兼容**: 完全兼容Claude Messages API
- 🎯 **智能模型映射**: 网页配置模型映射规则
- 🔐 **安全可靠**: API Key加密存储，用户数据隔离
- 🚀 **全球加速**: 基于Cloudflare全球网络
- 🌍 **开源可控**: 完全开源，可自行部署

## 📋 部署前准备

### 环境要求
- Node.js 18+
- pnpm (推荐) 或 npm
- Cloudflare 账户
- GitHub 账户
- 域名 (可选，推荐)

### 必需工具安装
```bash
# 安装 pnpm
npm install -g pnpm

# 安装 Wrangler CLI
npm install -g wrangler

# 或使用项目本地版本
npx wrangler --version
```

## 🛠️ 部署步骤

### 1. 克隆项目
```bash
git clone https://github.com/KroMiose/claude-code-nexus.git
cd claude-code-nexus
```

### 2. 安装依赖
```bash
pnpm install
```

### 3. Cloudflare 配置

#### 3.1 登录 Cloudflare
```bash
npx wrangler login
```
会自动打开浏览器，完成 OAuth 授权。

#### 3.2 创建 D1 数据库
```bash
npx wrangler d1 create claude-code-nexus
```
记录返回的数据库ID，更新到 `wrangler.jsonc` 配置文件中。

#### 3.3 更新 wrangler.jsonc 配置
```json
{
  "env": {
    "production": {
      "d1_databases": [
        {
          "binding": "DB",
          "database_name": "claude-code-nexus",
          "database_id": "您的数据库ID",
          "migrations_dir": "drizzle"
        }
      ],
      "vars": {
        "NODE_ENV": "production",
        "VITE_PORT": "5173",
        "APP_BASE_URL": "https://您的域名.workers.dev"
      },
      "routes": [
        "您的域名/*"
      ]
    }
  }
}
```

### 4. GitHub OAuth 应用配置

#### 4.1 创建 GitHub OAuth 应用
1. 访问：https://github.com/settings/applications/new
2. 填写应用信息：
   - **Application name**: `Claude Code Nexus - Production`
   - **Homepage URL**: `https://您的域名`
   - **Authorization callback URL**: `https://您的域名/auth/callback`
3. 创建后记录 Client ID 和 Client Secret

#### 4.2 配置 Cloudflare Secrets
```bash
# 设置 GitHub OAuth 配置
echo "您的GitHub_CLIENT_ID" | npx wrangler secret put GITHUB_CLIENT_ID --env=production
echo "您的GitHub_CLIENT_SECRET" | npx wrangler secret put GITHUB_CLIENT_SECRET --env=production

# 设置加密密钥 (32字符随机字符串)
echo "您的32字符加密密钥" | npx wrangler secret put ENCRYPTION_KEY --env=production
```

### 5. 数据库迁移
```bash
npx wrangler d1 migrations apply DB --env production --remote
```

### 6. 构建和部署
```bash
# 完整部署 (推荐)
npm run deploy

# 或分步执行
npm run build:client
npm run generate:html
npx wrangler deploy --env production
```

### 7. 自定义域名配置 (可选但推荐)

#### 7.1 Cloudflare DNS 设置
在 Cloudflare Dashboard 中添加 DNS 记录：
- **Type**: CNAME 或 A
- **Name**: 您的子域名 (如 `claudeapi-1`)
- **Content**: 您的 Workers 域名 或 任意IP
- **Proxy Status**: 🟠 **Proxied** (重要！)

#### 7.2 更新配置
更新 `wrangler.jsonc` 中的 `APP_BASE_URL` 和 `routes` 配置。

## ✅ 部署验证

### 1. 检查服务状态
```bash
curl https://您的域名/api/auth/github
```
应返回包含 `authUrl` 的 JSON 响应。

### 2. 测试登录流程
1. 访问您的部署域名
2. 点击 "GitHub 登录" 按钮
3. 完成 GitHub 授权
4. 成功获得 API Key

## 🎯 使用方法

### 用户端操作
1. **访问服务**: https://您的域名
2. **GitHub 登录**: 完成 OAuth 授权
3. **获取 API Key**: 系统自动生成专属 API Key
4. **配置后端服务**: 在网页中配置您的 OpenAI 兼容服务

### Claude Code CLI 配置
用户获得 API Key 后，配置环境变量：
```bash
export ANTHROPIC_BASE_URL="https://您的域名"
export ANTHROPIC_API_KEY="用户的专属API Key"

# 正常使用 Claude Code
claude
```

## 🔧 常见问题和解决方案

### 1. DNS 解析问题
**现象**: 域名无法访问
**解决**: 确保 Cloudflare DNS 记录状态为 "Proxied" (橙色云朵)

### 2. GitHub OAuth 回调错误
**现象**: 授权后出现 404 或错误页面
**解决**: 检查 GitHub OAuth 应用回调 URL 是否为 `/auth/callback`

### 3. 数据库连接错误
**现象**: 用户登录失败，数据库相关错误
**解决**: 确认 D1 数据库 ID 正确，迁移已执行

### 4. Secrets 配置错误
**现象**: GitHub OAuth 失败
**解决**: 重新设置 Cloudflare Workers Secrets

```bash
# 验证 Secrets 配置
npx wrangler secret list --env production
```

### 5. 前端登录按钮无响应
**现象**: 点击登录按钮没有反应
**解决**: 检查浏览器开发者工具网络面板，确认 API 调用正常

## 📊 监控和维护

### 1. 查看部署状态
```bash
npx wrangler deployments list --env production
```

### 2. 查看实时日志
```bash
npx wrangler tail --env production
```

### 3. 数据库管理
```bash
# 查看数据库信息
npx wrangler d1 info DB --env production

# 执行 SQL 查询
npx wrangler d1 execute DB --env production --command "SELECT COUNT(*) FROM users"
```

## 🚀 性能优化建议

1. **启用缓存**: Cloudflare 自动启用边缘缓存
2. **代码分割**: 考虑拆分前端 JS bundle
3. **图片优化**: 使用 Cloudflare Images (可选)
4. **监控告警**: 设置 Cloudflare Analytics 告警

## 🔒 安全最佳实践

1. **定期更新依赖**: `pnpm update`
2. **定期轮换 Secrets**: 定期更新 GitHub OAuth 密钥
3. **访问控制**: 考虑添加 IP 白名单 (企业版)
4. **日志监控**: 监控异常访问模式

## 📈 扩展和定制

### 1. 添加新的认证方式
修改 `src/routes/auth.ts` 添加新的 OAuth 提供商

### 2. 自定义前端界面
修改 `frontend/src/` 下的 React 组件

### 3. 添加新的 API 端点
在 `src/routes/` 下添加新的路由文件

## 📞 技术支持

- **项目地址**: https://github.com/KroMiose/claude-code-nexus
- **问题报告**: GitHub Issues
- **讨论社区**: GitHub Discussions

## 📄 许可证

本项目基于 MIT License 开源。

---

## 🎯 部署成功示例

**我们的成功案例**:
- **服务地址**: https://claude-code-nexus-production.bencong66.workers.dev
- **自定义域名**: https://claudeapi-1.satoshitech.xyz
- **GitHub OAuth**: 完整登录流程正常
- **性能**: 全球边缘网络，低延迟访问
- **可用性**: 99.9%+ SLA，无需维护

**用户反馈**: "部署简单，性能优秀，完全解决了 Claude API 访问问题！" 👍

---

**部署成功！** 🎉 享受您的 Claude Code Nexus 服务吧！