FROM node:lts-alpine

# Set labels
LABEL maintainer="Docker Dev Toolkit"
LABEL description="Node.js LTS for frontend development"

# Install basic tools
RUN apk add --no-cache \
    git \
    bash \
    && rm -rf /var/cache/apk/*

# Enable corepack for yarn and pnpm
RUN corepack enable

# Set working directory
WORKDIR /workspace

# Default command - keep container running
CMD ["tail", "-f", "/dev/null"]
