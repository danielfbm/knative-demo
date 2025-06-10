#!/bin/bash

# Complete Kubernetes Deployment Script with Multiple Options
set -e

echo "🚀 Knative Color Demo - Complete Kubernetes Deployment"
echo "======================================================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for deployment
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    echo "⏳ Waiting for deployment $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace
}

# Function to check if Knative Serving is available
check_knative_serving() {
    if kubectl api-resources | grep -q "serving.knative.dev"; then
        echo "✅ Knative Serving is available"
        return 0
    else
        echo "❌ Knative Serving is not available"
        return 1
    fi
}

# Build the application
echo "📦 Building the application..."
./mvnw clean package -DskipTests

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t danielfbm/color-demo:latest .

# Tag with current timestamp
VERSION=$(date +%Y%m%d-%H%M%S)
docker tag danielfbm/color-demo:latest danielfbm/color-demo:$VERSION

echo "📋 Built images:"
echo "  - danielfbm/color-demo:latest"
echo "  - danielfbm/color-demo:$VERSION"

# Check if we're using kind and load image
if kubectl config current-context | grep -q "kind"; then
    echo "🔄 Loading image into kind cluster..."
    kind load docker-image danielfbm/color-demo:latest
fi

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f config/namespace.yaml

# Wait for namespace to be ready
kubectl wait --for=condition=Ready namespace/eventing-demo --timeout=60s

# Deploy based on what's available
if check_knative_serving; then
    echo "🎯 Deploying with Knative Serving..."

    # Apply service account and RBAC
    kubectl apply -f config/sa.yaml
    kubectl apply -f config/role.yaml
    kubectl apply -f config/rolebinding.yaml

    # Apply the Knative service
    kubectl apply -f config/color-demo-service.yaml

    # Wait for Knative service to be ready
    echo "⏳ Waiting for Knative service to be ready..."
    kubectl wait --for=condition=Ready ksvc/color-demo-app -n eventing-demo --timeout=300s

    # Get service URL
    SERVICE_URL=$(kubectl get ksvc color-demo-app -n eventing-demo -o jsonpath='{.status.url}')
    echo "🌐 Knative Service URL: $SERVICE_URL"

    # Apply eventing components if available
    if kubectl api-resources | grep -q "brokers.eventing.knative.dev"; then
        echo "🔗 Setting up Knative Eventing..."
        kubectl apply -f config/broker.yaml
        kubectl apply -f config/color-change-trigger.yaml

        echo "✅ Knative Eventing configured"
    fi

else
    echo "🔧 Deploying with standard Kubernetes..."

    # Deploy standard Kubernetes resources
    kubectl apply -f config/k8s-deployment.yaml

    # Wait for deployment to be ready
    wait_for_deployment "eventing-demo" "color-demo-app"

    echo "🔌 Setting up port forwarding..."
    # Kill any existing port forwards
    pkill -f "kubectl port-forward.*color-demo-service" || true

    # Start port forwarding in background
    nohup kubectl port-forward -n eventing-demo service/color-demo-service 8080:80 > port-forward.log 2>&1 &
    PORT_FORWARD_PID=$!

    echo "📋 Port forwarding started (PID: $PORT_FORWARD_PID)"
    echo "🌐 Application URL: http://localhost:8080"
fi

echo ""
echo "🔍 Deployment Status:"
echo "===================="

# Show deployment status
kubectl get deployments -n eventing-demo
echo ""

# Show pods
echo "🏃‍♂️ Running Pods:"
kubectl get pods -n eventing-demo
echo ""

# Show services
echo "🌐 Services:"
kubectl get services -n eventing-demo
echo ""

# Test health endpoint
echo "🩺 Health Check:"
if kubectl get service -n eventing-demo color-demo-service >/dev/null 2>&1; then
    sleep 3
    if curl -s http://localhost:8080/cloudevents/health >/dev/null 2>&1; then
        echo "✅ Application is healthy!"
        HEALTH_STATUS=$(curl -s http://localhost:8080/cloudevents/health)
        echo "   Response: $HEALTH_STATUS"
    else
        echo "⚠️  Health check failed - application may still be starting"
    fi
fi

echo ""
echo "🎉 Deployment Complete!"
echo "======================"

if check_knative_serving; then
    echo "📋 Knative Service Details:"
    kubectl get ksvc -n eventing-demo
    echo ""
    echo "🔗 Access your application at: $SERVICE_URL"
else
    echo "📋 Standard Kubernetes Deployment:"
    echo "🔗 Access your application at: http://localhost:8080"
    echo "📝 Port forwarding log: tail -f port-forward.log"
fi

echo ""
echo "🧪 Test the application:"
echo "curl -s http://localhost:8080/cloudevents/health"
echo ""
echo "📚 See K8S_DEPLOYMENT.md for more details and testing instructions"
