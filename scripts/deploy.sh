#!/bin/bash

# Build and Deploy Script for Knative Color Demo
set -e

# Source the common library
source "$(dirname "$0")/library.sh"

# Get project root directory
PROJECT_ROOT=$(get_project_root)
NAMESPACE="${1:-knative-demo}"

echo -e "${BLUE}🚀 Building and deploying Knative Color Demo...${NC}"

# Build the application
build_application "$PROJECT_ROOT"

# Build Docker image
build_docker_image "$PROJECT_ROOT"

# Load image into kind if using kind
load_image_to_kind

# Create namespace if it doesn't exist
create_namespace "$NAMESPACE"

# Apply Knative configurations
say "Applying Knative configurations..."

# Apply service account, role, and rolebinding
apply_manifest "$PROJECT_ROOT/config/auth/sa.yaml" "service account"
apply_manifest "$PROJECT_ROOT/config/auth/role.yaml" "role"
apply_manifest "$PROJECT_ROOT/config/auth/rolebinding.yaml" "rolebinding"

# Apply broker
apply_manifest "$PROJECT_ROOT/config/broker.yaml" "broker"

# Apply the color demo service
apply_manifest "$PROJECT_ROOT/config/colors/serving/color-demo-service.yaml" "color demo service"

# Apply triggers
apply_manifest "$PROJECT_ROOT/config/colors/color-change-trigger.yaml" "color change trigger"

# Wait for the service to be ready
wait_for_knative_service "color-demo-app" "$NAMESPACE"

# Get the service URL
SERVICE_URL=$(get_knative_service_url "color-demo-app" "$NAMESPACE")
say_success "Service deployed successfully!"
echo -e "${GREEN}🌐 Service URL: ${SERVICE_URL}${NC}"

# Optionally deploy the event sender for testing
read -p "Deploy color event sender for testing? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    say "Deploying color event sender..."
    apply_manifest "$PROJECT_ROOT/config/colors/color-event-producer.yaml" "color event sender"
    say_success "Color event sender deployed!"
fi

say_success "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Open ${SERVICE_URL} in your browser"
echo "2. Watch the timeline for color changes"
echo "3. Monitor received CloudEvents in the right panel"
echo "4. Manually change colors using the form"
echo ""
echo "To send test events manually:"
echo "curl -X POST ${SERVICE_URL}/cloudevents \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Ce-Id: test-\$(date +%s)' \\"
echo "  -H 'Ce-Source: manual-test' \\"
echo "  -H 'Ce-Type: com.example.color.change' \\"
echo "  -H 'Ce-Specversion: 1.0' \\"
echo "  -d '{\"color\": \"BLUE\"}'"
SERVICE_URL=$(kubectl get ksvc color-demo-app -n ${NAMESPACE} -o jsonpath='{.status.url}')
echo "✅ Service deployed successfully!"
echo "🌐 Service URL: ${SERVICE_URL}"

# Optionally deploy the event sender for testing
read -p "Deploy color event sender for testing? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🎨 Deploying color event sender..."
    kubectl apply -f config/color-event-sender.yaml
    echo "✅ Color event sender deployed!"
fi

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Open ${SERVICE_URL} in your browser"
echo "2. Watch the timeline for color changes"
echo "3. Monitor received CloudEvents in the right panel"
echo "4. Manually change colors using the form"
echo ""
echo "To send test events manually:"
echo "curl -X POST ${SERVICE_URL}/cloudevents \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Ce-Id: test-$(date +%s)' \\"
echo "  -H 'Ce-Source: manual-test' \\"
echo "  -H 'Ce-Type: com.example.color.change' \\"
echo "  -H 'Ce-Specversion: 1.0' \\"
echo "  -d '{\"color\": \"BLUE\"}'"
