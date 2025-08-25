# 变更文件清单

## 📝 修改的文件 (Modified)

### 前端文件
1. **frontend/src/hooks/useAuth.ts**
   - 修复 OAuth 登录流程的 CORS 问题

2. **frontend/src/pages/HomePage.tsx**
   - 更新示例配置中的 `ANTHROPIC_BASE_URL`

3. **frontend/src/pages/DashboardPage.tsx**
   - 替换三处 `https://claude.nekro.ai` 为 `https://claudeapi-1.satoshitech.xyz`

### 后端文件
4. **src/config/defaultModelMappings.ts**
   - 添加 NexusAI API 预设
   - 修改谷歌 Gemini 的默认 URL
   - 更新默认 API 配置

5. **src/routes/auth.ts**
   - 新用户自动配置默认 Gemini API
   - 添加默认 API Key 加密存储

6. **src/routes/claude.ts**
   - 添加 Gemini 原生格式检测
   - 实现格式自动切换逻辑
   - 支持 x-goog-api-key 认证

7. **src/utils/claudeConverter.ts**
   - 新增 Gemini 格式转换函数
   - 支持双向格式转换

### 配置文件
8. **wrangler.jsonc**
   - 更新生产环境配置
   - 设置域名路由

## ➕ 新增的文件 (Added)

### 文档类
- `README-CN.md` - 中文说明文档
- `DEPLOYMENT_GUIDE.md` - 部署指南
- `CLOUDFLARE_DEPLOYMENT.md` - Cloudflare 部署步骤
- `QUICK_START.md` - 快速开始
- `test-claude-connection.md` - 连接测试文档
- `diagnose.md` - 故障诊断
- `debug-no-response.md` - 无响应排查

### 工具脚本
- `test-api.sh` - API 测试工具
- `test-debug.sh` - 调试工具
- `test-stream.sh` - 流式测试
- `debug-gemini.sh` - Gemini 调试

## ➖ 删除的文件 (Deleted)
- `simple-server.js` - 临时测试服务器（不再需要）

## 📊 变更统计
- 修改文件：8 个
- 新增文件：11 个
- 删除文件：1 个
- 总计变更：20 个文件