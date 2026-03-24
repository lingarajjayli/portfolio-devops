# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**portfolio-devops** is a DevOps demonstration project structured as a portfolio showcasing various DevOps tools and practices. The project uses a documentation-first approach with README files in each subdirectory.

## Architecture

The project is organized into the following functional areas:

```
portfolio-devops/
├── docker/           - Docker-related documentation and configurations
├── terraform/        - Terraform Infrastructure as Code resources
├── k8s/              - Kubernetes manifests and configurations
├── scripts/          - Shell scripts for automation
└── .github/workflows/ - GitHub Actions CI/CD pipelines
```

**CI/CD Pipeline** (`.github/workflows/ci.yml`):
- **health-check**: Basic sanity check on push and PR
- **shellcheck**: Lints shell scripts in the `scripts/` directory using ShellCheck

## High-Level Architecture

This is a portfolio/demo project designed to demonstrate DevOps practices. Each subdirectory represents a different DevOps technology or practice. The project structure emphasizes documentation over code complexity, making it easy to understand and extend.

- **docker/**: Contains Docker-related documentation and configurations for containerization demonstrations
- **terraform/**: Holds Terraform IaC resources for infrastructure provisioning examples
- **k8s/**: Includes Kubernetes deployment manifests and configurations
- **scripts/**: Contains shell scripts for automation tasks (all linted with ShellCheck in CI)
- **.github/workflows/**: Defines CI/CD pipelines that run on push and PR to master

## Common Commands

### Shell Scripts
- Run a script: `./scripts/<name>.sh` (may need `chmod +x` first)
- ShellCheck: `shellcheck ./scripts/*`
- Run with bash: `bash ./scripts/<name>.sh`

### Docker
See `docker/README.md` for container-related documentation.

### Terraform
See `terraform/README.md` for IaC resource documentation.

### Kubernetes
See `k8s/README.md` for deployment manifest documentation.

### Git Workflow
- Commit to `master` branch (main branch)
- Create PRs against `master`
- CI runs on push and PR to `master`

## Development Practices

1. **Shell Scripts**: All scripts in `scripts/` are linted with ShellCheck in CI
2. **Documentation**: Each subdirectory has a README.md with relevant documentation
3. **CI Integration**: Changes trigger automated checks on the `master` branch
4. **Branch Strategy**: Single `master` branch for production-ready code

## Tools Used

- **GitHub Actions**: CI/CD automation
- **ShellCheck**: Shell script linting
- **Docker**: Containerization
- **Terraform**: Infrastructure as Code
- **Kubernetes**: Container orchestration
