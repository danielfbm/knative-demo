#!/bin/bash

# Kubernetes deployment script for Knative Color Demo
set -e

# Source the common library
source "$(dirname "$0")/library.sh"

# Get project root and configuration
PROJECT_ROOT=$(get_project_root)
NAMESPACE="${1:-$DEFAULT_NAMESPACE}"

echo -e "${BLUE}🚀 Deploying Knative Color Demo to Kubernetes...${NC}"

# Build the application
build_application "$PROJECT_ROOT"

# Build Docker image
build_docker_image "$PROJECT_ROOT"

# Load image into kind cluster if using kind
load_image_to_kind

# Apply Kubernetes manifests
say "Applying Kubernetes manifests..."

# Create namespace
create_namespace "$NAMESPACE"

# Apply service account and RBAC
apply_manifest "$PROJECT_ROOT/config/auth/sa.yaml" "service account"
apply_manifest "$PROJECT_ROOT/config/auth/role.yaml" "role"
apply_manifest "$PROJECT_ROOT/config/auth/rolebinding.yaml" "rolebinding"

# Check if Knative Serving is available and deploy accordingly
if check_knative_serving; then
    say "Knative Serving detected - deploying Knative service..."
    apply_manifest "$PROJECT_ROOT/config/colors/serving/color-demo-service.yaml" "Knative service"

    # Apply broker for eventing if available
    if check_knative_eventing; then
        apply_manifest "$PROJECT_ROOT/config/broker.yaml" "broker"
        apply_manifest "$PROJECT_ROOT/config/colors/color-change-trigger.yaml" "color change trigger"
    fi

    # Wait for the service to be ready
    wait_for_knative_service "color-demo-app" "$NAMESPACE"

    # Get service URL
    SERVICE_URL=$(get_knative_service_url "color-demo-app" "$NAMESPACE")
    say_success "Deployment completed!"
    echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"

else
    say "Knative Serving not available - deploying standard Kubernetes resources..."
    apply_manifest "$PROJECT_ROOT/config/colors/k8s-deployment.yaml" "Kubernetes deployment"

    # Wait for deployment to be ready
    wait_for_deployment "$NAMESPACE" "color-demo-app"

    say_success "Deployment completed!"
    echo -e "${GREEN}🌐 Service URL: http://localhost:8080 (via port-forward)${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Service status:${NC}"
if check_knative_serving; then
    kubectl get ksvc color-demo-app -n "$NAMESPACE"
else
    kubectl get deployments -n "$NAMESPACE"
fi

echo ""
echo -e "${BLUE}🏃‍♂️ Running pods:${NC}"
kubectl get pods -n "$NAMESPACE"

if check_knative_serving; then
    echo ""
    say_success "Deployment successful!"
    echo -e "📋 Access the application at: ${GREEN}$SERVICE_URL${NC}"
    echo -e "📋 Health check: ${GREEN}$SERVICE_URL/cloudevents/health${NC}"
    echo -e "📋 Color API: ${GREEN}$SERVICE_URL/api/colors/current${NC}"
else
    # Setup port forwarding for standard deployment
    setup_port_forward "$NAMESPACE" "color-demo-service"
fi

# Apply broker for eventing
apply_manifest "$PROJECT_ROOT/config/broker.yaml" "broker"

# Apply triggers
apply_manifest "$PROJECT_ROOT/config/colors/color-change-trigger.yaml" "color change trigger"

echo "✅ Deployment completed!"
echo ""
echo "📋 Checking deployment status..."

# Wait for the service to be ready
wait_for_knative_service "color-demo-app" "$NAMESPACE"

# Get service URL
SERVICE_URL=$(get_knative_service_url "color-demo-app" "$NAMESPACE")
echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"

echo ""
echo "🔍 Service status:"
kubectl get ksvc color-demo-app -n "$NAMESPACE"

echo ""
echo "🏃‍♂️ Running pods:"
kubectl get pods -n "$NAMESPACE"

echo ""
say_success "Deployment successful!"
echo -e "📋 Access the application at: ${GREEN}$SERVICE_URL${NC}"
echo -e "📋 Health check: ${GREEN}$SERVICE_URL/cloudevents/health${NC}"
echo -e "📋 Color API: ${GREEN}$SERVICE_URL/api/colors/current${NC}"
