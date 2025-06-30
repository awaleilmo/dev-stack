# 🐳 Docker Development Toolkit

Simple, manual Docker development environment with global PHP/Composer access. No automated scripts - just copy, paste, and run.

## ✨ Features

- **🌍 Global Commands** - Use `php`, `composer`, `artisan` from any directory
- **🔧 Modular Services** - Pick and choose what you need
- **📁 Project Agnostic** - Works with any PHP project structure
- **💻 IDE Friendly** - Right-click → Open Terminal → `composer install`
- **🔗 No Lock-in** - Simple Docker Compose files you can customize

## 🚀 Quick Start (5 Minutes)

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/dev-stack.git ~/dev-stack
cd ~/dev-stack
```

### 2. Create Network

```bash
docker network create dev-network
```

### 3. Start Services

```bash
# Full stack (all services)
cd stacks/
docker-compose -f full-stack.yml up -d

# OR PHP + MySQL only
docker-compose -f php-mysql.yml up -d
```

### 4. Add Aliases (Copy-Paste)

```bash
# Copy content from aliases/bashrc-snippet.txt
# Paste into your ~/.bashrc
nano ~/.bashrc

# Reload shell
source ~/.bashrc
```

### 5. Test

```bash
# Test from any directory
cd ~/Documents
php -v
composer -V

# Visit http://localhost:8080
# Visit http://localhost:8081 (Adminer)
```

## 📁 Repository Structure

```
dev-stack/
├── services/              # Individual services
│   ├── php/              # FrankenPHP + PHP 8.3
│   ├── mysql/            # MySQL 8.0
│   ├── postgres/         # PostgreSQL 15  
│   ├── redis/            # Redis 7
│   ├── adminer/          # Database manager
│   └── mailhog/          # Email testing
├── stacks/               # Combined stacks
│   ├── full-stack.yml    # All services
│   ├── php-mysql.yml     # PHP + MySQL + Adminer
│   └── php-postgres.yml  # PHP + PostgreSQL + Adminer
└── aliases/              # Copy-paste aliases
    ├── bashrc-snippet.txt
    └── zshrc-snippet.txt
```

## 🎛️ Service Options

### Option 1: Full Stack

Everything included:

```bash
cd stacks/
docker-compose -f full-stack.yml up -d
```

**Includes:** PHP, MySQL, PostgreSQL, Redis, Adminer, MailHog

### Option 2: PHP + MySQL

Most common setup:

```bash
cd stacks/  
docker-compose -f php-mysql.yml up -d
```

**Includes:** PHP, MySQL, Adminer

### Option 3: Individual Services

Pick exactly what you need:

```bash
# Start PHP
cd services/php/
docker-compose up -d

# Start MySQL
cd ../mysql/
docker-compose up -d

# Start Adminer
cd ../adminer/
docker-compose up -d
```

## 🗄️ Database Information

| Service | Host | Port | Username | Password | Database |
|---------|------|------|----------|----------|----------|
| MySQL | localhost | 3306 | user | userpass | app_db |
| PostgreSQL | localhost | 5432 | pguser | pgpass | app_pgdb |
| Redis | localhost | 6379 | - | - | - |

## 🌐 Web Interfaces

- **Application**: http://localhost:8080
- **Adminer (Database)**: http://localhost:8081  
- **MailHog (Email)**: http://localhost:8025

## 💻 Available Commands

After adding aliases, these work from **any directory**:

```bash
# Core commands
php -v                    # PHP version
composer install          # Install dependencies
artisan migrate           # Laravel artisan

# Laravel shortcuts  
migrate                   # php artisan migrate
fresh                     # php artisan migrate:fresh --seed
tinker                    # php artisan tinker
serve                     # php artisan serve

# Database connections
mysql-connect             # Connect to MySQL
postgres-connect          # Connect to PostgreSQL
redis-cli                 # Connect to Redis

# Container access
franken                   # Enter PHP container
franken-here             # Enter container in current directory
```

## 🎯 Usage Examples

### Laravel Project

```bash
# Any Laravel project directory
cd ~/my-laravel-project

# Works immediately
composer install
cp .env.example .env
php artisan key:generate
migrate
serve
```

### Symfony Project

```bash
cd ~/my-symfony-project
composer install
php bin/console doctrine:migrations:migrate
php -S localhost:8000 -t public/
```

### Any PHP Project

```bash
cd /any/php/project
php -v                    # ✅ Works
composer update           # ✅ Works
php index.php            # ✅ Works
```

## 🔧 Customization

### Change Ports

Edit any `docker-compose.yml`:

```yaml
ports:
  - "8081:8080"  # Change port to 8081
```

### Change Database Passwords

```yaml
environment:
  MYSQL_ROOT_PASSWORD: your_secure_password
  MYSQL_PASSWORD: your_user_password
```

### Add PHP Extensions

Edit `services/php/Dockerfile`:

```dockerfile
RUN docker-php-ext-install your_extension
```

Rebuild:
```bash
cd services/php/
docker-compose down
docker-compose up -d --build
```

## 🔄 Management

### Start/Stop Services

```bash
# Start full stack
cd stacks/
docker-compose -f full-stack.yml up -d

# Stop full stack
docker-compose -f full-stack.yml down

# Individual service
cd services/php/
docker-compose up -d
docker-compose down
```

### Check Status

```bash
docker ps
docker logs frankenphp-dev
```

### Update

```bash
cd ~/dev-stack
git pull origin main
docker-compose pull
docker-compose up -d --build
```

## 🛠️ Requirements

- Docker & Docker Compose
- Git
- Bash or Zsh shell

## 📖 Documentation

- [Manual Setup Guide](docs/MANUAL-SETUP.md) - Detailed setup instructions
- [Usage Guide](docs/USAGE.md) - Complete usage examples

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Make changes
4. Submit pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

**Simple. Manual. No Magic.** 🎯

Just Docker Compose files and copy-paste aliases for global PHP development access.
