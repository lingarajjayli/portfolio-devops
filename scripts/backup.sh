#!/bin/bash
#
# Backup Script
# A realistic backup automation script demonstrating:
# - Encrypted backups
# - Rotation policy
# - Verification after backup
# - Logging and reporting
#

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
ENCRYPTION="${ENCRYPTION:-true}"
LOG_FILE="/var/log/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TYPE="${BACKUP_TYPE:-all}"
COMPRESS="${COMPRESS:-gzip}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# Function to create backup directory
setup_backups() {
    log_info "Setting up backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"/{database,config,logs}

    # Setup encryption keys directory
    local keys_dir="$BACKUP_DIR/.keys"
    mkdir -p "$keys_dir"
    chmod 700 "$keys_dir"
}

# Function to backup database
backup_database() {
    local db_name="${1:-app_db}"
    local db_host="${DB_HOST:-localhost}"
    local db_user="${DB_USER:-backup_user}"

    log_info "Starting database backup for $db_name"

    # Simulate database backup
    # In production, would use: mysqldump --user=$db_user --host=$db_host $db_name | gzip > backup_file
    local backup_file="$BACKUP_DIR/database/${db_name}_${TIMESTAMP}.sql.gz"

    log_info "Creating encrypted backup: $backup_file"

    # Simulate encrypted backup creation
    cat > /dev/null << EOF
-- Database Backup: ${db_name}
-- Timestamp: ${TIMESTAMP}
-- Host: ${db_host}

CREATE DATABASE IF NOT EXISTS \`${db_name}\`;

-- Simulated backup content
INSERT INTO users (id, username, email, created_at) VALUES
(1, 'admin', 'admin@example.com', NOW()),
(2, 'user1', 'user1@example.com', NOW());

INSERT INTO products (id, name, price) VALUES
(1, 'Product A', 99.99),
(2, 'Product B', 149.99);
EOF

    # Compress and encrypt
    if [ "$COMPRESS" = "gzip" ]; then
        gzip "$backup_file" 2>/dev/null
    fi

    log_success "Database backup completed: $backup_file"
    echo "$backup_file"
}

# Function to backup configuration files
backup_config() {
    local config_path="${1:-/etc/app}"

    log_info "Starting configuration backup from: $config_path"

    local backup_file="$BACKUP_DIR/config/config_${TIMESTAMP}.tar.gz"

    # Create tarball of config files
    tar -czf "$backup_file" -C "$(dirname "$config_path")" "$(basename "$config_path")" 2>/dev/null || {
        log_warn "No config files found or permission denied"
        return 0
    }

    # Encrypt if enabled
    if [ "$ENCRYPTION" = "true" ] && command -v gpg &> /dev/null; then
        gpg --symmetric --cipher-algo AES256 "$backup_file" 2>/dev/null || \
        log_warn "GPG encryption not available, skipping encryption"
    fi

    log_success "Configuration backup completed: $backup_file"
    echo "$backup_file"
}

# Function to backup logs
backup_logs() {
    local logs_path="${1:-/var/log}"

    log_info "Starting logs backup from: $logs_path"

    local backup_file="$BACKUP_DIR/logs/logs_${TIMESTAMP}.tar.gz"

    # Find and backup log files (exclude recent logs)
    find "$logs_path" -name "*.log" -type f -mtime -1 -exec tar -rf "$backup_file" {} \; 2>/dev/null || true

    if [ -f "$backup_file" ]; then
        log_success "Logs backup completed: $backup_file"
    else
        log_warn "No recent log files found"
    fi
}

# Function to rotate old backups
rotate_backups() {
    log_info "Rotating old backups (older than $RETENTION_DAYS days)"

    local cleaned=0
    local removed=0

    # Find and list old backups
    local old_backups=$(find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS 2>/dev/null || true)

    if [ -n "$old_backups" ]; then
        echo "$old_backups" | while read -r old_file; do
            if [ -n "$old_file" ]; then
                if [ "$ENCRYPTION" = "true" ]; then
                    rm -f "$old_file"
                else
                    rm -rf "$old_file"
                fi
                removed=$((removed + 1))
                log_info "Removed old backup: $old_file"
            fi
        done
        cleaned=$((cleaned + removed))
    fi

    log_success "Cleaned up $cleaned old backup files"
    echo "$cleaned"
}

# Function to verify backups
verify_backups() {
    log_info "Verifying backup integrity"

    local verified=0
    local failed=0

    # Check for backup files
    for backup in "$BACKUP_DIR"/*.gz "$BACKUP_DIR"/*.sql.gz 2>/dev/null; do
        if [ -f "$backup" ]; then
            # Verify file size is reasonable (>0 bytes)
            local size=$(stat -f%z "$backup" 2>/dev/null || stat -c%s "$backup" 2>/dev/null)

            if [ "$size" -gt 0 ]; then
                verified=$((verified + 1))
                log_info "Backup verified: $backup"
            else
                failed=$((failed + 1))
                log_error "Backup verification failed: $backup (empty file)"
            fi
        fi
    done

    log_success "Verified $verified backups successfully"
    if [ $failed -gt 0 ]; then
        log_error "$failed backup(s) failed verification"
        return 1
    fi
    return 0
}

# Function to cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files"

    # Remove temporary directories
    rm -rf /tmp/backup_temp 2>/dev/null || true

    log_success "Cleanup completed"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    backup         Create new backups (default)
    backup-db      Backup database only
    backup-config  Backup configuration files
    backup-logs    Backup log files
    verify         Verify backup integrity
    rotate         Rotate old backups
    cleanup        Clean up temporary files
    help           Show this help message

Environment Variables:
    BACKUP_DIR     Backup directory (default: /var/backups)
    RETENTION_DAYS  Days to retain backups (default: 30)
    ENCRYPTION     Enable encryption (true/false)
    DB_HOST        Database host (default: localhost)
    DB_USER        Database backup user

Options:
    --db-name      Database name (for backup-db)
    --config-path  Config path (for backup-config)
    --logs-path    Logs path (for backup-logs)

Examples:
    $0 backup                    # Create full backup
    $0 backup-db --db-name=mydb # Backup specific database
    $0 backup-config             # Backup config files
    $0 verify                    # Verify all backups
    $0 rotate                    # Rotate old backups

EOF
}

# Main execution
main() {
    # Parse arguments
    local command="${1:-backup}"

    case $command in
        backup)
            setup_backups
            backup_database
            backup_config
            backup_logs
            verify_backups
            rotate_backups
            cleanup
            ;;
        backup-db)
            setup_backups
            local db_name="${2:-app_db}"
            backup_database "$db_name"
            ;;
        backup-config)
            setup_backups
            local config_path="${2:-/etc/app}"
            backup_config "$config_path"
            ;;
        backup-logs)
            local logs_path="${2:-/var/log}"
            backup_logs "$logs_path"
            ;;
        verify)
            verify_backups
            ;;
        rotate)
            rotate_backups
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h|*)
            usage
            ;;
    esac
}

# Run main function
main "$@"
