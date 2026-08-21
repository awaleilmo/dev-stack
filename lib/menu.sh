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

# Show main menu
show_main_menu() {
    clear
    print_header "Dev Stack Manager v1.0"
    echo ""
    
    # Prerequisites section
    echo -e "  ${CYAN}Prerequisites${NC}"
    if [[ "$HAS_DOCKER" == true ]]; then
        echo -e "  ${VB} ${GREEN}✅${NC} Docker Engine: ${DOCKER_VERSION}${NC}"
    else
        echo -e "  ${VB} ${RED}❌${NC} Docker Engine: not installed${NC}  [G] generate guide"
    fi
    if [[ "$HAS_MISE" == true ]]; then
        echo -e "  ${VB} ${GREEN}✅${NC} mise: ${MISE_VERSION}${NC}"
    else
        echo -e "  ${VB} ${RED}❌${NC} mise: not installed${NC}  [G] generate guide"
    fi
    echo ""
    
    # Services section
    echo -e "  ${CYAN}Services${NC}"
    printf "  ${VB} %-4s %-12s %-15s %-8s\n" "#" "SERVICE" "STATUS" "PORT"
    printf "  ${VB} %-4s %-12s %-15s %-8s\n" "----" "----------" "--------------" "-----"
    
    local num=1
    for service in "${SERVICE_ORDER[@]}"; do
        local status
        status=$(get_service_status "$service")
        local port="${SERVICE_PORT[$service]}"
        local icon
        icon=$(status_icon "$status")
        
        printf "  ${VB} %-4s ${icon} %-10s %-15s %-8s\n" \
            "$num" \
            "$service" \
            "$(status_text "$status")" \
            "$port"
        num=$((num + 1))
    done
    echo "  ${VB}$(printf '%0.s ' $(seq 1 48))${VB}"
    echo ""
    
    # Actions section
    echo -e "  ${CYAN}Actions${NC}"
    echo -e "  ${VB} [U] Update All Images${NC}      - Pull image terbaru dari registry"
    echo -e "  ${VB} [A] Start All Services${NC}     - Jalankan semua service yang sudah terinstall"
    echo -e "  ${VB} [S] Stop All Services${NC}      - Hentikan semua container yang berjalan"
    echo -e "  ${VB} [G] Generate Guides${NC}        - Buat panduan instalasi (jika ada yang missing)"
    echo -e "  ${VB} [I] Install Mise Runtime${NC}  - Cek & buat panduan install mise + PHP/Node/Python"
    echo -e "  ${VB} [V] Verify System${NC}          - Tampilkan status lengkap sistem & runtime"
    echo ""
    echo -e "  ${BOLD}Select service [1-8] or action [0-9/U/A/S/G/I/V/Q]:${NC} "
}

# Show service submenu
show_service_menu() {
    local service="$1"
    local status
    status=$(get_service_status "$service")
    
    clear
    print_header "Service: $service ($status)"
    
    echo ""
    echo -e "  ${CYAN}Details${NC}"
    echo "  Image: ${SERVICE_IMAGE[$service]}"
    echo "  Container: ${SERVICE_CONTAINER[$service]}"
    echo "  Port: ${SERVICE_PORT[$service]}"
    echo ""
    
    echo -e "  ${CYAN}Actions${NC}"
    
    if [[ "$status" == "not-installed" ]]; then
        echo "  [I] Install         - Download image & buat container baru"
        echo "  [D] Download Image  - Download image saja (tanpa container)"
    else
        echo "  [S] Start           - Jalankan container"
        echo "  [T] Stop            - Hentikan container"
        echo "  [R] Restart         - Stop lalu start ulang"
        echo "  [L] Logs            - Lihat log container (-f)"
        echo "  [H] Shell           - Masuk ke container bash"
        echo "  [U] Update Image    - Pull image baru & restart container"
        echo "  [D] Remove          - Hapus container & data (destructive)"
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
        S|s) start_service "$service" ;;
        T|t) stop_service "$service" ;;
        R|r) restart_service "$service" ;;
        L|l) show_logs "$service" ;;
        H|h) enter_shell "$service" ;;
        U|u) update_service "$service" ;;
        D|d) remove_service "$service" ;;
        I|i) install_service "$service" ;;
        B|b|0) return 1 ;;
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
            # Generate guides
            local guide_dir
            guide_dir="$(pwd)"
            local docker_guide="$guide_dir/docker-installation.md"
            local devenv_guide="$guide_dir/development-environment-installation.md"
            local guide_count=0
            
            clear
            print_header "Generate Installation Guides"
            echo ""
            echo "  Guides adalah file Markdown yang berisi instruksi instalasi"
            echo "  untuk dependency yang belum tersedia di sistem Anda."
            echo ""
            echo "  ┌─────────────────────────────────────────────────────────┐"
            echo "  │ Docker Installation Guide                               │"
            echo "  │   File: docker-installation.md                          │"
            echo "  │   Konten: Panduan install Docker di Linux               │"
            echo "  │   Status: $([ "$HAS_DOCKER" == true ] && echo '✅ Sudah terinstall' || echo '❌ Belum terinstall')"
            echo "  └─────────────────────────────────────────────────────────┘"
            echo ""
            echo "  ┌─────────────────────────────────────────────────────────┐"
            echo "  │ Development Environment Guide                           │"
            echo "  │   File: development-environment-installation.md         │"
            echo "  │   Konten: Panduan install mise + PHP/Node/Python        │"
            echo "  │   Status: $([ "$HAS_MISE" == true ] && echo '✅ Sudah terinstall' || echo '❌ Belum terinstall')"
            echo "  └─────────────────────────────────────────────────────────┘"
            echo ""
            
            if [[ "$HAS_DOCKER" == false ]]; then
                local df
                df=$(generate_docker_guide "$docker_guide")
                guide_count=$((guide_count + 1))
                echo "  ✅ Guide dibuat: $df"
            else
                echo "  ℹ️  Docker sudah terinstall - tidak perlu guide"
            fi
            
            if [[ "$HAS_MISE" == false ]]; then
                local gf
                gf=$(generate_devenv_guide "$devenv_guide")
                guide_count=$((guide_count + 1))
                echo "  ✅ Guide dibuat: $gf"
            else
                echo "  ℹ️  mise sudah terinstall - tidak perlu guide"
            fi
            
            echo ""
            if [[ $guide_count -eq 0 ]]; then
                echo "  Semua dependency sudah terinstall. Tidak ada guide yang perlu dibuat."
            else
                echo "  📁 Lokasi guide: $(pwd)/"
                echo "  💡 Buka file tersebut dengan editor: nano docker-installation.md"
            fi
            echo ""
            read -rp "  Press Enter to continue..." 
            ;;
        I|i)
            clear
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
                echo "  Status Tools saat ini:"
                if [[ "$HAS_COMPOSER" == true ]]; then
                    echo "  - Composer: ✅ ${COMPOSER_VERSION:-installed}"
                else
                    echo "  - Composer: ⬚ belum terinstall"
                fi
                echo ""
                echo "  💡 Untuk install runtime via mise, jalankan:"
                echo "      mise use -g php@${MISE_PHP_VERSION} node@${MISE_NODE_VERSION} python@${MISE_PYTHON_VERSION}"
                echo ""
                echo "  💡 Untuk install Composer, jalankan:"
                echo "      curl -sS https://getcomposer.org/installer | php"
                echo "      sudo mv composer.phar /usr/local/bin/composer"
                echo ""
            fi
            echo ""
            read -rp "  Press Enter to continue..." 
            ;;
        V|v)
            # Verify system
            clear
            print_header "System Verification"
            echo ""
            echo "  Halaman ini menampilkan status lengkap sistem Anda:"
            echo "  - OS & Package Manager"
            echo "  - Prerequisites (Docker, mise)"
            echo "  - Development Runtimes (PHP, Node.js, Python)"
            echo ""
            print_detection_summary
            echo ""
            read -rp "  Press Enter to continue..." 
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
    
    while true; do
        show_main_menu
        # Handle EOF (non-interactive mode)
        if ! read -rp "" choice; then
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
                if ! read -rp "" action; then
                    return 0
                fi
                
                if ! handle_service_action "$service" "$action"; then
                    break
                fi
                echo -n "  Press Enter to continue..."
                if ! read -r; then
                    return 0
                fi
            done
        elif [[ "$choice" =~ ^[UuAaSsGgIiVvQq0]$ ]]; then
            handle_main_action "$choice"
            result=$?
            
            if [[ $result -eq 2 ]]; then
                clear
                echo ""
                echo -e "  ${GREEN}Goodbye!${NC}"
                echo ""
                return 0
            elif [[ $result -eq 3 ]]; then
                print_error "Invalid choice. Use numbers 1-${#SERVICE_ORDER[@]} or actions U/A/S/G/I/V/Q"
            fi
            sleep 1
        else
            print_error "Invalid choice. Use [1-8] for services, [0] for back, or [U/A/S/G/I/V/Q] for actions"
            sleep 2
        fi
    done
}
