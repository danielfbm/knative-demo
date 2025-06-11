#!/bin/bash

# Common library functions for Knative Color Demo scripts
# Source this file in other scripts: source "$(dirname "$0")/library.sh"

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export NC='\033[0m' # No Color

# Configuration
export IMAGE_NAME="danielfbm/color-demo"
export TAG="latest"
export DEFAULT_NAMESPACE="eventing-demo"

# Determine project root directory
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(dirname "$script_dir")"
}

# Enhanced say function with colors
say() {
    echo -e "${BLUE}==> $1${NC}"
}

# Success message
say_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Error message
say_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Warning message
say_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for deployment
wait_for_deployment() {
    local namespace="$1"
    local deployment="$2"
    local timeout="${3:-300}"
    
    say "Waiting for deployment $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n "$namespace"
}

# Function to wait for Knative service
wait_for_knative_service() {
    local service_name="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    say "Waiting for Knative service $service_name to be ready..."
    kubectl wait --for=condition=Ready ksvc/"$service_name" -n "$namespace" --timeout=${timeout}s
}

# Function to check if Knative Serving is available
check_knative_serving() {
    if kubectl api-resources | grep -q "serving.knative.dev"; then
        return 0
    else
        return 1
    fi
}

# Function to check if Knative Eventing is available
check_knative_eventing() {
    if kubectl api-resources | grep -q "eventing.knative.dev"; then
        return 0
    else
        return 1
    fi
}

# Function to build Spring Boot application
build_application() {
    local project_root="$1"
    say "Building Spring Boot application..."
    "$project_root/mvnw" clean package -DskipTests
}

# Function to build Docker image
build_docker_image() {
    local project_root="$1"
    local image_name="${2:-$IMAGE_NAME}"
    local tag="${3:-$TAG}"
    
    say "Building Docker image..."
    docker build -t "${image_name}:${tag}" "$project_root"
    
    # Tag with timestamp version
    local version=$(date +%Y%m%d-%H%M%S)
    docker tag "${image_name}:${tag}" "${image_name}:${version}"
    
    say_success "Built images:"
    echo "  - ${image_name}:${tag}"
    echo "  - ${image_name}:${version}"
}

# Function to load image into kind cluster if using kind
load_image_to_kind() {
    local image_name="${1:-$IMAGE_NAME}"
    local tag="${2:-$TAG}"
    
    if kubectl config current-context | grep -q "kind"; then
        say "Loading image into kind cluster..."
        kind load docker-image "${image_name}:${tag}"
    fi
}

# Function to create and wait for namespace
create_namespace() {
    local namespace="$1"
    say "Creating namespace $namespace..."
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    kubectl wait --for=condition=Ready namespace/"$namespace" --timeout=60s || \
    kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/"$namespace" --timeout=60s
}

# Function to apply Kubernetes manifests with error handling
apply_manifest() {
    local manifest_path="$1"
    local description="${2:-$(basename "$manifest_path")}"
    
    if [[ -f "$manifest_path" ]]; then
        say "Applying $description..."
        kubectl apply -f "$manifest_path"
    else
        say_error "Manifest not found: $manifest_path"
        return 1
    fi
}

# Function to validate all required manifests exist
validate_manifests() {
    local project_root="$1"
    local manifests=(
        "$project_root/config/namespace.yaml"
        "$project_root/config/auth/sa.yaml"
        "$project_root/config/auth/role.yaml"
        "$project_root/config/auth/rolebinding.yaml"
        "$project_root/config/broker.yaml"
        "$project_root/config/colors/serving/color-demo-service.yaml"
        "$project_root/config/colors/color-change-trigger.yaml"
        "$project_root/config/colors/k8s-deployment.yaml"
    )
    
    local missing_files=()
    for manifest in "${manifests[@]}"; do
        if [[ ! -f "$manifest" ]]; then
            missing_files+=("$manifest")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        say_error "Missing required manifest files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
    
    return 0
}

# Function to get Knative service URL
get_knative_service_url() {
    local service_name="$1"
    local namespace="$2"
    
    kubectl get ksvc "$service_name" -n "$namespace" -o jsonpath='{.status.url}' 2>/dev/null
}

# Function to setup port forwarding for standard K8s deployment
setup_port_forward() {
    local namespace="$1"
    local service_name="$2"
    local local_port="${3:-8080}"
    local service_port="${4:-80}"
    
    say "Setting up port forwarding..."
    # Kill any existing port forwards
    pkill -f "kubectl port-forward.*${service_name}" || true
    
    # Start port forwarding in background
    nohup kubectl port-forward -n "$namespace" service/"$service_name" "${local_port}:${service_port}" > port-forward.log 2>&1 &
    local port_forward_pid=$!
    
    say_success "Port forwarding started (PID: $port_forward_pid)"
    echo "🌐 Application URL: http://localhost:${local_port}"
}

# Function to wait for application to be ready
wait_for_application() {
    local url="$1"
    local timeout="${2:-30}"
    local health_endpoint="${url}/cloudevents/health"
    
    say "Waiting for application to be ready..."
    for i in $(seq 1 $timeout); do
        if curl -s "$health_endpoint" >/dev/null 2>&1; then
            say_success "Application is ready!"
            return 0
        fi
        if [ $i -eq $timeout ]; then
            say_error "Application failed to start within timeout"
            return 1
        fi
        sleep 2
    done
}

# Function to run a test with output validation
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"

    echo -n "Testing $test_name... "

    if result=$(eval "$command" 2>/dev/null); then
        if [[ -z "$expected_pattern" ]] || echo "$result" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}✅ PASS${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (unexpected response)"
            echo "  Expected pattern: $expected_pattern"
            echo "  Got: $result"
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL${NC} (request failed)"
        return 1
    fi
}

# Function to send CloudEvent
send_cloud_event() {
    local url="$1"
    local color="$2"
    local source="$3"
    local message="$4"

    curl -s -X POST "$url/cloudevents" \
        -H "Content-Type: application/json" \
        -H "ce-id: test-$(date +%s)-$(shuf -i 1000-9999 -n 1)" \
        -H "ce-type: com.example.color.change" \
        -H "ce-source: $source" \
        -H "ce-specversion: 1.0" \
        -H "ce-time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        -d "{\"color\": \"$color\", \"message\": \"$message\"}"
}
