# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying containerized applications.

## Architecture

```
k8s/
├── deployments/         # Application deployments
├── services/            # Service definitions
├── configmaps/         # Configuration data
├── secrets/             # Sensitive configuration
├── ingress/            # Ingress configurations
├── namespaces/         # Namespace definitions
└── README.md           # This file
```

## Quick Start

### 1. Setup Namespace

```bash
kubectl create namespace devops-portfolio
kubectl apply -f k8s/namespaces/
```

### 2. Deploy Application

```bash
kubectl apply -f k8s/
```

### 3. Access Application

```bash
# Get service endpoint
kubectl get service -n devops-portfolio

# Open port in firewall
kubectl port-forward svc/myapp-frontend 8080:80 -n devops-portfolio
```

## Manifest Documentation

### Deployments

- `deployments/frontend.yaml` - Frontend web application
- `deployments/backend.yaml` - Backend API service
- `deployments/worker.yaml` - Background job processor

### Services

- `services/frontend-service.yaml` - Load balancer for frontend
- `services/backend-service.yaml` - Load balancer for backend
- `services/database-service.yaml` - Database headless service

### ConfigMaps

- `configmaps/frontend-config.yaml` - Frontend configuration
- `configmaps/backend-config.yaml` - Backend configuration

### Secrets

- `secrets/db-credentials.yaml` - Database credentials (example)

### Ingress

- `ingress/main.yaml` - Main ingress with TLS

## Deployment Strategy

We use rolling updates for zero-downtime deployments:

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

## Monitoring

Enable metrics-server for resource monitoring:

```bash
kubectl top pods -n devops-portfolio
```

## Scale Applications

```bash
# Scale deployment
kubectl scale deployment myapp-frontend --replicas=3 -n devops-portfolio

# View deployment status
kubectl get deployments -n devops-portfolio
```

## Rollback

```bash
# Rollback to previous revision
kubectl rollout undo deployment/myapp-frontend -n devops-portfolio

# View rollout history
kubectl rollout history deployment/myapp-frontend -n devops-portfolio
```
