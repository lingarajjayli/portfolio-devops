#!/bin/bash
#
# Deploy Application Script
# A realistic CI/CD deployment script demonstrating best practices:
# - Environment-specific configuration
# - Health checks
# - Rolling deployment strategy
# - Error handling and rollback
#

set -euo pipefail

# Configuration
APP_NAME="${APP_NAME:-myapp}"
NAMESPACE="${NAMESPACE:-default}"
REPO="${REPO:-github.com/lingarajjayli/portfolio-devops}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DEPLOY_DIR="/tmp/deployments"
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $level in
        INFO)  echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}" ;;
    esac
}

# Function to check if running in Kubernetes
check_k8s() {
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null 2>&1; then
        log "INFO" "Running on Kubernetes cluster"
        return 0
    else
        log "INFO" "Not running on Kubernetes, using local deployment"
        return 1
    fi
}

# Function to perform health check
health_check() {
    log "INFO" "Performing health check for $APP_NAME..."

    if check_k8s; then
        # Kubernetes health check
        local retry=0
        while [ $retry -lt $HEALTH_CHECK_RETRIES ]; do
            if kubectl wait --for=condition=ready pod \
                --selector=app=$APP_NAME \
                --namespace=$NAMESPACE \
                --timeout=${HEALTH_CHECK_INTERVAL}s 2>/dev/null; then
                log "INFO" "Health check passed"
                return 0
            fi
            retry=$((retry + 1))
        done
        log "ERROR" "Health check failed after $HEALTH_CHECK_RETRIES attempts"
        return 1
    else
        # Local health check (simulated)
        log "INFO" "Simulating health check for local deployment"
        return 0
    fi
}

# Function to rollback previous deployment
rollback() {
    log "WARN" "Initiating rollback..."

    if check_k8s; then
        kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE 2>/dev/null || true
        log "INFO" "Rollback completed"
    else
        log "INFO" "No rollback required (local deployment)"
    fi
}

# Function to deploy application
deploy_app() {
    log "INFO" "Deploying $APP_NAME:tag=$IMAGE_TAG"

    if check_k8s; then
        # Kubernetes deployment
        kubectl apply -f "${DEPLOY_DIR}/deployment.yaml" -n $NAMESPACE || {
            log "ERROR" "Failed to deploy to Kubernetes"
            rollback
            return 1
        }

        kubectl apply -f "${DEPLOY_DIR}/service.yaml" -n $NAMESPACE || {
            log "ERROR" "Failed to create service"
            rollback
            return 1
        }

        log "INFO" "Application deployed successfully to Kubernetes"
    else
        # Simulate local deployment
        log "INFO" "Simulating deployment for local environment"
        mkdir -p "${DEPLOY_DIR}/${APP_NAME}"
        log "INFO" "Deployment artifacts stored in ${DEPLOY_DIR}/${APP_NAME}"
    fi

    health_check
    return $?
}

# Function to configure environment
configure_env() {
    local env=$1

    case $env in
        dev|development)
            log "INFO" "Configuring for development environment"
            export DEPLOY_ENV="development"
            ;;
        staging|staging)
            log "INFO" "Configuring for staging environment"
            export DEPLOY_ENV="staging"
            ;;
        prod|production)
            log "INFO" "Configuring for production environment"
            export DEPLOY_ENV="production"
            ;;
        *)
            log "WARN" "Using default environment: development"
            export DEPLOY_ENV="development"
            ;;
    esac
}

# Function to validate release
validate_release() {
    log "INFO" "Validating release..."

    # Simulate release validation checks
    local checks_passed=0
    local checks_failed=0

    # Check 1: Deployment readiness
    if [ -n "$DEPLOY_ENV" ]; then
        checks_passed=$((checks_passed + 1))
    else
        checks_failed=$((checks_failed + 1))
    fi

    # Check 2: Health endpoint
    if health_check; then
        checks_passed=$((checks_passed + 1))
    else
        checks_failed=$((checks_failed + 1))
        rollback
    fi

    # Check 3: Resource limits (Kubernetes)
    if check_k8s; then
        kubectl get deployment $APP_NAME -n $NAMESPACE 2>/dev/null && checks_passed=$((checks_passed + 1))
    fi

    if [ $checks_failed -eq 0 ]; then
        log "INFO" "All release validation checks passed ($checks_passed checks)"
        return 0
    else
        log "ERROR" "Release validation failed with $checks_failed checks"
        return 1
    fi
}

# Main execution
main() {
    local command=${1:-help}

    case $command in
        deploy)
            configure_env "${2:-dev}"
            deploy_app
            ;;
        rollback)
            rollback
            ;;
        health-check)
            health_check
            ;;
        validate)
            validate_release
            ;;
        help|*)
            log "INFO" "Usage: $0 <command> [options]"
            log "INFO" "Commands:"
            log "INFO" "  deploy        Deploy the application"
            log "INFO" "  rollback      Rollback to previous version"
            log "INFO" "  health-check  Run health check"
            log "INFO" "  validate      Validate release"
            log "INFO" "  help          Show this help message"
            log "INFO" ""
            log "INFO" "Environment variables:"
            log "INFO" "  APP_NAME      Application name (default: myapp)"
            log "INFO" "  NAMESPACE     Kubernetes namespace (default: default)"
            log "INFO" "  REPO          Git repository URL"
            log "INFO" "  IMAGE_TAG     Image tag (default: latest)"
            log "INFO" "  DEPLOY_ENV    Deployment environment (dev/staging/prod)"
            ;;
    esac
}

# Run main function
main "$@"
