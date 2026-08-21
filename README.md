# 🐳 Docker Development Toolkit

Simple, manual Docker development environment with global CLI access. No automated scripts - just one command to manage everything.

## ✨ Features

- **🌍 Global CLI** - Use `devstack` from any directory
- **🔧 Modular Services** - Pick and choose what you need
- **📁 Project Agnostic** - Works with any PHP/Node project
- **💻 IDE Friendly** - Right-click → Open Terminal
- **🔗 No Lock-in** - Simple Docker Compose files

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/awaleilmo/dev-stack.git ~/dev-stack
cd ~/dev-stack
```

### 2. Install Global Command (One-time)

```bash
./bin/devstack-install
```

### 3. Run Dev Stack

```bash
devstack
```

Or from the repository:

```bash
./bin/devstack
```

## 📁 Repository Structure

```
dev-stack/
├── bin/
│   ├── devstack          # Main CLI entry point
│   └── devstack-install  # Global command installer
├── lib/
│   ├── config.sh         # Configuration defaults
│   ├── detect.sh         # System detection
│   ├─�� ui.sh             # UI utilities
│   ├── menu.sh           # Interactive menu
│   ├── services.sh       # Service registry
│   └── guides.sh         # Installation guides
├── services/             # Individual services
│   ├── mysql/           # MySQL 8.0
│   ├── postgres/        # PostgreSQL 15
│   ├── mongodb/         # MongoDB 7.0
│   ├── redis/           # Redis 7
│   ├── adminer/         # Database manager
│   ├── mailpit/         # Email testing (modern replacement for MailHog)
│   ├── rabbitmq/        # Message broker (Laravel Queues, Celery)
│   ├── meilisearch/     # Full-text search engine
│   ├── minio/           # S3 storage
│   ├── portainer/       # Docker WebUI
│   ├── prometheus/      # Metrics collection
│   ├── grafana/         # Metrics visualization
│   └── jaeger/          # Distributed tracing
└── docs/
    └── CLI-DESIGN.md     # CLI design documentation
```

## 🎛️ Service Management

### Starting Services

```bash
devstack
# Then select service number [1-10] and choose action
```

### Available Services

| # | Service | Container | Image | Port |
|---|---------|-----------|-------|------|
| 1 | MySQL | mysql8-dev | mysql:8.0 | 3306 |
| 2 | PostgreSQL | postgres15-dev | postgres:15 | 5432 |
| 3 | MongoDB | mongodb-dev | mongo:7.0 | 27017 |
| 4 | Redis | redis-dev | redis:7-alpine | 6379 |
| 5 | Adminer | adminer-dev | adminer:latest | 8081 |
| 6 | Mailpit | mailpit-dev | axllent/mailpit:latest | 8026 |
| 7 | RabbitMQ | rabbitmq-dev | rabbitmq:3-management-alpine | 5672 / 15672 |
| 8 | Meilisearch | meilisearch-dev | getmeili/meilisearch:latest | 7700 |
| 9 | MinIO | minio-dev | minio/minio:latest | 9001 |
| 10 | Portainer | portainer-dev | portainer/portainer-ce:latest | 9000 |
| 11 | Prometheus | prometheus-dev | prom/prometheus:latest | 9090 |
| 12 | Grafana | grafana-dev | grafana/grafana:latest | 3000 |
| 13 | Jaeger | jaeger-dev | jaegertracing/all-in-one:latest | 16686 |

## 🌐 Web Interfaces

- **Adminer (Database)**: http://localhost:8081
- **Mailpit (Email Testing)**: http://localhost:8026
- **RabbitMQ Management**: http://localhost:15672 (admin/adminpass)
- **Meilisearch Dashboard**: http://localhost:7700
- **Portainer (Docker UI)**: http://localhost:9000 (admin/admin)
- **MinIO Console (S3 Storage)**: http://localhost:9002 (admin/password123)
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Jaeger**: http://localhost:16686

## 💻 Development Runtimes (via mise)

This toolkit manages Docker services. For development runtimes (PHP, Node.js, Python), use [mise](https://mise.jdx.dev/):

```bash
# Install mise
curl https://mise.run | sh

# Configure global versions
mise use -g php@8.3 node@22 python@3.13

# Verify
php -v
node -v
python3 -v
```

## 📖 CLI Commands

### Main Menu

| Key | Action |
|-----|--------|
| `1-8` | Manage specific service |
| `U` | Update all images |
| `A` | Start all services |
| `S` | Stop all services |
| `I` | Install mise runtime |
| `Q` | Quit |

### Service Submenu

| Key | Action |
|-----|--------|
| `S` | Start |
| `T` | Stop |
| `R` | Restart |
| `L` | Logs (follow) |
| `H` | Shell access |
| `U` | Update image |
| `D` | Remove (with data) |
| `I` | Install (new) |
| `B` | Back to main menu |

## 🗄️ Database Information

| Service | Host | Port | Username | Password | Database |
|---------|------|------|----------|----------|----------|
| MySQL | localhost | 3306 | user | userpass | app_db |
| PostgreSQL | localhost | 5432 | pguser | pgpass | app_pgdb |
| Redis | localhost | 6379 | - | - | - |
| MongoDB | localhost | 27017 | mongouser | mongopass | app_mongo |
| MinIO | localhost | 9001 | admin | password123 | - |

## 🔧 Customization

### Change Ports

Edit `.env` file:

```bash
MYSQL_PORT=3306
POSTGRES_PORT=5432
REDIS_PORT=6379
```

### Change Database Passwords

```bash
MYSQL_ROOT_PASSWORD=rootpass
MYSQL_PASSWORD=userpass
POSTGRES_PASSWORD=pgpass
```

## 🔄 Management

### Check Status

```bash
devstack
# View running services in the main menu
```

### Update All Services

```bash
devstack
# Press [U] to pull all images
```

### Uninstall Global Command

```bash
rm -f ~/.local/bin/devstack
```

## 🛠️ Requirements

- Docker & Docker Compose
- Git
- Bash or Zsh shell
- Linux OS (Ubuntu/Debian/Fedora/Arch)

## 📄 License

MIT License

---

**Simple. Manual. No Magic.** 🎯

One command to manage your development stack.
