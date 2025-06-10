#!/bin/bash

# Build and Deploy Script for Knative Color Demo

set -e

# Configuration
IMAGE_NAME="danielfbm/color-demo"
TAG="latest"
NAMESPACE="knative-demo"

echo "🚀 Building and deploying Knative Color Demo..."

# Build the application
echo "📦 Building Spring Boot application..."
./mvnw clean package -DskipTests

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Push to registry (uncomment if using remote registry)
# echo "📤 Pushing to registry..."
# docker push ${IMAGE_NAME}:${TAG}

# Create namespace if it doesn't exist
echo "📋 Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Apply Knative configurations
echo "🔧 Applying Knative configurations..."

# Apply service account, role, and rolebinding
kubectl apply -f config/sa.yaml
kubectl apply -f config/role.yaml
kubectl apply -f config/rolebinding.yaml

# Apply broker
kubectl apply -f config/broker.yaml

# Apply the color demo service
kubectl apply -f config/color-demo-service.yaml

# Apply triggers
kubectl apply -f config/color-change-trigger.yaml

# Wait for the service to be ready
echo "⏳ Waiting for service to be ready..."
kubectl wait --for=condition=Ready ksvc/color-demo-app -n ${NAMESPACE} --timeout=300s

# Get the service URL
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
