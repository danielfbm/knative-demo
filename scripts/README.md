# Scripts Directory

This directory contains organized scripts for the Knative Color Demo project. All scripts have been refactored to use the common `library.sh` for shared functionality.

## Library

- **`library.sh`** - Common functions library that all other scripts source
  - Color output functions (`say`, `say_success`, `say_error`, `say_warning`)
  - Kubernetes utility functions (`wait_for_deployment`, `wait_for_knative_service`, etc.)
  - Docker and build functions (`build_application`, `build_docker_image`, etc.)
  - Test helper functions (`run_test`, `send_cloud_event`, etc.)

## Installation Scripts

- **`install-cert-manager.sh`** - Installs cert-manager v1.17.2
- **`install.sh`** - Installs Knative Eventing components v1.18.1

## Deployment Scripts

- **`deploy.sh [namespace]`** - Basic Knative deployment (requires Knative Serving)
- **`deploy-k8s.sh [namespace]`** - Smart deployment (Knative if available, otherwise standard K8s)
- **`deploy-complete.sh [namespace]`** - Complete deployment with comprehensive status checking

## Testing Scripts

- **`test-cloudevents.sh [api_endpoint] [start_app]`** - Basic CloudEvents testing
- **`test-complete.sh [base_url]`** - Comprehensive test suite with all endpoints

## Usage Examples

### Install Knative Eventing
```bash
./scripts/install-cert-manager.sh
./scripts/install.sh
```

### Deploy the application
```bash
# Quick deployment (requires Knative)
./scripts/deploy.sh

# Smart deployment (adapts to available platform)
./scripts/deploy-k8s.sh

# Complete deployment with full status
./scripts/deploy-complete.sh
```

### Test the application
```bash
# Basic testing
./scripts/test-cloudevents.sh

# Comprehensive testing
./scripts/test-complete.sh

# Test with local Spring Boot app
./scripts/test-cloudevents.sh http://localhost:8080 true
```

## Features

✅ **Path Resolution**: All scripts correctly resolve project paths regardless of execution location
✅ **Error Handling**: Comprehensive error checking and user-friendly messages
✅ **Platform Detection**: Automatic detection of Knative Serving/Eventing availability
✅ **Kind Integration**: Automatic image loading for kind clusters
✅ **Colored Output**: Consistent colored output for better readability
✅ **Flexible Deployment**: Support for both Knative and standard Kubernetes deployments
✅ **Comprehensive Testing**: Full test suite covering all endpoints and functionality

## Namespace Configuration

All deployment scripts accept an optional namespace parameter:
- Default namespace: `eventing-demo`
- Custom namespace: `./scripts/deploy.sh my-namespace`

## Common Issues Fixed

1. **Path Issues**: Scripts now use `get_project_root()` to find the correct project directory
2. **Missing Dependencies**: Proper error handling when required tools are missing
3. **Platform Compatibility**: Scripts adapt to available Kubernetes platform features
4. **Resource Waiting**: Proper waiting for resources to be ready before proceeding
5. **Port Conflicts**: Automatic cleanup of existing port forwards

## Development

When adding new scripts:
1. Source the library: `source "$(dirname "$0")/library.sh"`
2. Use library functions instead of duplicating code
3. Follow the established patterns for error handling and output
4. Test with both Knative and standard Kubernetes environments
