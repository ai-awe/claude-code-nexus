# Claude Code Nexus - 5分钟快速部署

> 🚀 **最快速的Claude Code Nexus部署指南** - 从0到上线只需5分钟！

## ⚡ 一键部署脚本

### 前置准备 (30秒)
```bash
# 确保已安装 Node.js 18+ 和 git
node --version && git --version

# 全局安装 wrangler (如果没有)
npm install -g wrangler
```

### 快速部署 (4分钟)

#### 1. 克隆项目 (30秒)
```bash
git clone https://github.com/KroMiose/claude-code-nexus.git
cd claude-code-nexus
pnpm install
```

#### 2. Cloudflare 配置 (1分钟)
```bash
# 登录 Cloudflare
npx wrangler login

# 创建数据库
npx wrangler d1 create claude-code-nexus
```
📝 **复制返回的数据库ID**，更新到 `wrangler.jsonc` 第34行。

#### 3. GitHub OAuth (1分钟)
1. 打开：https://github.com/settings/applications/new
2. 快速填写：
   - **Name**: `Claude Code Nexus`
   - **Homepage**: `https://your-worker.workers.dev`
   - **Callback**: `https://your-worker.workers.dev/auth/callback`
3. 📝 **复制 Client ID 和 Secret**

#### 4. 设置密钥 (30秒)
```bash
echo "您的CLIENT_ID" | npx wrangler secret put GITHUB_CLIENT_ID --env=production
echo "您的CLIENT_SECRET" | npx wrangler secret put GITHUB_CLIENT_SECRET --env=production
echo "ClaudeNexus2025EncryptionKey32Char" | npx wrangler secret put ENCRYPTION_KEY --env=production
```

#### 5. 数据库迁移 + 部署 (1分钟)
```bash
npm run deploy
```

## 🎉 部署完成！

部署成功后：
1. **访问您的Workers域名** (控制台会显示)
2. **测试GitHub登录**
3. **获取API Key**
4. **开始使用**

## 🔧 使用Claude Code CLI

```bash
export ANTHROPIC_BASE_URL="https://您的workers域名"
export ANTHROPIC_API_KEY="您的API Key"
claude
```

## 💡 自定义域名 (可选)

如果您有域名，在Cloudflare添加DNS记录：
- **Type**: CNAME
- **Name**: `claude-api`  
- **Content**: 您的Workers域名
- **Proxy**: ✅ 启用

然后更新 `wrangler.jsonc` 中的域名配置。

## 🆘 遇到问题？

**常见问题快速修复**：

1. **数据库ID错误** → 检查 `wrangler.jsonc` 第34行
2. **OAuth回调错误** → 确认GitHub回调URL是 `/auth/callback`
3. **域名访问404** → 确保DNS记录状态为"Proxied"

**获取帮助**：
- 查看完整文档：`DEPLOYMENT_GUIDE.md`
- 提交Issue：GitHub Issues

---

**🎯 成功案例**: https://claudeapi-1.satoshitech.xyz  
**⏱️ 部署时间**: 4分32秒  
**✅ 状态**: 完美运行  

**享受您的Claude Code Nexus！** 🚀