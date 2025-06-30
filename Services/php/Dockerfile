FROM dunglas/frankenphp:php8.3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libgd-dev \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions (simplified)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        intl \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        zip \
        bcmath \
        opcache \
        sockets

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /app

# Create a simple index.php for testing
RUN mkdir -p /app/public && echo '<?php phpinfo(); ?>' > /app/public/index.php

# Expose ports
EXPOSE 8080 8443

# Default command
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
