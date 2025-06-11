#!/bin/bash

# Source the common library
source "$(dirname "$0")/library.sh"

# Get project root directory
PROJECT_ROOT=$(get_project_root)

# Configuration
API_ENDPOINT="${1:-http://localhost:8080}"
START="${2:-false}"

echo -e "${BLUE}-- API_ENDPOINT: $API_ENDPOINT${NC}"
echo -e "${BLUE}-- START: $START${NC}"

# Test script for CloudEvents endpoint
say "Testing CloudEvents endpoint..."

if [ "$START" = true ]; then
    # Start the application in the background
    say "Starting Spring Boot application..."
    java -jar "$PROJECT_ROOT/target/knative-color-demo-0.0.1-SNAPSHOT.jar" &
    APP_PID=$!

    # Wait for the application to start
    wait_for_application "$API_ENDPOINT" 15
fi

# Test health endpoint
say "Testing health endpoint..."
curl -s "$API_ENDPOINT/cloudevents/health" | jq . || echo "Failed to get health status"

# Test CloudEvent reception with color change
say "Testing color change CloudEvent..."
send_cloud_event "$API_ENDPOINT" "RED" "test-script" "Testing color change from script"

echo ""

say "Testing another cloud event type"
curl -X POST "$API_ENDPOINT/cloudevents" \
  -H "Content-Type: application/json" \
  -H "ce-id: test-event-$(date +%s)" \
  -H "ce-type: com.example.another-event" \
  -H "ce-source: test-script" \
  -H "ce-specversion: 1.0" \
  -H "ce-time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -d '{"message": "Hello world"}'

# Check current color
say "Checking current color..."
curl -s "$API_ENDPOINT/api/colors/current" | jq . || echo "Failed to get current color"

echo ""

# Check events
say "Checking received events..."
curl -s "$API_ENDPOINT/api/events" | jq . || echo "Failed to get events"

if [ "$START" = true ] && [ -n "$APP_PID" ]; then
    # Kill the application
    say "Stopping application..."
    kill "$APP_PID" 2>/dev/null || true
fi

say_success "Test completed!"
