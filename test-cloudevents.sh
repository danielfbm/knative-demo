#!/bin/bash

# Test script for CloudEvents endpoint
echo "Testing CloudEvents endpoint..."

# Start the application in the background
echo "Starting Spring Boot application..."
java -jar target/knative-color-demo-0.0.1-SNAPSHOT.jar &
APP_PID=$!

# Wait for the application to start
echo "Waiting for application to start..."
sleep 10

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8081/cloudevents/health | jq .

# Test CloudEvent reception with color change
echo "Testing color change CloudEvent..."
curl -X POST http://localhost:8081/cloudevents \
  -H "Content-Type: application/json" \
  -H "ce-id: test-event-$(date +%s)" \
  -H "ce-type: com.example.color.change" \
  -H "ce-source: test-script" \
  -H "ce-specversion: 1.0" \
  -H "ce-time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -d '{"color": "RED", "message": "Testing color change from script"}'

echo ""

# Check current color
echo "Checking current color..."
curl -s http://localhost:8081/api/colors/current | jq .

echo ""

# Check events
echo "Checking received events..."
curl -s http://localhost:8081/api/events | jq .

# Kill the application
echo "Stopping application..."
kill $APP_PID

echo "Test completed!"
