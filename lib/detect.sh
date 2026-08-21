#!/usr/bin/env bash
# lib/detect.sh - System detection functions
# Guard to prevent re-declaration of globals when sourced multiple times

if [[ -z "${_DETECT_SH_SOURCED:-}" ]]; then
    _DETECT_SH_SOURCED=1
else
    return 0
fi

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global state
declare -g SYSTEM_OS=""
declare -g SYSTEM_DISTRO=""
declare -g SYSTEM_PM=""
declare -g HAS_DOCKER=false
declare -g DOCKER_VERSION=""
declare -g HAS_MISE=false
declare -g MISE_VERSION=""
declare -g HAS_PHP=false
declare -g PHP_VERSION=""
declare -g HAS_NODE=false
declare -g NODE_VERSION=""
declare -g HAS_PYTHON=false
declare -g PYTHON_VERSION=""
declare -g MISSING_DEPS=()

# Check if command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Detect OS and distribution
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        SYSTEM_OS="$ID"
        SYSTEM_DISTRO="$NAME"
    elif [[ -f /etc/debian_version ]]; then
        SYSTEM_OS="debian"
        SYSTEM_DISTRO="Debian"
    elif [[ -f /etc/redhat-release ]]; then
        SYSTEM_OS="rhel"
        SYSTEM_DISTRO="$(cat /etc/redhat-release)"
    elif [[ -f /etc/arch-release ]]; then
        SYSTEM_OS="arch"
        SYSTEM_DISTRO="Arch Linux"
    else
        SYSTEM_OS="unknown"
        SYSTEM_DISTRO="Unknown Linux"
    fi
}

# Detect package manager
detect_pm() {
    if has_cmd apt-get; then
        SYSTEM_PM="apt"
    elif has_cmd dnf; then
        SYSTEM_PM="dnf"
    elif has_cmd yum; then
        SYSTEM_PM="yum"
    elif has_cmd pacman; then
        SYSTEM_PM="pacman"
    else
        SYSTEM_PM="unknown"
    fi
}

# Detect Docker
detect_docker() {
    if has_cmd docker; then
        if docker info &>/dev/null 2>&1; then
            HAS_DOCKER=true
            DOCKER_VERSION="$(docker --version 2>/dev/null | sed -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
            if [[ -z "$DOCKER_VERSION" ]]; then
                DOCKER_VERSION="installed"
            fi
        fi
    fi
}

# Detect mise
detect_mise() {
    if has_cmd mise; then
        HAS_MISE=true
        MISE_VERSION="$(mise --version 2>/dev/null | awk '{print $1}')"
        if [[ -z "$MISE_VERSION" ]]; then
            MISE_VERSION="installed"
        fi
    fi
}

# Detect PHP via mise
detect_php() {
    if [[ "$HAS_MISE" == true ]]; then
        local mise_output
        mise_output="$(mise current php 2>/dev/null || true)"
        if [[ -n "$mise_output" ]] && echo "$mise_output" | grep -qE "^${MISE_PHP_VERSION}"; then
            HAS_PHP=true
            PHP_VERSION="$(php -v 2>/dev/null | head -1 | awk '{print $2}' || true)"
        fi
    fi
}

# Detect Node.js via mise
detect_node() {
    if [[ "$HAS_MISE" == true ]]; then
        local mise_output
        mise_output="$(mise current node 2>/dev/null || true)"
        if [[ -n "$mise_output" ]] && echo "$mise_output" | grep -qE "^${MISE_NODE_VERSION}"; then
            HAS_NODE=true
            NODE_VERSION="$(node -v 2>/dev/null | sed 's/v//' || true)"
        fi
    fi
}

# Detect Python via mise
detect_python() {
    if [[ "$HAS_MISE" == true ]]; then
        local mise_output
        mise_output="$(mise current python 2>/dev/null || true)"
        if [[ -n "$mise_output" ]] && echo "$mise_output" | grep -qE "^${MISE_PYTHON_VERSION}"; then
            HAS_PYTHON=true
            PYTHON_VERSION="$(python3 --version 2>/dev/null | awk '{print $2}' || true)"
        fi
    fi
}

# Detect system dependencies
declare -gA REQUIRED_SYSTEM_DEPS=(
    [curl]=curl
    [git]=git
    [nano]=nano
)

declare -gA PHP_SYSTEM_DEPS=(
    [libssl-dev]=libssl-dev
    [libzip-dev]=libzip-dev
    [libonig-dev]=libonig-dev
    [libxml2-dev]=libxml2-dev
    [libpng-dev]=libpng-dev
    [libicu-dev]=libicu-dev
    [libjpeg-dev]=libjpeg-dev
    [libbz2-dev]=libbz2-dev
    [zlib1g-dev]=zlib1g-dev
)

declare -gA PYTHON_SYSTEM_DEPS=(
    [libreadline-dev]=libreadline-dev
    [libsqlite3-dev]=libsqlite3-dev
    [libffi-dev]=libffi-dev
    [liblzma-dev]=liblzma-dev
    [tk-dev]=tk-dev
)

detect_system_deps() {
    MISSING_DEPS=()
    
    # Check basic tools
    for dep in "${!REQUIRED_SYSTEM_DEPS[@]}"; do
        if ! has_cmd "${REQUIRED_SYSTEM_DEPS[$dep]}"; then
            MISSING_DEPS+=("system:$dep")
        fi
    done
    
    # Check PHP dependencies (if mise available)
    if [[ "$HAS_MISE" == true ]]; then
        for dep in "${!PHP_SYSTEM_DEPS[@]}"; do
            if ! dpkg -s "${PHP_SYSTEM_DEPS[$dep]}" &>/dev/null 2>&1; then
                MISSING_DEPS+=("php:$dep")
            fi
        done
        
        for dep in "${!PYTHON_SYSTEM_DEPS[@]}"; do
            if ! dpkg -s "${PYTHON_SYSTEM_DEPS[$dep]}" &>/dev/null 2>&1; then
                MISSING_DEPS+=("python:$dep")
            fi
        done
    fi
}

# Run all detections
detect_all() {
    detect_os
    detect_pm
    detect_docker
    detect_mise
    detect_php
    detect_node
    detect_python
    detect_system_deps
}

# Print detection results summary
print_detection_summary() {
    echo -e "${CYAN}System Information:${NC}"
    echo "  OS: $SYSTEM_DISTRO ($SYSTEM_OS)"
    echo "  Package Manager: $SYSTEM_PM"
    echo ""
    echo -e "${CYAN}Prerequisites:${NC}"
    if [[ "$HAS_DOCKER" == true ]]; then
        echo -e "  ${GREEN}✅${NC} Docker Engine: $DOCKER_VERSION"
    else
        echo -e "  ${RED}❌${NC} Docker Engine: not installed"
    fi
    
    if [[ "$HAS_MISE" == true ]]; then
        echo -e "  ${GREEN}✅${NC} mise: $MISE_VERSION"
    else
        echo -e "  ${RED}❌${NC} mise: not installed"
    fi
    echo ""
    echo -e "${CYAN}Development Runtimes:${NC}"
    if [[ "$HAS_PHP" == true ]]; then
        echo -e "  ${GREEN}✅${NC} PHP ${MISE_PHP_VERSION}: ${PHP_VERSION:-installed}"
    else
        echo -e "  ${YELLOW}⬚${NC} PHP ${MISE_PHP_VERSION}: not configured via mise"
    fi
    
    if [[ "$HAS_NODE" == true ]]; then
        echo -e "  ${GREEN}✅${NC} Node.js ${MISE_NODE_VERSION}: ${NODE_VERSION:-installed}"
    else
        echo -e "  ${YELLOW}⬚${NC} Node.js ${MISE_NODE_VERSION}: not configured via mise"
    fi
    
    if [[ "$HAS_PYTHON" == true ]]; then
        echo -e "  ${GREEN}✅${NC} Python ${MISE_PYTHON_VERSION}: ${PYTHON_VERSION:-installed}"
    else
        echo -e "  ${YELLOW}⬚${NC} Python ${MISE_PYTHON_VERSION}: not configured via mise"
    fi
    echo ""
}
