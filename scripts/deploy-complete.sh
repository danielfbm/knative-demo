#!/bin/bash

# Complete Kubernetes Deployment Script with Multiple Options
set -e

# Source the common library
source "$(dirname "$0")/library.sh"

# Get project root and configuration
PROJECT_ROOT=$(get_project_root)
NAMESPACE="${1:-$DEFAULT_NAMESPACE}"

echo -e "${BLUE}🚀 Knative Color Demo - Complete Kubernetes Deployment${NC}"
echo "======================================================"

# Build the application
build_application "$PROJECT_ROOT"

# Build Docker image
build_docker_image "$PROJECT_ROOT"

# Load image into kind if using kind
load_image_to_kind

# Create namespace
create_namespace "$NAMESPACE"

# Deploy based on what's available
if check_knative_serving; then
    say "Deploying with Knative Serving..."

    # Apply service account and RBAC
    apply_manifest "$PROJECT_ROOT/config/auth/sa.yaml" "service account"
    apply_manifest "$PROJECT_ROOT/config/auth/role.yaml" "role"
    apply_manifest "$PROJECT_ROOT/config/auth/rolebinding.yaml" "rolebinding"

    # Apply the Knative service
    apply_manifest "$PROJECT_ROOT/config/colors/serving/color-demo-service.yaml" "Knative service"

    # Wait for Knative service to be ready
    wait_for_knative_service "color-demo-app" "$NAMESPACE"

    # Get service URL
    SERVICE_URL=$(get_knative_service_url "color-demo-app" "$NAMESPACE")
    echo -e "${GREEN}🌐 Knative Service URL: $SERVICE_URL${NC}"

    # Apply eventing components if available
    if check_knative_eventing; then
        say "Setting up Knative Eventing..."
        apply_manifest "$PROJECT_ROOT/config/broker.yaml" "broker"
        apply_manifest "$PROJECT_ROOT/config/colors/color-change-trigger.yaml" "color change trigger"
        say_success "Knative Eventing configured"
    fi

else
    say "Deploying with standard Kubernetes..."

    # Deploy standard Kubernetes resources
    apply_manifest "$PROJECT_ROOT/config/colors/k8s-deployment.yaml" "Kubernetes deployment"

    # Wait for deployment to be ready
    wait_for_deployment "$NAMESPACE" "color-demo-app"

    # Setup port forwarding
    setup_port_forward "$NAMESPACE" "color-demo-service"
fi
echo ""
echo -e "${BLUE}🔍 Deployment Status:${NC}"
echo "===================="

# Show deployment status
kubectl get deployments -n "$NAMESPACE" 2>/dev/null || echo "No deployments found"
echo ""

# Show pods
echo -e "${BLUE}🏃‍♂️ Running Pods:${NC}"
kubectl get pods -n "$NAMESPACE"
echo ""

# Show services
echo -e "${BLUE}🌐 Services:${NC}"
kubectl get services -n "$NAMESPACE"
echo ""

# Test health endpoint
echo -e "${BLUE}🩺 Health Check:${NC}"
if kubectl get service -n "$NAMESPACE" color-demo-service >/dev/null 2>&1; then
    sleep 3
    if curl -s http://localhost:8080/cloudevents/health >/dev/null 2>&1; then
        say_success "Application is healthy!"
        HEALTH_STATUS=$(curl -s http://localhost:8080/cloudevents/health)
        echo "   Response: $HEALTH_STATUS"
    else
        say_warning "Health check failed - application may still be starting"
    fi
fi

echo ""
say_success "Deployment Complete!"
echo "======================"

if check_knative_serving; then
    echo -e "${BLUE}📋 Knative Service Details:${NC}"
    kubectl get ksvc -n "$NAMESPACE"
    echo ""
    echo -e "🔗 Access your application at: ${GREEN}$SERVICE_URL${NC}"
else
    echo -e "${BLUE}📋 Standard Kubernetes Deployment:${NC}"
    echo -e "🔗 Access your application at: ${GREEN}http://localhost:8080${NC}"
    echo -e "📝 Port forwarding log: ${YELLOW}tail -f port-forward.log${NC}"
fi

echo ""
echo -e "${BLUE}🧪 Test the application:${NC}"
echo "curl -s http://localhost:8080/cloudevents/health"
echo ""
echo -e "${BLUE}📚 See K8S_DEPLOYMENT.md for more details and testing instructions${NC}"
