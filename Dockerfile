# 使用 Node.js 20 Alpine 镜像
FROM node:20-alpine

# 安装必要的系统依赖
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    libc6-compat \
    curl

# 设置工作目录
WORKDIR /app

# 复制包文件
COPY package.json pnpm-lock.yaml ./

# 安装 pnpm
RUN npm install -g pnpm

# 安装依赖
RUN pnpm install

# 复制源代码
COPY . .

# 构建项目
RUN pnpm build:client && pnpm generate:html

# 暴露端口
EXPOSE 8787

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8787/api/health || exit 1

# 启动命令
CMD ["pnpm", "dev:backend"]