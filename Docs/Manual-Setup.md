# 📖 Manual Setup Guide

Simple manual setup instructions without automated scripts.

## 🎯 Quick Setup (5 Minutes)

### 1. Create Network

```bash
# Create shared network for all services
docker network create dev-network
```

### 2. Choose Your Stack

Pick one of these options:

#### Option A: Full Stack (All Services)
```bash
cd stacks/
docker-compose -f full-stack.yml up -d
```

#### Option B: PHP + MySQL Only
```bash
cd stacks/
docker-compose -f php-mysql.yml up -d
```

#### Option C: Individual Services
```bash
# Start PHP service
cd services/php/
docker-compose up -d

# Start MySQL service  
cd ../mysql/
docker-compose up -d

# Start Adminer
cd ../adminer/
docker-compose up -d
```

### 3. Add Aliases (Optional)

Copy content from `aliases/bashrc-snippet.txt` and paste into your `~/.bashrc`:

```bash
# Open your bashrc
nano ~/.bashrc

# Paste the aliases at the end
# Save and reload
source ~/.bashrc
```

### 4. Test

```bash
# Test global commands
php -v
composer -V

# Test from any directory
cd ~/Documents
php -v

# Test web interfaces
# Open http://localhost:8080 (PHP)
# Open http://localhost:8081 (Adminer)
```

## 🔧 Service Management

### Starting Services

```bash
# Full stack
cd stacks/
docker-compose -f full-stack.yml up -d

# Individual service
cd services/php/
docker-compose up -d
```

### Stopping Services

```bash
# Full stack
cd stacks/
docker-compose -f full-stack.yml down

# Individual service
cd services/php/
docker-compose down
```

### Checking Status

```bash
# See all containers
docker ps

# See specific containers
docker ps --filter "name=frankenphp-dev"
```

## 📁 Directory Structure

```
dev-stack/
├── services/           # Individual services
│   ├── php/           # PHP + FrankenPHP
│   ├── mysql/         # MySQL database
│   ├── postgres/      # PostgreSQL database
│   ├── redis/         # Redis cache
│   ├── adminer/       # Database manager
│   └── mailhog/       # Email testing
├── stacks/            # Combined stacks
│   ├── full-stack.yml    # All services
│   ├── php-mysql.yml     # PHP + MySQL
│   └── php-postgres.yml  # PHP + PostgreSQL
└── aliases/           # Copy-paste aliases
    ├── bashrc-snippet.txt
    └── zshrc-snippet.txt
```

## 🎛️ Customization

### Change Ports

Edit the docker-compose.yml files:

```yaml
ports:
  - "8081:8080"  # Change 8080 to 8081
```

### Change Database Passwords

Edit environment variables:

```yaml
environment:
  MYSQL_ROOT_PASSWORD: your_password
  MYSQL_PASSWORD: your_user_password
```

### Add Custom PHP Extensions

Edit `services/php/Dockerfile`:

```dockerfile
RUN docker-php-ext-install your_extension
```

Then rebuild:
```bash
cd services/php/
docker-compose down
docker-compose up -d --build
```

## 🗄️ Database Info

| Service | Host | Port | Username | Password | Database |
|---------|------|------|----------|----------|----------|
| MySQL | localhost | 3306 | user | userpass | app_db |
| PostgreSQL | localhost | 5432 | pguser | pgpass | app_pgdb |
| Redis | localhost | 6379 | - | - | - |

## 🌐 Web Interfaces

- **Application**: http://localhost:8080
- **Adminer**: http://localhost:8081
- **MailHog**: http://localhost:8025

## 💡 Usage Examples

### Laravel Project

```bash
# Navigate to your Laravel project
cd ~/my-laravel-project

# Install dependencies
composer install

# Run migrations
php artisan migrate

# Start development server
php artisan serve
```

### Any PHP Project

```bash
# Navigate to any project
cd /path/to/any/php/project

# Use PHP and Composer normally
php -v
composer install
php index.php
```

## 🔧 Troubleshooting

### Commands Not Found

Make sure you copied the aliases to your shell configuration:

```bash
# Check if aliases exist
alias php

# If not found, add them manually
source aliases/bashrc-snippet.txt
```

### Port Conflicts

Change ports in docker-compose.yml files:

```yaml
ports:
  - "3307:3306"  # MySQL on port 3307 instead of 3306
```

### Container Won't Start

Check logs:

```bash
# Check specific container logs
docker logs frankenphp-dev
docker logs mysql8-dev

# Check all logs
docker-compose logs
```

### Reset Everything

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove network
docker network rm dev-network

# Start fresh
docker network create dev-network
cd stacks/
docker-compose -f full-stack.yml up -d
```

That's it! Simple manual setup without any automated scripts. 🎉
