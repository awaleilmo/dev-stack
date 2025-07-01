FROM node:lts-alpine

# Set labels
LABEL maintainer="Docker Dev Toolkit"
LABEL description="Node.js LTS for frontend development"

# Install additional tools
RUN apk add --no-cache \
    git \
    curl \
    bash \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Install global packages
RUN npm install -g \
    @vue/cli \
    @angular/cli \
    create-react-app \
    vite \
    webpack \
    webpack-cli \
    typescript \
    ts-node \
    nodemon \
    pm2 \
    yarn \
    pnpm \
    eslint \
    prettier \
    && npm cache clean --force

# Set working directory
WORKDIR /workspace

# Create package.json for global workspace
RUN echo '{\
  "name": "nodejs-workspace",\
  "version": "1.0.0",\
  "description": "Node.js development workspace",\
  "scripts": {\
    "dev": "echo Please navigate to your project directory",\
    "build": "echo Please navigate to your project directory",\
    "start": "echo Please navigate to your project directory"\
  }\
}' > package.json

# Expose common development ports
EXPOSE 3000 3001 4200 5173 8080

# Default command - keep container running
CMD ["tail", "-f", "/dev/null"]
