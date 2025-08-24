// 简单的 Node.js 服务器替代 Cloudflare Workers dev
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const url = require('url');
const querystring = require('querystring');

const PORT = 8787;

// 环境变量配置
const GITHUB_CLIENT_ID = 'Ov23liuee9wIPJ0Y96zM';
const GITHUB_CLIENT_SECRET = '554ec985f47b0d0f9392ca41d71f69b87ba2d470';
const ENCRYPTION_KEY = '32characterencryptionkey12345678';
const APP_BASE_URL = 'https://claudeapi.satoshitech.xyz';

// HTTP请求工具函数
function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const response = {
            statusCode: res.statusCode,
            headers: res.headers,
            data: data
          };
          resolve(response);
        } catch (error) {
          reject(error);
        }
      });
    });
    
    req.on('error', reject);
    
    if (postData) {
      req.write(postData);
    }
    
    req.end();
  });
}

// GitHub OAuth 回调处理函数
async function handleGitHubCallback(req, res, query) {
  try {
    if (!query.code) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Authorization code not found' }));
      return;
    }

    // 交换 code 获取 access token
    const tokenOptions = {
      hostname: 'github.com',
      path: '/login/oauth/access_token',
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Claude-Code-Nexus/1.0'
      }
    };

    const tokenData = querystring.stringify({
      client_id: GITHUB_CLIENT_ID,
      client_secret: GITHUB_CLIENT_SECRET,
      code: query.code
    });

    const tokenResponse = await makeRequest(tokenOptions, tokenData);
    
    if (tokenResponse.statusCode !== 200) {
      throw new Error(`GitHub token exchange failed: ${tokenResponse.data}`);
    }

    const tokenResult = JSON.parse(tokenResponse.data);
    
    if (tokenResult.error) {
      throw new Error(`GitHub OAuth error: ${tokenResult.error_description || tokenResult.error}`);
    }

    // 获取用户信息
    const userOptions = {
      hostname: 'api.github.com',
      path: '/user',
      method: 'GET',
      headers: {
        'Authorization': `token ${tokenResult.access_token}`,
        'User-Agent': 'Claude-Code-Nexus/1.0',
        'Accept': 'application/vnd.github.v3+json'
      }
    };

    const userResponse = await makeRequest(userOptions);
    
    if (userResponse.statusCode !== 200) {
      throw new Error(`GitHub user info failed: ${userResponse.data}`);
    }

    const userData = JSON.parse(userResponse.data);

    // 成功登录，返回成功页面
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
      <html>
        <head>
          <title>登录成功 - Claude Code Nexus</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .success { color: #28a745; }
            .info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px auto; max-width: 500px; }
          </style>
        </head>
        <body>
          <h1 class="success">🎉 GitHub 登录成功！</h1>
          <div class="info">
            <p><strong>用户名:</strong> ${userData.login}</p>
            <p><strong>邮箱:</strong> ${userData.email || '未公开'}</p>
            <p><strong>Access Token:</strong></p>
            <code style="background: #e9ecef; padding: 10px; display: block; word-break: break-all;">${tokenResult.access_token}</code>
          </div>
          <p>请将上面的 Access Token 配置到您的 Claude Code CLI 中：</p>
          <pre style="background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: left; max-width: 600px; margin: 0 auto;">
export ANTHROPIC_BASE_URL="https://claudeapi.satoshitech.xyz/"
export ANTHROPIC_AUTH_TOKEN="${tokenResult.access_token}"</pre>
          <p><a href="/">返回首页</a></p>
        </body>
      </html>
    `);

  } catch (error) {
    console.error('GitHub OAuth callback error:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      error: 'Internal server error', 
      message: error.message 
    }));
  }
}

const server = http.createServer((req, res) => {
  // CORS 头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;
  
  // API 健康检查
  if (pathname === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'OK', timestamp: new Date().toISOString() }));
    return;
  }
  
  // GitHub OAuth 登录端点
  if (pathname === '/api/auth/github') {
    const state = Math.random().toString(36).substring(7);
    const redirectUrl = `https://github.com/login/oauth/authorize?client_id=${GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(APP_BASE_URL + '/api/auth/github/callback')}&scope=user:email&state=${state}`;
    
    res.writeHead(302, { 'Location': redirectUrl });
    res.end();
    return;
  }
  
  // GitHub OAuth 回调端点
  if (pathname === '/api/auth/github/callback') {
    handleGitHubCallback(req, res, query);
    return;
  }
  
  // API 根路径
  if (pathname.startsWith('/api/')) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      message: 'Claude Code Nexus API', 
      version: '0.1.0',
      endpoints: ['/api/health', '/api/auth/github'] 
    }));
    return;
  }
  
  // 静态文件服务
  let filePath = path.join(__dirname, 'dist/client', pathname === '/' ? 'index.html' : pathname);
  
  // 检查文件是否存在
  if (!fs.existsSync(filePath)) {
    // 如果是 SPA 路由，返回 index.html
    if (!pathname.includes('.') && !pathname.startsWith('/api/')) {
      filePath = path.join(__dirname, 'dist/client/index.html');
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not Found');
      return;
    }
  }
  
  const ext = path.extname(filePath);
  const contentType = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
  }[ext] || 'text/plain';
  
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500);
      res.end('Server Error');
      return;
    }
    
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Claude Code Nexus server running on http://0.0.0.0:${PORT}`);
  console.log(`📍 Health check: http://0.0.0.0:${PORT}/api/health`);
  console.log(`🔐 GitHub OAuth: http://0.0.0.0:${PORT}/api/auth/github`);
});