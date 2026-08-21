#!/usr/bin/env bash
# lib/services.sh - Service registry and lifecycle management

set -euo pipefail

# Source dependencies (detect.sh is already sourced, guarded by _DETECT_SH_SOURCED)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ui.sh"

# Service registry
declare -A SERVICE_CONTAINER=(
    [mysql]=mysql8-dev
    [postgres]=postgres15-dev
    [mongodb]=mongodb-dev
    [redis]=redis-dev
    [adminer]=adminer-dev
    [mailhog]=mailhog-dev
    [minio]=minio-dev
    [portainer]=portainer-dev
)

declare -A SERVICE_IMAGE=(
    [mysql]=mysql:8.0
    [postgres]=postgres:15
    [mongodb]=mongo:7.0
    [redis]=redis:7-alpine
    [adminer]=adminer:latest
    [mailhog]=mailhog/mailhog:latest
    [minio]=minio/minio:latest
    [portainer]=portainer/portainer-ce:latest
)

declare -A SERVICE_PORT=(
    [mysql]=3306
    [postgres]=5432
    [mongodb]=27017
    [redis]=6379
    [adminer]=8081
    [mailhog]=8025
    [minio]=9001
    [portainer]=9000
)

declare -A SERVICE_DIR=(
    [mysql]=services/mysql
    [postgres]=services/postgres
    [mongodb]=services/mongodb
    [redis]=services/redis
    [adminer]=services/adminer
    [mailhog]=services/mailhog
    [minio]=services/minio
    [portainer]=services/portainer
)

declare -A SERVICE_CATEGORY=(
    [mysql]=database
    [postgres]=database
    [mongodb]=database
    [redis]=cache
    [adminer]=tool
    [mailhog]=tool
    [minio]=storage
    [portainer]=tool
)

declare -A SERVICE_LABEL=(
    [mysql]=MySQL
    [postgres]=PostgreSQL
    [mongodb]=MongoDB
    [redis]=Redis
    [adminer]=Adminer
    [mailhog]=MailHog
    [minio]=MinIO
    [portainer]=Portainer
)

# Service order for display
SERVICE_ORDER=(mysql postgres mongodb redis adminer mailhog minio portainer)

# Get current working directory
get_devstack_dir() {
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    dirname "$script_path"
}

# Ensure dev-network exists
ensure_network() {
    if ! docker_safe network inspect dev-network &>/dev/null 2>&1; then
        docker_safe network create dev-network >/dev/null 2>&1 || true
        print_success "Network 'dev-network' created"
    else
        print_info "Network 'dev-network' already exists"
    fi
}

# Check service status
get_service_status() {
    local service="$1"
    local container="${SERVICE_CONTAINER[$service]}"
    
    if docker_safe ps -q -f "name=^${container}$" &>/dev/null 2>&1; then
        echo "running"
    elif docker_safe ps -aq -f "name=^${container}$" &>/dev/null 2>&1; then
        echo "stopped"
    else
        echo "not-installed"
    fi
}

# Check if image has update available
check_image_update() {
    local service="$1"
    local image="${SERVICE_IMAGE[$service]}"
    
    # Get local image digest
    local local_digest=""
    local_digest=$(docker image inspect "$image" --format '{{.Id}}' 2>/dev/null || echo "")
    
    # Pull and check
    local pull_output
    pull_output=$(docker pull "$image" 2>&1) || true
    
    if echo "$pull_output" | grep -q "Image is up to date"; then
        echo "up-to-date"
    else
        echo "update-available"
    fi
}

# Get container runtime (how long it's been running)
get_container_runtime() {
    local container="$1"
    docker_safe ps -f "name=^${container}$" --format '{{.RunningFor}}' 2>/dev/null || echo ""
}

# Start service
start_service() {
    local service="$1"
    local dir="${SERVICE_DIR[$service]}"
    local container="${SERVICE_CONTAINER[$service]}"
    
    ensure_network
    docker compose -f "$dir/docker-compose.yml" up -d
    print_success "$service started successfully (container: $container)"
}

# Stop service
stop_service() {
    local service="$1"
    local dir="${SERVICE_DIR[$service]}"
    local container="${SERVICE_CONTAINER[$service]}"
    
    docker compose -f "$dir/docker-compose.yml" down
    print_success "$service stopped (container: $container)"
}

# Restart service
restart_service() {
    local service="$1"
    stop_service "$service"
    sleep 2
    start_service "$service"
}

# Remove service (with data)
remove_service() {
    local service="$1"
    local dir="${SERVICE_DIR[$service]}"
    local container="${SERVICE_CONTAINER[$service]}"
    local volume="${service}_data"
    
    echo ""
    print_warning "This will remove the container and DELETE volume '$volume'."
    echo "ALL DATA WILL BE LOST!"
    echo ""
    
    local confirm=""
    read -rp "Type 'REMOVE' to confirm: " confirm
    
    if [[ "$confirm" == "REMOVE" ]]; then
        docker compose -f "$dir/docker-compose.yml" down -v
        print_success "$service removed (container and volume deleted)"
    else
        print_info "Operation cancelled"
    fi
}

# Show service logs
show_logs() {
    local service="$1"
    local dir="${SERVICE_DIR[$service]}"
    
    docker compose -f "$dir/docker-compose.yml" logs -f
}

# Enter service shell
enter_shell() {
    local service="$1"
    local container="${SERVICE_CONTAINER[$service]}"
    
    docker exec -it "$container" bash
}

# Update service image
update_service() {
    local service="$1"
    local dir="${SERVICE_DIR[$service]}"
    local image="${SERVICE_IMAGE[$service]}"
    
    echo "Pulling $image..."
    docker pull "$image"
    
    # Check if update was actually downloaded
    if docker compose -f "$dir/docker-compose.yml" up -d --force-recreate 2>/dev/null; then
        print_success "$service updated and restarted"
    else
        print_warning "$service image updated but container restart failed"
    fi
}

# Install service (pull image only)
install_service() {
    local service="$1"
    local image="${SERVICE_IMAGE[$service]}"
    
    echo "Downloading $image..."
    docker pull "$image"
    print_success "$service image downloaded"
}

# List all services with status
list_services() {
    echo ""
    printf "  %-4s %-12s %-15s %-8s %-8s\n" "#" "SERVICE" "STATUS" "IMAGE" "PORT"
    printf "  %-4s %-12s %-15s %-8s %-8s\n" "---" "----------" "--------------" "-------" "-----"
    
    for service in "${SERVICE_ORDER[@]}"; do
        local status
        status=$(get_service_status "$service")
        local image="${SERVICE_IMAGE[$service]}"
        local port="${SERVICE_PORT[$service]}"
        local runtime=""
        
        if [[ "$status" == "running" ]]; then
            runtime=$(get_container_runtime "${SERVICE_CONTAINER[$service]}")
            status="$status ${runtime}"
        fi
        
        local icon
        icon=$(status_icon "$status")
        
        printf "  %-4s ${icon} %-10s %-15s %-8s %-8s\n" \
            "$((${#SERVICE_ORDER[@]} - ${#SERVICE_ORDER[@]} + ${SERVICE_ORDER[@]/#service/0} + 1))" \
            "$service" \
            "$(status_text "$status")" \
            "$image" \
            "$port"
    done
    echo ""
}
