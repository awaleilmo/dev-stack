#!/usr/bin/env bash
# lib/menu.sh - Interactive menu system

set -euo pipefail

# Source dependencies (detect.sh is already sourced, guarded by _DETECT_SH_SOURCED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ui.sh"
source "$SCRIPT_DIR/../lib/services.sh"

# Service display numbers
declare -A SERVICE_NUMBER=()
for i in "${!SERVICE_ORDER[@]}"; do
    SERVICE_NUMBER["${SERVICE_ORDER[$i]}"]=$((i + 1))
done

# Count services by status
count_services_by_status() {
    local status="$1"
    local count=0
    for service in "${SERVICE_ORDER[@]}"; do
        local svc_status
        svc_status=$(get_service_status "$service")
        [[ "$svc_status" == "$status" ]] && ((count++))
    done
    echo "$count"
}

# Check if guide file exists and is valid
guide_exists() {
    local guide_file="$1"
    [[ -f "$guide_file" ]] && [[ -s "$guide_file" ]] && return 0
    return 1
}

# Force regenerate all guides (ignores existing files)
force_regenerate_guides() {
    local guide_dir
    guide_dir="$(pwd)"
    local regenerated=0
    
    # Always regenerate Docker guide if Docker is missing
    if [[ "$HAS_DOCKER" == false ]]; then
        local df
        df=$(generate_docker_guide "$guide_dir/docker-installation.md")
        echo "  ✅ Generated: $df"
        regenerated=$((regenerated + 1))
    fi
    
    # Always regenerate DevEnv guide if mise is missing
    if [[ "$HAS_MISE" == false ]]; then
        local gf
        gf=$(generate_devenv_guide "$guide_dir/development-environment-installation.md")
        echo "  ✅ Generated: $gf"
        regenerated=$((regenerated + 1))
    fi
    
    # If .env is missing, show instructions
    if [[ "$HAS_ENV" == false ]]; then
        echo ""
        echo "  ⚠️  .env file is missing"
        echo "  💡 Run: cp .env.example .env"
        echo "     Then edit: nano .env"
    fi
    
    return $regenerated
}

# Get required guides based on system state
get_required_guides() {
    local guides=()
    local guide_dir
    guide_dir="$(pwd)"
    
    if [[ "$HAS_DOCKER" == false ]]; then
        guides+=("$guide_dir/docker-installation.md:Docker Engine")
    fi
    if [[ "$HAS_MISE" == false ]]; then
        guides+=("$guide_dir/development-environment-installation.md:Development Environment (mise)")
    fi
    if [[ "$HAS_ENV" == false ]]; then
        guides+=(".env:Environment Configuration")
    fi
    
    printf '%s\n' "${guides[@]}"
}

# List available guide files
list_guide_files() {
    local guide_dir
    guide_dir="$(pwd)"
    local found_any=false
    
    echo "  ${CYAN}Guide Files:${NC}"
    echo ""
    
    # Check Docker guide
    local docker_guide="$guide_dir/docker-installation.md"
    if guide_exists "$docker_guide"; then
        local size
        size=$(wc -l < "$docker_guide" 2>/dev/null || echo "?")
        echo "  ✅ $docker_guide ($size lines)"
        found_any=true
    elif [[ "$HAS_DOCKER" == false ]]; then
        echo "  ❌ $docker_guide (MISSING - needs generation)"
        found_any=true
    fi
    
    # Check DevEnv guide
    local devenv_guide="$guide_dir/development-environment-installation.md"
    if guide_exists "$devenv_guide"; then
        local size
        size=$(wc -l < "$devenv_guide" 2>/dev/null || echo "?")
        echo "  ✅ $devenv_guide ($size lines)"
        found_any=true
    elif [[ "$HAS_MISE" == false ]]; then
        echo "  ❌ $devenv_guide (MISSING - needs generation)"
        found_any=true
    fi
    
    # Check .env
    local env_file="$guide_dir/.env"
    if [[ -f "$env_file" ]]; then
        echo "  ✅ $env_file (configured)"
        found_any=true
    elif [[ "$HAS_ENV" == false ]]; then
        echo "  ⚠️  $env_file (missing - run: cp .env.example .env)"
        found_any=true
    fi
    
    if [[ "$found_any" == false ]]; then
        echo "  ℹ️  No guides needed - all dependencies are installed"
    fi
    echo ""
}

# Show main menu
show_main_menu() {
    # Don't clear here - let the caller handle it to avoid flickering
    print_header "Dev Stack Manager v1.0"
    echo ""
    
    # Prerequisites section
    echo -e "  ${CYAN}Prerequisites${NC}"
    if [[ "$HAS_DOCKER" == true ]]; then
        echo -e "  ${VB} ${GREEN}✅${NC} Docker Engine: ${DOCKER_VERSION}${NC}"
    else
        echo -e "  ${VB} ${RED}❌${NC} Docker Engine: not installed"
    fi
    if [[ "$HAS_MISE" == true ]]; then
        echo -e "  ${VB} ${GREEN}✅${NC} mise: ${MISE_VERSION}${NC}"
    else
        echo -e "  ${VB} ${RED}❌${NC} mise: not installed"
    fi
    if [[ "$HAS_ENV" == true ]]; then
        echo -e "  ${VB} ${GREEN}✅${NC} .env: configured"
    else
        echo -e "  ${VB} ${YELLOW}⚠️${NC} .env: not found"
    fi
    echo ""
    
    # Guide files status (compact)
    local guide_dir
    guide_dir="$(pwd)"
    local docker_guide="$guide_dir/docker-installation.md"
    local devenv_guide="$guide_dir/development-environment-installation.md"
    
    if [[ "$HAS_DOCKER" == false ]] || [[ "$HAS_MISE" == false ]] || [[ "$HAS_ENV" == false ]]; then
        echo -e "  ${CYAN}Guide Files:${NC}"
        if guide_exists "$docker_guide"; then
            echo -e "  ${VB} ${GREEN}✅${NC} docker-installation.md"
        elif [[ "$HAS_DOCKER" == false ]]; then
            echo -e "  ${VB} ${RED}❌${NC} docker-installation.md (needs generation)"
        fi
        if guide_exists "$devenv_guide"; then
            echo -e "  ${VB} ${GREEN}✅${NC} development-environment-installation.md"
        elif [[ "$HAS_MISE" == false ]]; then
            echo -e "  ${VB} ${RED}❌${NC} development-environment-installation.md (needs generation)"
        fi
        if [[ "$HAS_ENV" == false ]]; then
            echo -e "  ${VB} ${YELLOW}⚠️${NC} .env (run: cp .env.example .env)"
        fi
        echo ""
    fi
    echo ""
    
    # Services section - grouped by category
    echo -e "  ${CYAN}Services${NC}"
    printf "  ${VB} %-3s %-14s %-16s %-12s %-8s\n" "#" "SERVICE" "CONTAINER" "PORT" "STATUS"
    printf "  ${VB} %-3s %-14s %-16s %-12s %-8s\n" "---" "--------------" "----------------" "--------" "--------"
    
    local num=1
    for service in "${SERVICE_ORDER[@]}"; do
        local status
        status=$(get_service_status "$service")
        local label="${SERVICE_LABEL[$service]}"
        local container="${SERVICE_CONTAINER[$service]}"
        local port="${SERVICE_PORT[$service]}"
        local icon
        icon=$(status_icon "$status")
        
        printf "  ${VB} %-3s ${icon} %-12s %-16s %-12s %-8s\n" \
            "$num" \
            "$label" \
            "$container" \
            "$port" \
            "$(status_text "$status")"
        num=$((num + 1))
    done
    echo "  ${VB}$(printf '%0.s ' $(seq 1 62))${VB}"
    echo ""
    
    # Service summary
    local running stopped not_installed
    running=$(count_services_by_status "running")
    stopped=$(count_services_by_status "stopped")
    not_installed=$(count_services_by_status "not-installed")
    echo -e "  ${GRAY}Summary: ${running} running, ${stopped} stopped, ${not_installed} not installed${NC}"
    echo ""
    
    # Actions section
    echo -e "  ${CYAN}Actions${NC}"
    echo -e "  ${VB} [U] Update All Images${NC}      - Pull image terbaru dari registry"
    echo -e "  ${VB} [A] Start All Services${NC}     - Jalankan semua service yang sudah terinstall"
    echo -e "  ${VB} [S] Stop All Services${NC}      - Hentikan semua container yang berjalan"
    echo -e "  ${VB} [G] Generate Guides${NC}        - Buat panduan instalasi (jika ada yang missing)"
    echo -e "  ${VB} [I] Install Mise Runtime${NC}  - Cek & buat panduan install mise + PHP/Node/Python"
    echo -e "  ${VB} [E] Install PHP Extensions${NC} - Pasang ekstensi PHP via pecl (butuh PHP aktif)"
    echo -e "  ${VB} [V] Verify System${NC}          - Tampilkan status lengkap sistem & runtime"
    echo ""
    echo -ne "  ${BOLD}Select service [1-${#SERVICE_ORDER[@]}] or action [0/U/A/S/G/I/E/V/Q]:${NC} "
}

# Show service submenu
show_service_menu() {
    local service="$1"
    local status
    status=$(get_service_status "$service")
    local label="${SERVICE_LABEL[$service]}"
    local web_url="${SERVICE_WEB_URL[$service]:-}"
    
    safe_clear
    print_header "Service: $label ($status)"
    
    echo ""
    echo -e "  ${CYAN}Details${NC}"
    echo "  Image: ${SERVICE_IMAGE[$service]}"
    echo "  Container: ${SERVICE_CONTAINER[$service]}"
    echo "  Port: ${SERVICE_PORT[$service]}"
    if [[ -n "$web_url" ]]; then
        echo -e "  Web UI: ${CYAN}${web_url}${NC}"
    fi
    echo ""
    
    echo -e "  ${CYAN}Actions${NC}"
    
    if [[ "$status" == "not-installed" ]]; then
        echo "  [1] Install         - Download image & buat container baru"
        echo "  [2] Download Image  - Download image saja (tanpa container)"
    else
        echo "  [1] Start           - Jalankan container"
        echo "  [2] Stop            - Hentikan container"
        echo "  [3] Restart         - Stop lalu start ulang"
        echo "  [4] Logs            - Lihat log container (-f)"
        echo "  [5] Shell           - Masuk ke container bash"
        echo "  [6] Update Image    - Pull image baru & restart container"
        echo "  [7] Remove          - Hapus container & data (destructive)"
        if [[ -n "$web_url" ]]; then
            echo "  [8] Open Web UI     - Buka ${label} di browser"
        fi
    fi
    echo ""
    echo "  [0] Back to Main Menu"
    echo ""
    echo -ne "  Enter choice: ${BOLD}"
}

# Handle service action
handle_service_action() {
    local service="$1"
    local action="$2"
    
    case "$action" in
        1) 
            local status
            status=$(get_service_status "$service")
            if [[ "$status" == "not-installed" ]]; then
                install_service "$service"
            else
                start_service "$service"
            fi
            ;;
        2)
            local status
            status=$(get_service_status "$service")
            if [[ "$status" == "not-installed" ]]; then
                download_image "$service"
            else
                stop_service "$service"
            fi
            ;;
        3) restart_service "$service" ;;
        4) show_logs "$service" ;;
        5) enter_shell "$service" ;;
        6) update_service "$service" ;;
        7) remove_service "$service" ;;
        8)
            local web_url="${SERVICE_WEB_URL[$service]:-}"
            if [[ -n "$web_url" ]]; then
                xdg-open "$web_url" 2>/dev/null || open "$web_url" 2>/dev/null || echo "Please open: $web_url"
            else
                print_warning "No Web UI available for this service"
            fi
            ;;
        0) return 1 ;;
        *) print_error "Invalid choice"; sleep 1 ;;
    esac
    
    return 0
}

# Handle main menu action
handle_main_action() {
    local action="$1"
    
    case "$action" in
        U|u)
            echo ""
            echo "Pulling all images..."
            echo ""
            for service in "${SERVICE_ORDER[@]}"; do
                local status
                status=$(get_service_status "$service")
                if [[ "$status" != "not-installed" ]]; then
                    echo -n "  $service: "
                    docker compose -f "${SERVICE_DIR[$service]}/docker-compose.yml" pull 2>&1 | tail -1
                fi
            done
            echo ""
            print_success "All images updated"
            ;;
        A|a)
            echo ""
            echo "Starting all services..."
            echo ""
            for service in "${SERVICE_ORDER[@]}"; do
                local status
                status=$(get_service_status "$service")
                if [[ "$status" != "not-installed" ]]; then
                    start_service "$service"
                fi
            done
            ;;
        S|s)
            echo ""
            echo "Stopping all services..."
            echo ""
            for service in "${SERVICE_ORDER[@]}"; do
                local status
                status=$(get_service_status "$service")
                if [[ "$status" == "running" ]]; then
                    stop_service "$service"
                fi
            done
            ;;
        G|g)
            safe_clear
            print_header "Installation Guides"
            echo ""
            echo "  Menu ini akan:"
            echo "  1. Cek keberadaan file guide"
            echo "  2. Regenerate otomatis jika file hilang atau dependency belum terinstall"
            echo ""
            
            # Force regenerate based on current system state
            local guide_dir
            guide_dir="$(pwd)"
            local regenerated=0
            
            # Check and regenerate Docker guide
            local docker_guide="$guide_dir/docker-installation.md"
            if [[ "$HAS_DOCKER" == false ]] || ! guide_exists "$docker_guide"; then
                if [[ "$HAS_DOCKER" == false ]]; then
                    local df
                    df=$(generate_docker_guide "$docker_guide")
                    echo "  ✅ Generated: $df"
                    regenerated=$((regenerated + 1))
                elif ! guide_exists "$docker_guide"; then
                    echo "  ⚠️  Docker sudah terinstall tapi file guide hilang"
                    echo "  💡 Guide akan dibuat ulang: $docker_guide"
                    local df
                    df=$(generate_docker_guide "$docker_guide")
                    echo "  ✅ Regenerated: $df"
                    regenerated=$((regenerated + 1))
                fi
            fi
            
            # Check and regenerate DevEnv guide
            local devenv_guide="$guide_dir/development-environment-installation.md"
            if [[ "$HAS_MISE" == false ]] || ! guide_exists "$devenv_guide"; then
                if [[ "$HAS_MISE" == false ]]; then
                    local gf
                    gf=$(generate_devenv_guide "$devenv_guide")
                    echo "  ✅ Generated: $gf"
                    regenerated=$((regenerated + 1))
                elif ! guide_exists "$devenv_guide"; then
                    echo "  ⚠️  Mise sudah terinstall tapi file guide hilang"
                    echo "  💡 Guide akan dibuat ulang: $devenv_guide"
                    local gf
                    gf=$(generate_devenv_guide "$devenv_guide")
                    echo "  ✅ Regenerated: $gf"
                    regenerated=$((regenerated + 1))
                fi
            fi
            
            # Check .env
            if [[ "$HAS_ENV" == false ]]; then
                echo ""
                echo "  ⚠️  .env file tidak ditemukan"
                echo "  💡 Jalankan:"
                echo "     cp .env.example .env"
                echo "     nano .env"
            fi
            
            # Show current guide files
            echo ""
            echo "  ${CYAN}Guide Files Status:${NC}"
            if guide_exists "$docker_guide"; then
                local lines
                lines=$(wc -l < "$docker_guide" 2>/dev/null || echo "?")
                echo "  ✅ docker-installation.md ($lines lines)"
            else
                echo "  ❌ docker-installation.md (missing)"
            fi
            if guide_exists "$devenv_guide"; then
                local lines
                lines=$(wc -l < "$devenv_guide" 2>/dev/null || echo "?")
                echo "  ✅ development-environment-installation.md ($lines lines)"
            else
                echo "  ❌ development-environment-installation.md (missing)"
            fi
            if [[ -f "$guide_dir/.env" ]]; then
                echo "  ✅ .env (configured)"
            else
                echo "  ❌ .env (missing)"
            fi
            echo ""
            
            if [[ $regenerated -eq 0 ]] && [[ "$HAS_ENV" == true ]]; then
                echo "  ✅ Semua guide sudah up-to-date. Tidak ada yang perlu dibuat."
            else
                echo "  📁 Lokasi guide: $(pwd)/"
                echo ""
                echo "  💡 Buka dengan editor:"
                echo "     nano docker-installation.md"
                echo "     nano development-environment-installation.md"
            fi
            echo ""
            echo -n "  Press Enter to continue..."
            read -r || true
            ;;
        I|i)
            safe_clear
            print_header "Install Mise Runtime"
            echo ""
            echo "  Action ini akan:"
            echo "  1. Cek apakah mise sudah terinstall"
            echo "  2. Jika belum, buat panduan instalasi mise"
            echo "  3. Menampilkan status PHP, Node.js, dan Python"
            echo ""
            
            if [[ "$HAS_MISE" == false ]]; then
                local guide_file
                guide_file=$(generate_devenv_guide)
                echo ""
                print_warning "mise belum terinstall."
                echo ""
                echo "  📄 Panduan instalasi dibuat:"
                echo "  $guide_file"
                echo ""
                echo "  Isi panduan tersebut berisi:"
                echo "  - Cara install mise (tool version manager)"
                echo "  - Cara install PHP ${MISE_PHP_VERSION}, Node.js ${MISE_NODE_VERSION}, Python ${MISE_PYTHON_VERSION}"
                echo "  - Cara install Composer"
                echo "  - Dependencies sistem yang diperlukan"
                echo ""
                echo "  💡 Buka file tersebut dengan: nano $guide_file"
                echo ""
            else
                echo "  ✅ mise sudah terinstall: $MISE_VERSION"
                echo ""
                echo "  Status Runtime saat ini:"
                echo "  - PHP ${MISE_PHP_VERSION}: $([ "$HAS_PHP" == true ] && echo "✅ ${PHP_VERSION:-installed}" || echo "⬚ belum dikonfigurasi")"
                echo "  - Node.js ${MISE_NODE_VERSION}: $([ "$HAS_NODE" == true ] && echo "✅ ${NODE_VERSION:-installed}" || echo "⬚ belum dikonfigurasi")"
                echo "  - Python ${MISE_PYTHON_VERSION}: $([ "$HAS_PYTHON" == true ] && echo "✅ ${PYTHON_VERSION:-installed}" || echo "⬚ belum dikonfigurasi")"
                echo ""
                echo "  Status Backend Runtimes:"
                if [[ "$HAS_GO" == true ]]; then
                    echo "  - Go: ✅ ${GO_VERSION:-installed}"
                else
                    echo "  - Go: ⬚ belum terinstall"
                fi
                echo ""
                echo "  Status Frontend Package Managers:"
                if [[ "$HAS_PNPM" == true ]]; then
                    echo "  - pnpm: ✅ ${PNPM_VERSION:-installed}"
                else
                    echo "  - pnpm: ⬚ belum terinstall"
                fi
                if [[ "$HAS_BUN" == true ]]; then
                    echo "  - Bun: ✅ ${BUN_VERSION:-installed}"
                else
                    echo "  - Bun: ⬚ belum terinstall"
                fi
                echo ""
                echo "  Status Tools:"
                if [[ "$HAS_COMPOSER" == true ]]; then
                    echo "  - Composer: ✅ ${COMPOSER_VERSION:-installed}"
                else
                    echo "  - Composer: ⬚ belum terinstall"
                fi
                echo ""
                echo "  💡 Untuk install runtime via mise, jalankan:"
                echo "      mise use -g php@${MISE_PHP_VERSION} node@${MISE_NODE_VERSION} python@${MISE_PYTHON_VERSION} go@latest"
                echo ""
                echo "  💡 Untuk install package managers:"
                echo "      # npm (sudah ada di Node.js):"
                echo "      npm install -g pnpm"
                echo "      # atau Bun:"
                echo "      curl -fsSL https://bun.sh/install | bash"
                echo ""
                echo "  💡 Untuk install Composer:"
                echo "      curl -sS https://getcomposer.org/installer | php"
                echo "      sudo mv composer.phar /usr/local/bin/composer"
                echo ""
            fi
            echo ""
            echo -n "  Press Enter to continue..."
            read -r || true
            ;;
        E|e)
            php_ext_menu
            ;;
        V|v)
            # Verify system
            safe_clear
            print_header "System Verification"
            echo ""
            echo "  Halaman ini menampilkan status lengkap sistem Anda:"
            echo "  - OS & Package Manager"
            echo "  - Prerequisites (Docker, mise, .env)"
            echo "  - Development Runtimes (PHP, Node.js, Python)"
            echo ""
            print_detection_summary
            echo ""
            echo -n "  Press Enter to continue..."
            read -r || true
            ;;
        Q|q)
            return 2
            ;;
        *)
            return 3
            ;;
    esac
    
    return 0
}

# Main menu loop
run_menu() {
    local choice=""
    local action=""
    local result=0
    
    # Ensure we're in the right directory
    cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null || true
    
    # Verify we have an interactive terminal
    if ! is_interactive; then
        print_error "This CLI requires an interactive terminal (TTY)."
        echo "Please run it directly in a terminal, not via pipe or script."
        return 1
    fi
    
    while true; do
        show_main_menu
        # Read with timeout so it never hangs forever
        if ! read -r choice; then
            echo ""
            echo -e "  ${GREEN}Goodbye!${NC}"
            echo ""
            return 0
        fi
        
        # Check if choice is a service number
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#SERVICE_ORDER[@]})); then
            local service="${SERVICE_ORDER[$((choice - 1))]}"
            
            while true; do
                show_service_menu "$service"
                if ! read -r action; then
                    return 0
                fi
                
                # Validate action range
                local max_action=7
                local web_url="${SERVICE_WEB_URL[$service]:-}"
                [[ -n "$web_url" ]] && max_action=8
                
                if [[ "$action" =~ ^[0-9]+$ ]] && ((action >= 0 && action <= max_action)); then
                    if ! handle_service_action "$service" "$action"; then
                        break
                    fi
                    echo -n "  Press Enter to continue..."
                    if ! read -r; then
                        return 0
                    fi
                else
                    print_error "Invalid choice. Use [0-${max_action}] for actions, [0] for back"
                    sleep 1
                fi
            done
        elif [[ "$choice" =~ ^[UuAaSsGgIiEeVvQq0]$ ]]; then
            handle_main_action "$choice"
            result=$?
            
            if [[ $result -eq 2 ]]; then
                safe_clear
                echo ""
                echo -e "  ${GREEN}Goodbye!${NC}"
                echo ""
                return 0
            elif [[ $result -eq 3 ]]; then
                print_error "Invalid choice. Use numbers 1-${#SERVICE_ORDER[@]} or actions U/A/S/G/I/V/Q"
            fi
            sleep 1
        else
            print_error "Invalid choice. Use [1-${#SERVICE_ORDER[@]}] for services, [0] for back, or [U/A/S/G/I/V/Q] for actions"
            sleep 2
        fi
    done
}
