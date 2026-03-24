#!/bin/bash
#
# Database Maintenance Script
# A realistic database maintenance script demonstrating:
# - Index optimization
# - Table optimization
# - Analytics cleanup
# - Vacuum operations
# - Health monitoring
#

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-myapp}"
DB_USER="${DB_USER:-mysql}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/database}"
LOG_FILE="/var/log/db-maintenance.log"
MAX_INDEX_FRAGMENTS="${MAX_INDEX_FRAGMENTS:-30}"
MAX_TABLE_FRAGMENTS="${MAX_TABLE_FRAGMENTS:-20}"

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
    mkdir -p "$(dirname "$LOG_FILE")"
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# Function to check database connectivity
check_connection() {
    log_info "Checking database connection to ${DB_HOST}:${DB_PORT}/${DB_NAME}"

    # MySQL connection check
    if command -v mysql &> /dev/null; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>/dev/null && {
            log_success "Database connection successful"
            return 0
        } || {
            log_error "Cannot connect to database"
            return 1
        }
    else
        log_warn "MySQL client not installed, skipping connection check"
        return 0
    fi
}

# Function to backup database before maintenance
backup_before_maintenance() {
    local backup_file="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz"

    log_info "Creating pre-maintenance backup: $backup_file"

    # Create backup
    if command -v mysqldump &> /dev/null; then
        mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" --single-transaction \
            "$DB_NAME" | gzip > "$backup_file" && {
            log_success "Backup created: $backup_file"
            chmod 600 "$backup_file"
        } || {
            log_error "Failed to create backup"
            return 1
        }
    else
        log_warn "mysqldump not available, skipping backup"
    fi

    echo "$backup_file"
}

# Function to optimize table
optimize_table() {
    local table_name=$1
    log_info "Optimizing table: $table_name"

    if command -v mysql &> /dev/null; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "OPTIMIZE TABLE $table_name;" 2>/dev/null && {
            log_success "Optimized: $table_name"
        } || {
            log_warn "Failed to optimize: $table_name"
        }
    fi
}

# Function to analyze table
analyze_table() {
    local table_name=$1
    log_info "Analyzing table: $table_name"

    if command -v mysql &> /dev/null; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "ANALYZE TABLE $table_name;" 2>/dev/null && {
            log_success "Analyzed: $table_name"
        } || {
            log_warn "Failed to analyze: $table_name"
        }
    fi
}

# Function to rebuild index
rebuild_index() {
    local table_name=$1
    local index_name=$2

    log_info "Rebuilding index '$index_name' on table '$table_name'"

    if command -v mysql &> /dev/null; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "ALTER TABLE $table_name DROP INDEX IF EXISTS $index_name; ALTER TABLE $table_name ADD INDEX $index_name (...);" \
            2>/dev/null || {
            log_warn "Could not rebuild index on $table_name.$index_name"
        }
    fi
}

# Function to fix table structure
fix_table_structure() {
    log_info "Fixing table structure"

    if command -v mysql &> /dev/null; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "
                CHECK TABLE information_schema.columns;
                CHECK TABLE information_schema.tables;
            " 2>/dev/null && {
            log_success "Table structure check passed"
        } || {
            log_warn "Table structure check failed"
        }
    fi
}

# Function to optimize indexes
optimize_indexes() {
    log_info "Optimizing indexes"

    if command -v mysql &> /dev/null; then
        # Get tables with high index fragmentation
        local slow_query="
            SELECT
                table_schema,
                table_name,
                index_name,
                AVG(stats[1]) as read_requests,
                SUM(stats[2]) as writes,
                (SUM(stats[2]) + AVG(stats[1])) as total_requests,
                (SUM(stats[3]) + AVG(stats[4])) as deleted,
                (SUM(stats[3]) + AVG(stats[4])) / (SUM(stats[2]) + AVG(stats[1])) as deleted_pct,
                ROUND(SUM(stats[5]) + AVG(stats[6]), 0) as index_cardinality,
                (SUM(stats[5]) + AVG(stats[6])) / (ROUND(SUM(stats[2]) + AVG(stats[1]), 0) + 1) * 100 as fragmentation_pct
            FROM information_schema.table_statistics
            WHERE table_schema = '${DB_NAME}'
            ORDER BY fragmentation_pct DESC
            LIMIT 10;
        "

        # Get fragmented indexes
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "
                SELECT
                    table_name,
                    index_name,
                    deleted + avg_row_len as fragmented
                FROM information_schema.table_statistics
                WHERE table_schema = '${DB_NAME}'
                AND (deleted + avg_row_len) / (written + updated + avg_row_len) * 100 > ${MAX_INDEX_FRAGMENTS}
                ORDER BY fragmented DESC;
            " 2>/dev/null | while read -r line; do
                if [ -n "$line" ]; then
                    # Extract table and index names
                    table=$(echo "$line" | awk '{print $1}')
                    index=$(echo "$line" | awk '{print $2}')
                    if [ -n "$table" ] && [ -n "$index" ]; then
                        rebuild_index "$table" "$index"
                    fi
                fi
            done

        log_success "Index optimization completed"
    fi
}

# Function to clean up old data
cleanup_old_data() {
    log_info "Cleaning up old data"

    # Example: Delete old logs older than 90 days
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
        -e "
            DELETE FROM application_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
            DELETE FROM audit_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
            DELETE FROM session_data WHERE expires_at < NOW();
            OPTIMIZE TABLE application_logs, audit_logs, session_data;
        " 2>/dev/null && {
        log_success "Old data cleanup completed"
    } || {
        log_warn "Cleanup operations encountered issues"
    }
}

# Function to vacuum database (for PostgreSQL)
vacuum_database() {
    log_info "Running VACUUM operations"

    if command -v psql &> /dev/null; then
        psql -h"$DB_HOST" -p"$DB_PORT" -U postgres -d postgres -c "
            VACUUM ANALYZE;
            SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'postgres';
        " 2>/dev/null && {
        log_success "Vacuum completed"
    } || {
        log_warn "Vacuum operations failed"
    }
    fi
}

# Function to check database health
check_health() {
    log_info "Checking database health"

    local health_status="healthy"
    local issues=()

    if command -v mysql &> /dev/null; then
        # Check slow query log
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "SHOW VARIABLES LIKE 'slow_query_log';" 2>/dev/null | grep -q "On" && {
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
                -e "SELECT COUNT(*) as slow_queries FROM slow_log WHERE start_time > DATE_SUB(NOW(), INTERVAL 1 HOUR);" 2>/dev/null | \
                while read -r line; do
                    queries=$(echo "$line" | awk '{print $1}')
                    if [ "$queries" -gt 10 ]; then
                        health_status="warning"
                        issues+=("High slow query count: $queries")
                    fi
                done
        } || true

        # Check replication status
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep -q "Slave_IO_Running: Yes" && \
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep -q "Slave_SQL_Running: Yes" && {
            log_success "Replication is healthy"
        } || {
            log_warn "Replication status unknown"
        }
    fi

    # Check table count
    local table_count=0
    if command -v mysql &> /dev/null; then
        table_count=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
            -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null | \
            awk '{print $1}')
    fi

    log_info "Database contains $table_count tables"

    if [ "$health_status" = "healthy" ]; then
        log_success "Database health check passed"
    else
        log_warn "Database health check: $health_status"
        echo "Issues found: ${issues[*]}"
    fi

    echo "$health_status"
}

# Function to create maintenance report
create_report() {
    local report_file="/var/reports/db-maintenance-$(date +%Y%m%d).md"
    log_info "Creating maintenance report: $report_file"

    cat > "$report_file" << EOF
# Database Maintenance Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Hostname:** $(hostname)
**Database:** ${DB_NAME}
**Host:** ${DB_HOST}:${DB_PORT}

## Overview

- **Tables:** $(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null | awk '{print $1}' || echo "N/A")
- **Database Size:** $(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null | awk '{print $1}' || echo "N/A") MB

## Recent Operations

- **Backup:** $(ls -t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -1 | xargs -I{} basename {} 2>/dev/null || echo "N/A")
- **Last Optimization:** $(ls -t /var/log/db-optimization-*.log 2>/dev/null | head -1 | xargs -I{} basename {} 2>/dev/null || echo "N/A")

## Health Status

$(check_health 2>/dev/null)

## Configuration

- **Slow Query Threshold:** 1 second
- **Max Index Fragments:** ${MAX_INDEX_FRAGMENTS}%
- **Max Table Fragments:** ${MAX_TABLE_FRAGMENTS}%

---
*Generated by Database Maintenance Script*
EOF

    log_success "Report created: $report_file"
    cat "$report_file"
}

# Function to run full maintenance
run_full_maintenance() {
    log_info "Starting full database maintenance"

    local start_time=$(date +%s)
    local steps_completed=0
    local steps_total=5

    # Step 1: Check connection
    if check_connection; then
        steps_completed=$((steps_completed + 1))
    fi

    # Step 2: Backup
    backup_before_maintenance
    steps_completed=$((steps_completed + 1))

    # Step 3: Optimize tables
    local tables=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
        -e "SHOW TABLES FROM ${DB_NAME};" 2>/dev/null | tail -n +2 | awk '{print $1}' || true)
    for table in $tables; do
        if [ -n "$table" ]; then
            optimize_table "$table"
        fi
    done
    log_success "Table optimization completed"
    steps_completed=$((steps_completed + 1))

    # Step 4: Analyze tables
    for table in $tables; do
        if [ -n "$table" ]; then
            analyze_table "$table"
        fi
    done
    log_success "Table analysis completed"
    steps_completed=$((steps_completed + 1))

    # Step 5: Clean up old data
    cleanup_old_data
    steps_completed=$((steps_completed + 1))

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Full maintenance completed in ${duration} seconds ($steps_completed/$steps_total steps)"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    check          Check database health (default)
    backup         Create backup
    optimize       Optimize tables and indexes
    analyze        Analyze table statistics
    cleanup        Clean up old data
    report         Generate maintenance report
    full           Run full maintenance (default)
    help           Show this help message

Environment Variables:
    DB_HOST              Database host (default: localhost)
    DB_PORT              Database port (default: 3306)
    DB_NAME              Database name (default: myapp)
    DB_USER              Database user (default: mysql)
    BACKUP_DIR           Backup directory (default: /var/backups/database)

Examples:
    $0 check              # Check database health
    $0 backup             # Create backup
    $0 optimize           # Optimize tables
    $0 report             # Generate report
    $0 full               # Run full maintenance

EOF
}

# Main execution
main() {
    # Parse arguments
    local command="${1:-full}"

    case $command in
        check)
            check_health
            ;;
        backup)
            backup_before_maintenance
            ;;
        optimize)
            optimize_indexes
            ;;
        analyze)
            for table in $(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" \
                -e "SHOW TABLES FROM ${DB_NAME};" 2>/dev/null | tail -n +2 | awk '{print $1}' || true); do
                analyze_table "$table"
            done
            ;;
        cleanup)
            cleanup_old_data
            ;;
        report)
            create_report
            ;;
        full)
            run_full_maintenance
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
