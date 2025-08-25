# Claude Code Nexus - Cloudflare Workers 部署记录

## 🎯 部署概览

**服务地址**: https://claude-code-nexus-production.bencong66.workers.dev  
**自定义域名**: https://claudeapi-1.satoshitech.xyz (通过Workers路由)  
**部署时间**: 2025-08-24

## 🔧 GitHub OAuth 配置

### 新建 GitHub OAuth 应用
- **Application name**: Claude Code Nexus - Cloudflare
- **Homepage URL**: https://claudeapi-1.satoshitech.xyz  
- **Authorization callback URL**: https://claudeapi-1.satoshitech.xyz/auth/callback
- **Client ID**: Ov23li86oPl2mZq0lZGe
- **Client Secret**: 28c51ab5a1a6bc7f4348e31f5ad00256e718590d

### 旧配置保留 (103.53.81.33服务器)
- **域名**: https://claudeapi.satoshitech.xyz
- **Client ID**: Ov23liuee9wIPJ0Y96zM
- **Client Secret**: 554ec985f47b0d0f9392ca41d71f69b87ba2d470
- **状态**: 保留配置，但服务已迁移到Cloudflare Workers

## 🗄️ Cloudflare 资源

### D1 数据库
- **名称**: claude-code-nexus
- **ID**: 905d7576-573a-4916-89f2-d11cdce90023
- **迁移状态**: ✅ 已完成 (0000, 0001, 0002)

### Workers Secrets
- `GITHUB_CLIENT_ID`: ✅ 已配置
- `GITHUB_CLIENT_SECRET`: ✅ 已配置  
- `ENCRYPTION_KEY`: ✅ 已配置 (ClaudeCodeNexusEncryptionKey2025)

### 路由配置
```json
{
  "routes": [
    "claudeapi-1.satoshitech.xyz/*"
  ]
}
```

## ⚡ 使用方法

### 1. 用户登录
访问 https://claudeapi-1.satoshitech.xyz → GitHub登录 → 获取API Key

### 2. Claude Code CLI 配置
```bash
export ANTHROPIC_BASE_URL="https://claudeapi-1.satoshitech.xyz"
export ANTHROPIC_API_KEY="用户的专属API Key"
```

## 🔄 部署命令

```bash
# 设置Secrets
echo "CLIENT_ID" | npx wrangler secret put GITHUB_CLIENT_ID --env=production
echo "CLIENT_SECRET" | npx wrangler secret put GITHUB_CLIENT_SECRET --env=production

# 数据库迁移
npx wrangler d1 migrations apply DB --env production --remote

# 部署
npm run deploy
```

## 📊 性能优势

- ✅ **全球CDN**: Cloudflare边缘网络
- ✅ **自动扩容**: 无服务器架构
- ✅ **高可用**: 99.9%+ SLA保证
- ✅ **低延迟**: 边缘计算优化
- ✅ **零运维**: 无需服务器管理

## 🚨 注意事项

1. **域名冲突**: 确保旧服务器nginx配置已清理
2. **DNS设置**: claudeapi-1.satoshitech.xyz 需通过Cloudflare代理
3. **OAuth应用**: 新旧两个应用并存，避免冲突
4. **SSL证书**: Cloudflare自动管理，无需Let's Encrypt

---

**部署状态**: ✅ 完成  
**最后更新**: 2025-08-24 17:40 UTC