# Claude Code Nexus 变更记录

## 📅 2025-08-25 主要更新

### 🚀 核心功能实现

#### 1. **Cloudflare Workers 部署**
- 成功部署到 `https://claudeapi-1.satoshitech.xyz`
- 配置了 D1 数据库和环境变量
- 设置了自定义域名路由

#### 2. **前端配置更新**
- **文件**: `frontend/src/pages/HomePage.tsx`
  - 将示例中的 `ANTHROPIC_BASE_URL` 从 `https://claude.nekro.ai` 改为 `https://claudeapi-1.satoshitech.xyz`
  
- **文件**: `frontend/src/pages/DashboardPage.tsx`
  - 更新了三处 URL 引用，全部改为用户自己的服务地址
  - 修改了配置教程中的示例 URL

#### 3. **OAuth 登录修复**
- **文件**: `frontend/src/hooks/useAuth.ts`
  - 修复了登录流程，改为先获取 OAuth URL 再跳转
  - 解决了 CORS 错误问题

#### 4. **API 配置优化**
- **文件**: `src/config/defaultModelMappings.ts`
  - 添加了 "NexusAI API" 作为预设供应商
  - 将 "谷歌Gemini" 的 URL 改为用户的服务地址
  - 更新默认 API 配置指向 "谷歌Gemini"

#### 5. **Gemini 原生格式支持**
- **文件**: `src/utils/claudeConverter.ts`
  - 新增 `convertClaudeToGemini()` 函数
  - 新增 `convertGeminiToClaude()` 函数
  - 支持 Gemini 原生 API 格式转换

- **文件**: `src/routes/claude.ts`
  - 添加了 Gemini 格式检测逻辑
  - 根据 URL 路径自动选择转换格式
  - 支持 `x-goog-api-key` 认证头

#### 6. **新用户默认配置**
- **文件**: `src/routes/auth.ts`
  - 新用户注册时自动配置默认 Gemini API
  - 设置默认 API Key 和 baseUrl

### 📝 新增文档

1. **README-CN.md** - 中文项目说明文档
2. **DEPLOYMENT_GUIDE.md** - 详细的部署指南
3. **CLOUDFLARE_DEPLOYMENT.md** - Cloudflare Workers 部署步骤
4. **QUICK_START.md** - 快速开始指南
5. **test-claude-connection.md** - 测试连接文档
6. **diagnose.md** - 故障诊断指南
7. **debug-no-response.md** - 无响应问题排查

### 🔧 调试工具

1. **test-api.sh** - API 测试脚本
2. **test-debug.sh** - 详细调试脚本
3. **test-stream.sh** - 流式响应测试
4. **debug-gemini.sh** - Gemini API 调试工具

### 🗑️ 删除文件

- **simple-server.js** - 移除了临时的测试服务器

### 🔧 配置文件更新

- **wrangler.jsonc**
  - 更新了生产环境配置
  - 设置了正确的域名路由

### 💡 关键改进

1. **统一域名配置**
   - 所有 `https://claude.nekro.ai` 引用都改为 `https://claudeapi-1.satoshitech.xyz`
   - 确保用户使用自己的服务而不是外部服务

2. **多 API 支持**
   - 支持 Gemini 原生格式
   - 保持 OpenAI 格式兼容
   - 灵活的模型映射配置

3. **用户体验优化**
   - 改进了错误处理
   - 添加了详细的调试信息
   - 提供了完整的故障排查工具

## 🎯 实现效果

- ✅ Claude Code CLI 可以成功连接到部署的服务
- ✅ 支持多种 AI API 后端（Gemini、OpenAI 兼容服务等）
- ✅ 用户可以自主配置和管理 API 服务
- ✅ 完整的 OAuth 登录和用户管理功能
- ✅ 流式和非流式响应都能正常工作

## 📊 技术栈

- **部署平台**: Cloudflare Workers
- **数据库**: Cloudflare D1
- **前端框架**: React + TypeScript + Material-UI
- **后端框架**: Hono
- **认证方式**: GitHub OAuth
- **API 格式**: Claude API 兼容

## 🔗 相关链接

- 生产环境：https://claudeapi-1.satoshitech.xyz
- GitHub OAuth 应用：已配置回调地址