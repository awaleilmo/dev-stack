#!/usr/bin/env bash
# lib/guides.sh - Generate installation guides

set -euo pipefail

# Source dependencies (detect.sh is already sourced, guarded by _DETECT_SH_SOURCED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ui.sh"

# Generate Docker installation guide
generate_docker_guide() {
    local guide_file="${1:-docker-installation.md}"
    
    cat > "$guide_file" << EOF
# Docker Installation Guide — Linux

## Detected System
- OS: $SYSTEM_DISTRO ($SYSTEM_OS)
- Package Manager: $SYSTEM_PM

EOF

    case "$SYSTEM_PM" in
        apt)
            cat >> "$guide_file" << 'EOF'
## Step 1: Install Docker
```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
```

## Step 2: Add User to Docker Group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## Step 3: Verify Installation
```bash
docker --version
docker compose version
```

## Next
Run `./bin/devstack` again after Docker is installed.
EOF
            ;;
        dnf|yum)
            cat >> "$guide_file" << 'EOF'
## Step 1: Install Docker
```bash
sudo dnf install -y docker docker-compose-plugin
sudo systemctl enable --now docker
```

## Step 2: Add User to Docker Group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## Step 3: Verify Installation
```bash
docker --version
docker compose version
```

## Next
Run `./bin/devstack` again after Docker is installed.
EOF
            ;;
        pacman)
            cat >> "$guide_file" << 'EOF'
## Step 1: Install Docker
```bash
sudo pacman -Syu docker docker-compose
sudo systemctl enable --now docker
```

## Step 2: Add User to Docker Group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## Step 3: Verify Installation
```bash
docker --version
docker compose version
```

## Next
Run `./bin/devstack` again after Docker is installed.
EOF
            ;;
        *)
            cat >> "$guide_file" << 'EOF'
## Installation Instructions

For your Linux distribution, please visit the official Docker documentation:
https://docs.docker.com/engine/install/

Choose your distribution and follow the installation instructions.

## Next
Run `./bin/devstack` again after Docker is installed.
EOF
            ;;
    esac
    
    echo "$guide_file"
}

# Generate development environment guide
generate_devenv_guide() {
    local guide_file="${1:-development-environment-installation.md}"
    
    cat > "$guide_file" << EOF
# Development Environment Installation Guide

## Detected System
- OS: $SYSTEM_DISTRO ($SYSTEM_OS)
- Package Manager: $SYSTEM_PM

## Target Runtimes
- PHP: ${MISE_PHP_VERSION}
- Node.js: ${MISE_NODE_VERSION}
- Python: ${MISE_PYTHON_VERSION}

EOF

    # Check what's missing
    local has_mise_install=false
    local has_php_configured=false
    local has_node_configured=false
    local has_python_configured=false
    
    if [[ "$HAS_MISE" == false ]]; then
        has_mise_install=true
    fi
    if [[ "$HAS_PHP" == false ]]; then
        has_php_configured=true
    fi
    if [[ "$HAS_NODE" == false ]]; then
        has_node_configured=true
    fi
    if [[ "$HAS_PYTHON" == false ]]; then
        has_python_configured=true
    fi
    
    # Generate content based on what's missing
    if [[ "$has_mise_install" == true ]]; then
        cat >> "$guide_file" << 'EOF'
## Step 1: Install mise
```bash
curl https://mise.run | sh
```

Then add mise to your shell configuration:
```bash
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

EOF
    fi
    
    if [[ "$has_php_configured" == true || "$has_node_configured" == true || "$has_python_configured" == true ]]; then
        cat >> "$guide_file" << EOF
## Step 2: Configure Runtimes via mise

EOF
        if [[ "$has_php_configured" == true ]]; then
            echo "\`\`\`bash" >> "$guide_file"
            echo "mise use -g php@${MISE_PHP_VERSION}" >> "$guide_file"
            echo "\`\`\`" >> "$guide_file"
            echo "" >> "$guide_file"
        fi
        if [[ "$has_node_configured" == true ]]; then
            echo "\`\`\`bash" >> "$guide_file"
            echo "mise use -g node@${MISE_NODE_VERSION}" >> "$guide_file"
            echo "\`\`\`" >> "$guide_file"
            echo "" >> "$guide_file"
        fi
        if [[ "$has_python_configured" == true ]]; then
            echo "\`\`\`bash" >> "$guide_file"
            echo "mise use -g python@${MISE_PYTHON_VERSION}" >> "$guide_file"
            echo "\`\`\`" >> "$guide_file"
            echo "" >> "$guide_file"
        fi
    fi
    
    # Check system dependencies
    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        echo "## Step 3: Install System Dependencies" >> "$guide_file"
        echo "" >> "$guide_file"
        
        local apt_deps=()
        local php_deps=()
        local python_deps=()
        
        for dep in "${MISSING_DEPS[@]}"; do
            local type="${dep%%:*}"
            local pkg="${dep##*:}"
            
            case "$type" in
                system) apt_deps+=("$pkg") ;;
                php) php_deps+=("$pkg") ;;
                python) python_deps+=("$pkg") ;;
            esac
        done
        
        if [[ ${#apt_deps[@]} -gt 0 ]]; then
            cat >> "$guide_file" << EOF
Some system packages are missing. Install them with:

\`\`\`bash
sudo ${SYSTEM_PM} install -y ${apt_deps[*]}
\`\`\`

EOF
        fi
        
        if [[ ${#php_deps[@]} -gt 0 ]]; then
            cat >> "$guide_file" << EOF
PHP compilation requires these system libraries:

\`\`\`bash
sudo ${SYSTEM_PM} install -y ${php_deps[*]}
\`\`\`

EOF
        fi
        
        if [[ ${#python_deps[@]} -gt 0 ]]; then
            cat >> "$guide_file" << EOF
Python compilation requires these system libraries:

\`\`\`bash
sudo ${SYSTEM_PM} install -y ${python_deps[*]}
\`\`\`

EOF
        fi
    fi
    
    cat >> "$guide_file" << 'EOF'
## Step 4: Verify Installation
```bash
php -v
node -v
python3 -v
```

## Next
Run `./bin/devstack` again after the development environment is set up.
EOF
    
    echo "$guide_file"
}

# Check if guide is needed and generate it
check_and_generate_guide() {
    local guide_type="$1"  # "docker" or "devenv"
    local guide_file=""
    
    case "$guide_type" in
        docker)
            guide_file=$(generate_docker_guide)
            print_warning "Docker is not installed."
            echo "Installation guide created: $guide_file"
            echo ""
            echo "Please read and execute the installation guide before continuing."
            return 1
            ;;
        devenv)
            guide_file=$(generate_devenv_guide)
            print_warning "Development environment setup is required."
            echo "Installation guide created: $guide_file"
            echo ""
            echo "You can still use this CLI to manage Docker services, but"
            echo "PHP/Node.js/Python development will require running the guide."
            ;;
    esac
}
