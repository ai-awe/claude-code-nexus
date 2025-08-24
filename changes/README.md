# Changes Directory

这个目录包含了部署过程中创建和修改的文件。

## 文件清单

### 1. minimal-server.js
- **用途**: 简化的Node.js服务器，用于在传统Linux服务器上运行Claude Code Nexus
- **功能**: 
  - GitHub OAuth认证
  - 基础API代理
  - 简单的文件存储用户数据
  - 健康检查端点
- **端口**: 3008
- **数据存储**: `./data/users.json` (文件存储)

### 2. Caddyfile.backup
- **用途**: Caddy反向代理配置
- **功能**:
  - 自动SSL证书获取 (Let's Encrypt)
  - HTTP到HTTPS重定向
  - 反向代理到localhost:3008
  - 安全头设置
  - 访问日志记录

## 部署配置说明

### 服务器环境
- **服务器**: 103.125.219.164
- **域名**: claudeapi.satoshitech.xyz
- **SSL**: Let's Encrypt自动获取
- **防火墙**: 开放80, 443, 3008端口

### OAuth配置
```javascript
client_id: 'Ov23li2JrYOEwqBpUg7m'
client_secret: 'ca71cdaf8e1c86e27a6d2dea6e8c5a9d7e5d9c3b'
callback_url: 'https://claudeapi.satoshitech.xyz/auth/github/callback'
```

### 启动命令
```bash
cd /opt/claude-nexus
node minimal-server.js > server.log 2>&1 &
```

### 验证命令
```bash
# 健康检查
curl https://claudeapi.satoshitech.xyz/health

# 首页
curl https://claudeapi.satoshitech.xyz/

# 服务状态
ss -tlnp | grep :3008
```

## 注意事项

1. **数据存储**: 使用简单文件存储，生产环境建议使用数据库
2. **安全性**: API密钥明文存储，生产环境需要加密
3. **可扩展性**: 单机部署，需要负载均衡考虑集群
4. **监控**: 基础日志记录，建议增加监控告警

## 恢复原始环境

如需恢复到原始Cloudflare Workers环境：
1. 修改DNS解析回103.114.163.238
2. 停止本地服务：`pkill -f minimal-server.js`
3. 在Cloudflare部署原始代码

## 性能测试结果

- ✅ HTTPS访问正常
- ✅ SSL证书自动获取
- ✅ 健康检查响应: 45字节JSON
- ✅ OAuth重定向功能
- 🔲 完整API功能测试（待验证）