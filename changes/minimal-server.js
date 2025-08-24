const { serve } = require('@hono/node-server');
const { Hono } = require('hono');
const { cors } = require('hono/cors');
const fs = require('fs');
const crypto = require('crypto');

const app = new Hono();

// 简单文件存储
const dataDir = './data';
const usersFile = dataDir + '/users.json';

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir);
}

function getUsers() {
  if (!fs.existsSync(usersFile)) {
    return {};
  }
  return JSON.parse(fs.readFileSync(usersFile, 'utf8'));
}

function saveUser(githubId, userData) {
  const users = getUsers();
  users[githubId] = userData;
  fs.writeFileSync(usersFile, JSON.stringify(users, null, 2));
}

function findUserByApiKey(apiKey) {
  const users = getUsers();
  for (const id in users) {
    if (users[id].api_key === apiKey) {
      return users[id];
    }
  }
  return null;
}

// CORS
app.use('/*', cors());

// 健康检查
app.get('/health', (c) => {
  return c.json({ status: 'ok', service: 'Claude Code Nexus' });
});

// 首页
app.get('/', (c) => {
  return c.html(`
    <html>
      <head><title>Claude Code Nexus</title></head>
      <body style="font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px;">
        <h1>🚀 Claude Code Nexus</h1>
        <p>Claude Code API 代理服务</p>
        <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h3>开始使用</h3>
          <p>通过 GitHub 登录获取 API Key：</p>
          <a href="/auth/github" style="background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">通过 GitHub 登录</a>
        </div>
      </body>
    </html>
  `);
});

// GitHub OAuth
app.get('/auth/github', (c) => {
  const params = new URLSearchParams({
    client_id: 'Ov23li2JrYOEwqBpUg7m',
    redirect_uri: 'https://claudeapilocal.satoshitech.xyz/auth/github/callback',
    scope: 'user:email'
  });
  return c.redirect('https://github.com/login/oauth/authorize?' + params.toString());
});

app.get('/auth/github/callback', async (c) => {
  const code = c.req.query('code');
  if (!code) {
    return c.text('No code provided', 400);
  }

  try {
    const tokenRes = await fetch('https://github.com/login/oauth/access_token', {
      method: 'POST',
      headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: 'Ov23li2JrYOEwqBpUg7m',
        client_secret: 'ca71cdaf8e1c86e27a6d2dea6e8c5a9d7e5d9c3b',
        code: code
      })
    });

    const tokenData = await tokenRes.json();
    if (!tokenData.access_token) {
      return c.text('Failed to get token', 400);
    }

    const userRes = await fetch('https://api.github.com/user', {
      headers: { 'Authorization': 'Bearer ' + tokenData.access_token }
    });

    const user = await userRes.json();
    const apiKey = 'ak-nexus-' + crypto.randomBytes(20).toString('hex');

    saveUser(user.id.toString(), {
      github_id: user.id,
      username: user.login,
      name: user.name,
      email: user.email,
      api_key: apiKey,
      created_at: new Date().toISOString()
    });

    return c.html(`
      <html>
        <head><title>登录成功</title></head>
        <body style="font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px;">
          <h1>🎉 登录成功!</h1>
          <div style="background: #d4edda; color: #155724; padding: 20px; border-radius: 8px;">
            <p>欢迎 ${user.name || user.login}!</p>
            <p><strong>API Key:</strong> <code style="background: #eee; padding: 4px;">${apiKey}</code></p>
          </div>
          <h3>配置 Claude Code</h3>
          <pre style="background: #eee; padding: 15px; border-radius: 4px;">export ANTHROPIC_API_KEY=${apiKey}
export ANTHROPIC_BASE_URL=https://claudeapilocal.satoshitech.xyz</pre>
          <p><a href="/">← 返回首页</a></p>
        </body>
      </html>
    `);
  } catch (err) {
    return c.text('Error: ' + err.message, 500);
  }
});

// Claude API
app.post('/v1/messages', async (c) => {
  const auth = c.req.header('Authorization');
  if (!auth || !auth.startsWith('Bearer ')) {
    return c.json({ error: 'Missing authorization' }, 401);
  }

  const apiKey = auth.substring(7);
  const user = findUserByApiKey(apiKey);
  if (!user) {
    return c.json({ error: 'Invalid API key' }, 401);
  }

  const body = await c.req.json();
  
  return c.json({
    id: 'msg_' + crypto.randomBytes(16).toString('hex'),
    type: 'message',
    role: 'assistant',
    content: [{
      type: 'text',
      text: `Hello ${user.username}! Claude Code Nexus is working. This is a test response for model: ${body.model || 'claude-3-5-sonnet-20241022'}.`
    }],
    model: body.model || 'claude-3-5-sonnet-20241022',
    stop_reason: 'end_turn',
    usage: { input_tokens: 10, output_tokens: 25 }
  });
});

const port = 3008;
console.log('🚀 Starting Claude Code Nexus on port', port);
serve({ fetch: app.fetch, port });