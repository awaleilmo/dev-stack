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
TR='╗'
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
    # Use printf to clear screen directly - no external command dependencies
    printf '\033[2J\033[3J\033[H' >/dev/null 2>&1 || true
}

# Check if we're running in an interactive terminal
is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# Restore terminal to sane state
restore_terminal() {
    # Reset terminal line discipline to sane defaults
    stty sane >/dev/null 2>&1 || true
    stty echo >/dev/null 2>&1 || true
    stty icanon >/dev/null 2>&1 || true
    stty icrnl >/dev/null 2>&1 || true
    # Reset any terminal attributes that might be messed up
    tput sgr0 >/dev/null 2>&1 || true
    tput cnorm >/dev/null 2>&1 || true
    tput rmcup >/dev/null 2>&1 || true
    # Reset color
    printf '\033[0m' >/dev/null 2>&1 || true
    # Reset cursor
    printf '\033[?25h' >/dev/null 2>&1 || true
    # Reset scroll region
    printf '\033[r' >/dev/null 2>&1 || true
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

# Loading spinner animation
loading_spinner() {
    local pid="$1"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp="${spinstr#?}"
        printf "  ${GRAY}[${spinstr:0:1}]${NC} Loading..."
        printf "\r"
        spinstr=${temp}${spinstr:0:1}
        sleep "$delay"
    done
    printf "  ${GRAY} [ ]${NC} Done!     \r"
    sleep 0.2
}

# Print loading message with spinner
print_loading() {
    local message="$1"
    local pid
    # Run the actual command in background
    "$@" &
    pid=$!
    
    printf "  ${CYAN}${message}${NC} "
    loading_spinner "$pid"
    wait "$pid"
    return $?
}

# Get color based on service category
category_color() {
    local service="$1"
    local category="${SERVICE_CATEGORY[$service]:-tool}"
    
    case "$category" in
        database)   echo -e "${BLUE}" ;;
        cache)      echo -e "${GREEN}" ;;
        queue)      echo -e "${YELLOW}" ;;
        search)     echo -e "${CYAN}" ;;
        storage)    echo -e "${MAGENTA:-\033[0;35m}" ;;
        monitoring) echo -e "${RED}" ;;
        tool)       echo -e "${WHITE}" ;;
        *)          echo -e "${GRAY}" ;;
    esac
}

# Print colored category badge
print_category_badge() {
    local service="$1"
    local category="${SERVICE_CATEGORY[$service]:-tool}"
    local color
    color=$(category_color "$service")
    
    case "$category" in
        database)   echo -e "${color}[DB]${NC}" ;;
        cache)      echo -e "${color}[CACHE]${NC}" ;;
        queue)      echo -e "${color}[QUEUE]${NC}" ;;
        search)     echo -e "${color}[SEARCH]${NC}" ;;
        storage)    echo -e "${color}[STORAGE]${NC}" ;;
        monitoring) echo -e "${color}[MONITOR]${NC}" ;;
        tool)       echo -e "${color}[TOOL]${NC}" ;;
        *)          echo -e "${GRAY}[?]${NC}" ;;
    esac
}
