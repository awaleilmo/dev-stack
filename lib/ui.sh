#!/usr/bin/env bash
# lib/ui.sh - UI utilities for colorful output

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Box drawing characters
TL='╔'
TR='�╗'
BL='╚'
BR='╝'
TM='╠'
BM='╣'
HM='╬'
VM='╣'
VB='║'

# Print a bordered box
print_box() {
    local title="$1"
    local content="$2"
    local width=52
    
    echo -e "${CYAN}${TL}$(printf '%0.s─' $(seq 1 $width))${TR}"
    echo -e "${VB}  $title${VB}"
    echo -e "${TM}$(printf '%0.s─' $(seq 1 $width))${BM}"
    
    while IFS= read -r line; do
        printf "${VB}  ${line}${NC}${VB}\n"
    done <<< "$content"
    
    echo -e "${BL}$(printf '%0.s─' $(seq 1 $width))${BR}"
}

# Print header
print_header() {
    local title="$1"
    local subtitle="${2:-}"
    
    echo -e "${BOLD}${CYAN}"
    echo -e "${TL}$(printf '%0.s─' $(seq 1 48))${TR}"
    echo -e "${VB}  🐳 $title${NC}${VB}"
    if [[ -n "$subtitle" ]]; then
        echo -e "${VB}  $subtitle${NC}${VB}"
    fi
    echo -e "${TM}$(printf '%0.s─' $(seq 1 48))${BM}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Print info message
print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Print prompt
print_prompt() {
    echo -ne "${BOLD}${WHITE}$1${NC}"
}

# Safe clear - never hang or fail even on a broken terminal
safe_clear() {
    clear >/dev/null 2>&1 || printf '\033[2J\033[3J\033[H' >/dev/null 2>&1 || true
}

# Timeout-wrapped docker for non-interactive calls (detection, status, network)
# so the CLI never hangs if the Docker daemon is unreachable or stuck.
# Interactive calls (logs -f, exec -it, up -d) are NOT wrapped on purpose.
docker_safe() {
    if command -v timeout >/dev/null 2>&1; then
        command timeout 20 docker "$@"
    else
        command docker "$@"
    fi
}

# Print service status icon
status_icon() {
    local status="$1"
    case "$status" in
        running)   echo -en "${GREEN}✅${NC}" ;;
        stopped)   echo -en "${YELLOW}⬚${NC}" ;;
        not-installed) echo -en "${RED}❌${NC}" ;;
        update-available) echo -en "${YELLOW}⬆️${NC}" ;;
        *)         echo -en "  " ;;
    esac
}

# Print service status text
status_text() {
    local status="$1"
    case "$status" in
        running)   echo -e "${GREEN}running${NC}" ;;
        stopped)   echo -e "${YELLOW}stopped${NC}" ;;
        not-installed) echo -e "${RED}not installed${NC}" ;;
        update-available) echo -e "${YELLOW}update available${NC}" ;;
        *)         echo -e "${GRAY}unknown${NC}" ;;
    esac
}
