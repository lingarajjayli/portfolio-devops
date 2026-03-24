#!/bin/bash
#
# Monitoring Script
# A realistic monitoring script demonstrating:
# - Resource monitoring (CPU, memory, disk)
# - Application health checks
# - Alert notifications
# - Report generation
#

set -euo pipefail

# Configuration
MONITORING_DIR="/var/monitoring"
METRICS_DIR="$MONITORING_DIR/metrics"
ALERTS_DIR="$MONITORING_DIR/alerts"
REPORTS_DIR="$MONITORING_DIR/reports"
LOGS_DIR="/var/log/app"
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-http://localhost:8080/health}"
ALERT_THRESHOLD_CPU="${ALERT_THRESHOLD_CPU:-80}"
ALERT_THRESHOLD_MEMORY="${ALERT_THRESHOLD_MEMORY:-85}"
ALERT_THRESHOLD_DISK="${ALERT_THRESHOLD_DISK:-90}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Alert channels
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
EMAIL_RECIPIENT="${EMAIL_RECIPIENT:-}"
PAGERDUTY_KEY="${PAGERDUTY_KEY:-}"

# Logging
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$MONITORING_DIR/logs/monitor.log"
    mkdir -p "$(dirname "$log_file")"
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$log_file"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# Function to create monitoring directories
setup_monitoring() {
    log_info "Setting up monitoring directories"
    mkdir -p "$METRICS_DIR"/{daily,hourly}
    mkdir -p "$ALERTS_DIR"
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$MONITORING_DIR/logs"

    # Create alert configuration
    cat > "$MONITORING_DIR/.env" << 'EOF'
# Monitoring Configuration
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_RESPONSE_TIME=1000
SLACK_WEBHOOK=
EMAIL_RECIPIENT=
PAGERDUTY_KEY=
EOF
}

# Function to get CPU usage
get_cpu_usage() {
    if command -v top &> /dev/null; then
        # Use top for CPU usage
        local cpu=$(top -bnm | grep "^%Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        echo "${cpu%.*}"
    else
        # Fallback: use /proc/stat
        local cpu_line=$(head -n1 /proc/stat)
        local cpu_user=$(echo "$cpu_line" | awk '{print $2}')
        local cpu_nice=$(echo "$cpu_line" | awk '{print $3}')
        local cpu_system=$(echo "$cpu_line" | awk '{print $4}')
        local cpu_idle=$(echo "$cpu_line" | awk '{print $5}')
        local total=$((cpu_user + cpu_nice + cpu_system + cpu_idle))
        local used=$((total - cpu_idle))
        local usage=$((used * 100 / total))
        echo "$usage"
    fi
}

# Function to get memory usage
get_memory_usage() {
    if command -v free &> /dev/null; then
        local total=$(free | awk '/^Mem:/ {print $2}')
        local used=$(free | awk '/^Mem:/ {print $3}')
        if [ "$total" -gt 0 ]; then
            echo $((used * 100 / total))
        else
            echo "0"
        fi
    else
        # Fallback: use /proc/meminfo
        local total=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
        local available=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
        if [ -n "$total" ] && [ -n "$available" ] && [ "$total" -gt 0 ]; then
            local used=$((total - available))
            echo $((used * 100 / total))
        else
            echo "0"
        fi
    fi
}

# Function to get disk usage
get_disk_usage() {
    local path="${1:-/}"
    if command -v df &> /dev/null; then
        df "$path" | awk '{print $5}' | sed 's/%//'
    else
        echo "0"
    fi
}

# Function to get network stats
get_network_stats() {
    if command -v netstat &> /dev/null || command -v ss &> /dev/null; then
        local active_connections=$(ss -tan state established | wc -l)
        echo "$active_connections"
    else
        echo "N/A"
    fi
}

# Function to check application health
check_health() {
    log_info "Checking application health"

    local health_status="healthy"
    local response_time=0
    local error_count=0

    # HTTP health check
    if command -v curl &> /dev/null; then
        local start_time=$(date +%s%N)
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL" 2>/dev/null || echo "000")
        local end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

        if [ "$http_code" = "200" ]; then
            log_info "Health check passed (HTTP $http_code, ${response_time}ms)"
        else
            log_warn "Health check failed (HTTP $http_code, ${response_time}ms)"
            health_status="unhealthy"
            error_count=1
        fi
    fi

    # Process health check
    local running_processes=$(ps aux | grep -E "app|application|service" | grep -v grep | wc -l)
    if [ "$running_processes" -eq 0 ]; then
        log_warn "No application processes found"
        health_status="unhealthy"
        error_count=$((error_count + 1))
    else
        log_info "Application processes running: $running_processes"
    fi

    echo "$health_status|$error_count|$response_time"
}

# Function to check for alerts
check_alerts() {
    log_info "Checking system alerts"

    local alerts_found=0
    local alert_messages=""

    # CPU alert
    local cpu_usage=$(get_cpu_usage)
    if [ "${cpu_usage:-0}" -ge "${ALERT_THRESHOLD_CPU}" ]; then
        log_warn "CPU usage alert: ${cpu_usage}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
        alerts_found=$((alerts_found + 1))
        alert_messages="$alert_messages\n    - CPU: ${cpu_usage}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
    else
        log_info "CPU usage OK: ${cpu_usage}%"
    fi

    # Memory alert
    local memory_usage=$(get_memory_usage)
    if [ "${memory_usage:-0}" -ge "${ALERT_THRESHOLD_MEMORY}" ]; then
        log_warn "Memory usage alert: ${memory_usage}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        alerts_found=$((alerts_found + 1))
        alert_messages="$alert_messages\n    - Memory: ${memory_usage}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
    else
        log_info "Memory usage OK: ${memory_usage}%"
    fi

    # Disk alert
    local disk_usage=$(get_disk_usage "/")
    if [ "${disk_usage:-0}" -ge "${ALERT_THRESHOLD_DISK}" ]; then
        log_warn "Disk usage alert: ${disk_usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        alerts_found=$((alerts_found + 1))
        alert_messages="$alert_messages\n    - Disk: ${disk_usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
    else
        log_info "Disk usage OK: ${disk_usage}%"
    fi

    # Generate alert if needed
    if [ $alerts_found -gt 0 ]; then
        log_error "Alerts found: $alerts_found$alert_messages"
        return 1
    else
        log_success "No alerts"
        return 0
    fi
}

# Function to send Slack notification
send_slack_alert() {
    local message=$1
    local severity=${2:-info}

    if [ -n "$SLACK_WEBHOOK" ]; then
        local color="good"
        case $severity in
            info) color="good" ;;
            warn) color="warning" ;;
            error) color="danger" ;;
        esac

        # URL-encode the message
        local encoded_message=$(echo -n "$message" | sed 's/ /%20/g' | sed 's/\n/%0A/g')

        curl -s -X POST \
            -H 'Content-type: application/json' \
            -d "{\"attachments\":[{\"color\":\"$color\",\"text\":\"$encoded_message\",\"footer\":\"DevOps Monitoring\"}]}" \
            "$SLACK_WEBHOOK" > /dev/null 2>&1 && \
        log_info "Slack notification sent" || \
        log_warn "Failed to send Slack notification"
    fi
}

# Function to send email alert
send_email_alert() {
    local message=$1
    local subject="[$(hostname)] Monitoring Alert: ${2:-System}"

    if command -v mail &> /dev/null && [ -n "$EMAIL_RECIPIENT" ]; then
        echo "$message" | mail -s "$subject" "$EMAIL_RECIPIENT"
        log_info "Email alert sent to $EMAIL_RECIPIENT"
    else
        log_warn "Email alert not sent (mail command not available or no recipient configured)"
    fi
}

# Function to send PagerDuty alert
send_pagerduty_alert() {
    local message=$1

    if [ -n "$PAGERDUTY_KEY" ]; then
        curl -s -X POST \
            -H "Authorization: Token $PAGERDUTY_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"routing_key\":\"$PAGERDUTY_KEY\",\"event_action\":\"trigger\",\"payload\":{\"summary\":\"$(hostname): $message\",\"severity\":\"error\",\"source\":\"devops-monitor\",\"custom_details\":{\"hostname\":\"$(hostname)\"}}}" \
            "https://events.pagerduty.com/v2/enqueue" > /dev/null 2>&1 && \
        log_info "PagerDuty alert sent" || \
        log_warn "Failed to send PagerDuty alert"
    fi
}

# Function to generate daily report
generate_report() {
    local report_file="$REPORTS_DIR/report_$(date +%Y%m%d).md"
    log_info "Generating daily report: $report_file"

    cat > "$report_file" << EOF
# Daily Monitoring Report - $(date '+%Y-%m-%d')

## System Overview

- **Hostname:** $(hostname)
- **Timestamp:** $(date '+%Y-%m-%d %H:%M:%S')
- **Load Average:** $(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo "N/A")

## Resource Usage

### CPU Usage
```
$(get_cpu_usage)%
```

### Memory Usage
- Used: $(get_memory_usage)%
- Total: $(free | awk '/^Mem:/ {print $2}' || echo "N/A")
- Available: $(free | awk '/^Mem:/ {print $7}' || echo "N/A")

### Disk Usage
```
$(df -h / | tail -1 | awk '{print $5}')
```

### Network
- Active Connections: $(get_network_stats)

## Health Status

$(check_health)

## Alerts

$(check_alerts 2>/dev/null || echo "No alerts")

## Metric History

```
$(ls -lt "$METRICS_DIR"/daily 2>/dev/null | head -5 | awk '{print $NF, $5}' || echo "No history available")
```

---
*Generated by DevOps Monitoring Script*
EOF

    log_success "Report generated: $report_file"
    cat "$report_file"
}

# Function to collect metrics
collect_metrics() {
    log_info "Collecting metrics"

    local cpu=$(get_cpu_usage)
    local memory=$(get_memory_usage)
    local disk=$(get_disk_usage "/")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Store metrics
    echo "$timestamp|CPU:${cpu}%|MEM:${memory}%|DISK:${disk}%" >> "$METRICS_DIR/daily/metrics.log"

    log_info "Metrics collected: CPU=${cpu}%, MEM=${memory}%, DISK=${disk}%"
}

# Function to run all checks
run_all_checks() {
    log_info "Starting monitoring checks"

    check_health
    local alerts_exit=$?
    collect_metrics
    generate_report

    return $alerts_exit
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    check          Run all monitoring checks (default)
    cpu            Check CPU usage only
    memory         Check memory usage only
    disk           Check disk usage only
    health         Run health checks only
    metrics        Collect metrics only
    report         Generate daily report
    all            Run all checks and generate report

Alert Configuration:
    SLACK_WEBHOOK       Slack webhook URL for notifications
    EMAIL_RECIPIENT     Email address for alerts
    PAGERDUTY_KEY       PagerDuty integration key

Environment Variables:
    ALERT_THRESHOLD_CPU          CPU alert threshold (default: 80%)
    ALERT_THRESHOLD_MEMORY       Memory alert threshold (default: 85%)
    ALERT_THRESHOLD_DISK         Disk usage threshold (default: 90%)
    HEALTH_CHECK_URL             Health check endpoint URL

Examples:
    $0 check            # Run all monitoring checks
    $0 cpu              # Check CPU usage only
    $0 health           # Run health checks
    $0 report           # Generate daily report

EOF
}

# Main execution
main() {
    # Parse arguments
    local command="${1:-check}"

    case $command in
        check|all)
            setup_monitoring
            run_all_checks
            ;;
        cpu)
            setup_monitoring
            echo "CPU Usage: $(get_cpu_usage)% (threshold: ${ALERT_THRESHOLD_CPU}%)"; \
            [ "${get_cpu_usage:-0}" -ge "${ALERT_THRESHOLD_CPU:-80}" ] && exit 1 || exit 0
            ;;
        memory)
            setup_monitoring
            echo "Memory Usage: $(get_memory_usage)% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"; \
            [ "${get_memory_usage:-0}" -ge "${ALERT_THRESHOLD_MEMORY:-85}" ] && exit 1 || exit 0
            ;;
        disk)
            setup_monitoring
            echo "Disk Usage: $(get_disk_usage)/ (threshold: ${ALERT_THRESHOLD_DISK}%)"; \
            [ "${get_disk_usage:-0}" -ge "${ALERT_THRESHOLD_DISK:-90}" ] && exit 1 || exit 0
            ;;
        health)
            setup_monitoring
            check_health
            ;;
        metrics)
            setup_monitoring
            collect_metrics
            ;;
        report)
            setup_monitoring
            generate_report
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
