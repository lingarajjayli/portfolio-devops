#!/bin/bash
#
# Log Rotation Script
# A realistic log rotation script demonstrating:
# - Size-based rotation
# - Compression of old logs
# - Signal handling for running processes
# - Comprehensive cleanup policies
#

set -euo pipefail

# Configuration
LOG_DIR="${LOG_DIR:-/var/log/app}"
COMPRESS_CMD="${COMPRESS_CMD:-gzip}"
COMPRESS_EXT="${COMPRESS_EXT:-.gz}"
MAX_LOG_SIZE="${MAX_LOG_SIZE:-100M}"
MAX_LOG_AGE="${MAX_LOG_AGE:-30}"
KEEP_COUNT="${KEEP_COUNT:-7}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}"
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }

# Function to get file size in bytes
get_file_size() {
    local file=$1
    stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"
}

# Function to convert size to bytes
size_to_bytes() {
    local size=$1
    local num=${size%[KMGTP]M}
    local unit=${size##*[0-9]}
    case $unit in
        K) echo $((num * 1024)) ;;
        M) echo $((num * 1024 * 1024)) ;;
        G) echo $((num * 1024 * 1024 * 1024)) ;;
        *) echo "$num" ;;
    esac
}

# Function to check if process is using log file
check_process_using_log() {
    local log_file=$1
    if command -v lsof &> /dev/null; then
        lsof "$log_file" 2>/dev/null | grep -q "OPEN" && return 0 || return 1
    elif command -v fuser &> /dev/null; then
        fuser "$log_file" 2>/dev/null && return 0 || return 1
    else
        log_warn "No process check tools available"
        return 1
    fi
}

# Function to rotate log file
rotate_log() {
    local log_file=$1
    local base_name=$(basename "$log_file")
    local rotated_file="${log_file}${COMPRESS_EXT}"

    log_info "Rotating: $log_file"

    # Check file size
    local file_size=$(get_file_size "$log_file")
    local max_size_bytes=$(size_to_bytes "$MAX_LOG_SIZE")

    if [ "$file_size" -le "$max_size_bytes" ]; then
        log_info "Skipping rotation (size: ${file_size}B <= ${MAX_LOG_SIZE})"
        return 0
    fi

    # Check if process is using the log file
    if check_process_using_log "$log_file"; then
        log_warn "Process using $log_file, sending HUP signal"
        # Try to find the process and send HUP
        ps aux | grep -v grep | grep "$base_name" | awk '{print $2}' | head -1 | xargs kill -HUP 2>/dev/null || {
            log_warn "Could not send HUP signal"
        }
        sleep 2
    fi

    # Move and compress the log file
    mv "$log_file" "$rotated_file"
    log_info "Rotated and compressed: $rotated_file"

    # Create new empty log file with proper permissions
    touch "$log_file"
    chmod 640 "$log_file"
    chown root:adm "$log_file" 2>/dev/null || true

    log_info "Created new log file: $log_file"
}

# Function to clean old compressed logs
clean_old_logs() {
    local pattern=$1
    log_info "Cleaning logs older than ${MAX_LOG_AGE} days matching: $pattern"

    local count=0
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            log_info "Removing old log: $file"
            rm -f "$file"
            count=$((count + 1))
        fi
    done < <(find "$LOG_DIR" -name "$pattern" -type f -mtime +"$MAX_LOG_AGE" -print0 2>/dev/null)

    log_info "Removed $count old log files"
    echo "$count"
}

# Function to manage compressed log files
manage_compressed_logs() {
    local pattern=${1:-*.gz}

    log_info "Managing compressed logs: $pattern"

    local compressed_files=()
    while IFS= read -r -d '' file; do
        compressed_files+=("$file")
    done < <(find "$LOG_DIR" -name "$pattern" -type f -print0 2>/dev/null)

    if [ ${#compressed_files[@]} -eq 0 ]; then
        log_info "No compressed log files found"
        return 0
    fi

    # Remove oldest compressed files beyond KEEP_COUNT
    local total_count=${#compressed_files[@]}
    local to_remove=$((total_count - KEEP_COUNT))

    if [ "$to_remove" -gt 0 ]; then
        log_info "Removing oldest $to_remove compressed logs"
        for ((i=0; i<to_remove; i++)); do
            rm -f "${compressed_files[$i]}"
            log_info "Removed: ${compressed_files[$i]}"
        done
    fi

    log_info "Keeping latest $KEEP_COUNT compressed logs"
}

# Function to verify log rotation
verify_logs() {
    log_info "Verifying log rotation"

    local errors=0
    local total_size=0

    for log_file in "$LOG_DIR"/*.log 2>/dev/null; do
        if [ -f "$log_file" ]; then
            local size=$(get_file_size "$log_file")
            total_size=$((total_size + size))
            log_info "Log file: $(basename "$log_file") size=${size}B"
        fi
    done

    for gz_file in "$LOG_DIR"/*.gz 2>/dev/null; do
        if [ -f "$gz_file" ]; then
            local size=$(get_file_size "$gz_file")
            total_size=$((total_size + size))
            log_info "Compressed: $(basename "$gz_file") size=${size}B"
        fi
    done

    # Verify integrity of compressed files
    for gz_file in "$LOG_DIR"/*.gz 2>/dev/null; do
        if [ -f "$gz_file" ]; then
            if ! gzip -t "$gz_file" 2>/dev/null; then
                log_error "Corrupted compressed file: $gz_file"
                errors=$((errors + 1))
            fi
        fi
    done

    if [ $errors -eq 0 ]; then
        log_success "All log files are valid"
    else
        log_error "$errors log file(s) are corrupted"
    fi

    log_info "Total log storage: $((total_size / 1024))KB"
    return $errors
}

# Function to display log statistics
log_stats() {
    log_info "Log Statistics"

    echo ""
    echo "## Log Files"
    echo ""

    for log_file in "$LOG_DIR"/*.log 2>/dev/null; do
        if [ -f "$log_file" ]; then
            local size=$(get_file_size "$log_file")
            local count=$(wc -l < "$log_file" 2>/dev/null || echo "0")
            printf "%-30s %10s lines %10sB\n" "$(basename "$log_file")" "$count" "$size"
        fi
    done

    echo ""
    echo "## Compressed Logs"
    echo ""

    for gz_file in "$LOG_DIR"/*.gz 2>/dev/null; do
        if [ -f "$gz_file" ]; then
            local size=$(get_file_size "$gz_file")
            local original=$(gzip -l "$gz_file" 2>/dev/null | tail -1 | awk '{print $2}')
            local ratio=$((100 * (1 - size / original)))
            printf "%-30s %10sB (%s%% saved)\n" "$(basename "$gz_file")" "$size" "$ratio"
        fi
    done

    echo ""
    echo "## Summary"
    echo ""
    echo "- Total log files: $(find "$LOG_DIR" -name "*.log" 2>/dev/null | wc -l)"
    echo "- Total compressed files: $(find "$LOG_DIR" -name "*.gz" 2>/dev/null | wc -l)"
    echo "- Oldest log: $(find "$LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2 || echo "N/A")"
    echo "- Newest log: $(find "$LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2 || echo "N/A")"
}

# Function to configure logrotate
configure_logrotate() {
    local config_file="${1:-/etc/logrotate.d/app}"

    log_info "Configuring logrotate: $config_file"

    cat > "$config_file" << 'EOF'
/var/log/app/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        # Send HUP signal to running processes
        for pid in $(pgrep -f 'app|application'); do
            kill -HUP "$pid" 2>/dev/null || true
        done
    endscript
}
EOF

    log_success "Logrotate configuration created"
    cat "$config_file"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    rotate    Rotate oversized log files (default)
    clean     Remove old logs older than MAX_LOG_AGE days
    verify    Verify log files integrity
    stats     Display log statistics
    config    Generate logrotate configuration
    help      Show this help message

Environment Variables:
    LOG_DIR               Log directory (default: /var/log/app)
    MAX_LOG_SIZE          Max log size before rotation (default: 100M)
    MAX_LOG_AGE           Age in days for cleanup (default: 30)
    KEEP_COUNT            Number of compressed logs to keep (default: 7)

Examples:
    $0 rotate              # Rotate oversized logs
    $0 clean               # Clean old logs
    $0 verify              # Verify log integrity
    $0 stats               # Show log statistics
    $0 config              # Generate logrotate config

EOF
}

# Main execution
main() {
    # Parse arguments
    local command="${1:-rotate}"

    case $command in
        rotate)
            # Rotate all logs that exceed MAX_LOG_SIZE
            for log_file in "$LOG_DIR"/*.log 2>/dev/null; do
                if [ -f "$log_file" ]; then
                    rotate_log "$log_file"
                fi
            done
            ;;
        clean)
            # Clean old logs
            clean_old_logs "*.gz"
            clean_old_logs "*.log"
            ;;
        verify)
            verify_logs
            ;;
        stats)
            log_stats
            ;;
        config)
            configure_logrotate "$1"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
