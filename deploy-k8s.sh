#!/bin/bash

# Kubernetes deployment script for Knative Color Demo
set -e

echo "🚀 Deploying Knative Color Demo to Kubernetes..."

# Build the application
echo "📦 Building the application..."
./mvnw clean package -DskipTests

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t danielfbm/color-demo:latest .

# Tag with a version
VERSION=$(date +%Y%m%d-%H%M%S)
docker tag danielfbm/color-demo:latest danielfbm/color-demo:$VERSION

echo "📋 Built image: danielfbm/color-demo:latest"
echo "📋 Built image: danielfbm/color-demo:$VERSION"

# Push to Docker registry (uncomment if you want to push to a registry)
# echo "📤 Pushing Docker image to registry..."
# docker push danielfbm/color-demo:latest
# docker push danielfbm/color-demo:$VERSION

# Load image into kind cluster if using kind
if kubectl config current-context | grep -q "kind"; then
    echo "🔄 Loading image into kind cluster..."
    kind load docker-image danielfbm/color-demo:latest
fi

# Apply Kubernetes manifests
echo "⚙️  Applying Kubernetes manifests..."

# Create namespace
kubectl apply -f config/namespace.yaml

# Wait for namespace to be ready
kubectl wait --for=condition=Ready namespace/eventing-demo --timeout=60s

# Apply service account and RBAC
kubectl apply -f config/sa.yaml
kubectl apply -f config/role.yaml
kubectl apply -f config/rolebinding.yaml

# Apply the Knative service
kubectl apply -f config/color-demo-service.yaml

# Apply broker for eventing
kubectl apply -f config/broker.yaml

# Apply triggers
kubectl apply -f config/color-change-trigger.yaml

echo "✅ Deployment completed!"
echo ""
echo "📋 Checking deployment status..."

# Wait for the service to be ready
echo "⏳ Waiting for Knative service to be ready..."
kubectl wait --for=condition=Ready ksvc/color-demo-app -n eventing-demo --timeout=300s

# Get service URL
SERVICE_URL=$(kubectl get ksvc color-demo-app -n eventing-demo -o jsonpath='{.status.url}')
echo "🌐 Service URL: $SERVICE_URL"

echo ""
echo "🔍 Service status:"
kubectl get ksvc color-demo-app -n eventing-demo

echo ""
echo "🏃‍♂️ Running pods:"
kubectl get pods -n eventing-demo

echo ""
echo "🎉 Deployment successful!"
echo "📋 Access the application at: $SERVICE_URL"
echo "📋 Health check: $SERVICE_URL/cloudevents/health"
echo "📋 Color API: $SERVICE_URL/api/colors/current"
