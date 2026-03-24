# Deployment Guide

This guide provides step-by-step instructions for deploying the DevOps Portfolio.

## Prerequisites

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| Git | 2.x | Version control |
| Docker | 20.x | Container runtime |
| kubectl | 1.25+ | Kubernetes CLI |
| Terraform | 1.5+ | IaC tooling |
| AWS CLI | 2.x | AWS management |
| Node.js | 18.x | Development |

### AWS Account Setup

```bash
# Configure AWS credentials
aws configure
# Enter access key, secret key, region, output format
```

### Kubernetes Setup

```bash
# Install kubectl
# See: https://kubernetes.io/docs/tasks/tools/

# Configure kubectl with your cluster
kubectl config use-context <your-cluster-context>

# Verify connection
kubectl cluster-info
```

## Deployment Steps

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/aviator/portfolio-devops.git
cd portfolio-devops

# Create environment files for production
cp .env.example .env
nano .env  # Edit with your production values
```

### 2. Configure Environment

Edit `.env` with your values:

```bash
# Database
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_PASSWORD=your_app_password
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Redis
REDIS_PASSWORD=your_redis_password

# Secrets
JWT_SECRET=your_jwt_secret
API_KEY=your_api_key
```

### 3. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 4. Deploy Container Images

```bash
# Build frontend image
docker build -t devops-portfolio/frontend:latest ./docker/

# Build backend image
docker build -t devops-portfolio/backend:latest ./docker/

# Build worker image
docker build -t devops-portfolio/worker:latest ./docker/

# Push to registry
docker push devops-portfolio/frontend:latest
docker push devops-portfolio/backend:latest
docker push devops-portfolio/worker:latest
```

### 5. Deploy to Kubernetes

```bash
# Apply namespaces
kubectl apply -f k8s/namespaces/

# Apply configurations
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/

# Apply deployments
kubectl apply -f k8s/deployments/

# Apply services
kubectl apply -f k8s/services/

# Verify deployment
kubectl get deployments -n devops-portfolio
kubectl get pods -n devops-portfolio
```

### 6. Local Development Setup

```bash
# Start local stack
docker-compose up -d

# Access services
# http://localhost:80 (Frontend)
# http://localhost:8080 (Backend API)

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 7. Production Deployment Checklist

Before deploying to production:

- [ ] Review and secure secrets in Vault
- [ ] Configure SSL certificates (Let's Encrypt)
- [ ] Set up proper monitoring and alerting
- [ ] Configure backup policies
- [ ] Test disaster recovery procedures
- [ ] Review security policies
- [ ] Configure rate limiting
- [ ] Enable WAF rules
- [ ] Set up log aggregation
- [ ] Configure auto-scaling policies

## Rollback Procedure

### Kubernetes Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/frontend -n devops-portfolio

# View rollout history
kubectl rollout history deployment/frontend -n devops-portfolio

# Undo specific revision
kubectl rollout undo deployment/frontend -n devops-portfolio --to-revision=2
```

### Infrastructure Rollback

```bash
# Revert Terraform state
terraform state pull
git checkout <previous-commit>
terraform init -refresh-only
terraform apply
```

## Monitoring

### View Metrics

```bash
# Access Grafana
GRAFANA_PASSWORD=<password>
http://<GRAFANA_HOST>:3000

# Common dashboards
- CPU & Memory Usage
- Request Latency
- Error Rates
- Active Connections
```

### View Logs

```bash
# Kubernetes logs
kubectl logs deployment/frontend -n devops-portfolio -f

# Docker logs
docker-compose logs -f frontend

# ELK Stack
http://<ELK_HOST>:5601
```

## Cleanup

```bash
# Destroy local environment
docker-compose down -v

# Destroy Terraform infrastructure
terraform destroy

# Clean up images
docker system prune -a
```

## Support

For deployment issues:

- Check [Troubleshooting Guide](./troubleshooting.md)
- Open [GitHub Issues](https://github.com/aviator/portfolio-devops/issues)
