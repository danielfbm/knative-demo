#!/bin/bash

# Comprehensive Test Suite for Knative Color Demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
BASE_URL="http://localhost:8080"
TIMEOUT=5

echo -e "${BLUE}🧪 Knative Color Demo - Test Suite${NC}"
echo "=================================="

# Function to run a test
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
    local color="$1"
    local source="$2"
    local message="$3"

    curl -s -X POST "$BASE_URL/cloudevents" \
        -H "Content-Type: application/json" \
        -H "ce-id: test-$(date +%s)-$(shuf -i 1000-9999 -n 1)" \
        -H "ce-type: com.example.color.change" \
        -H "ce-source: $source" \
        -H "ce-specversion: 1.0" \
        -H "ce-time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        -d "{\"color\": \"$color\", \"message\": \"$message\"}"
}

# Wait for application to be ready
echo "⏳ Waiting for application to be ready..."
for i in {1..30}; do
    if curl -s "$BASE_URL/cloudevents/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Application is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Application failed to start within timeout${NC}"
        exit 1
    fi
    sleep 2
done

echo ""
echo "🏁 Running Tests..."
echo "=================="

# Test 1: Health Check
run_test "Health Check" \
    "curl -s $BASE_URL/cloudevents/health" \
    "healthy"

# Test 2: Available Colors
run_test "Available Colors API" \
    "curl -s $BASE_URL/api/colors/available" \
    "RED"

# Test 3: Current Color (initial)
run_test "Current Color API" \
    "curl -s $BASE_URL/api/colors/current" \
    "color"

# Test 4: Color History
run_test "Color History API" \
    "curl -s $BASE_URL/api/colors/history" \
    "\[\]|\["

# Test 5: Events API
run_test "Events API" \
    "curl -s $BASE_URL/api/events" \
    "\[\]|\["

# Test 6: Web UI
run_test "Web UI" \
    "curl -s $BASE_URL/" \
    "Knative Color Demo"

echo ""
echo "🎨 Testing CloudEvents Functionality..."
echo "====================================="

# Test 7: Send RED CloudEvent
echo -n "Sending RED color event... "
if send_cloud_event "RED" "test-suite" "Testing RED color"; then
    echo -e "${GREEN}✅ Sent${NC}"
    sleep 2

    # Verify color changed
    run_test "Verify RED Color Change" \
        "curl -s $BASE_URL/api/colors/current" \
        "RED"
else
    echo -e "${RED}❌ Failed to send${NC}"
fi

# Test 8: Send BLUE CloudEvent
echo -n "Sending BLUE color event... "
if send_cloud_event "BLUE" "test-suite" "Testing BLUE color"; then
    echo -e "${GREEN}✅ Sent${NC}"
    sleep 2

    # Verify color changed
    run_test "Verify BLUE Color Change" \
        "curl -s $BASE_URL/api/colors/current" \
        "BLUE"
else
    echo -e "${RED}❌ Failed to send${NC}"
fi

# Test 9: Send GREEN CloudEvent
echo -n "Sending GREEN color event... "
if send_cloud_event "GREEN" "test-suite" "Testing GREEN color"; then
    echo -e "${GREEN}✅ Sent${NC}"
    sleep 2

    # Verify color changed
    run_test "Verify GREEN Color Change" \
        "curl -s $BASE_URL/api/colors/current" \
        "GREEN"
else
    echo -e "${RED}❌ Failed to send${NC}"
fi

# Test 10: Verify Events Were Recorded
run_test "Verify Events Recorded" \
    "curl -s $BASE_URL/api/events | jq length" \
    "[1-9]"

# Test 11: Verify Color History
run_test "Verify Color History" \
    "curl -s $BASE_URL/api/colors/history | jq length" \
    "[1-9]"

echo ""
echo "🔧 Testing Manual Color Setting..."
echo "================================="

# Test 12: Manual Color Setting
echo -n "Setting YELLOW manually... "
if curl -s -X POST "$BASE_URL/api/colors/set" \
    -H "Content-Type: application/json" \
    -d '{"color": "YELLOW", "source": "test-suite"}' >/dev/null; then
    echo -e "${GREEN}✅ Sent${NC}"
    sleep 2

    # Verify color changed
    run_test "Verify YELLOW Manual Change" \
        "curl -s $BASE_URL/api/colors/current" \
        "YELLOW"
else
    echo -e "${RED}❌ Failed to set${NC}"
fi

echo ""
echo "📊 Test Summary..."
echo "================"

# Get final state
echo "📋 Final Application State:"
echo -n "  Current Color: "
CURRENT_COLOR=$(curl -s "$BASE_URL/api/colors/current" | jq -r '.color // "UNKNOWN"')
echo -e "${GREEN}$CURRENT_COLOR${NC}"

echo -n "  Total Events: "
EVENT_COUNT=$(curl -s "$BASE_URL/api/events" | jq '. | length // 0')
echo -e "${BLUE}$EVENT_COUNT${NC}"

echo -n "  Color Changes: "
HISTORY_COUNT=$(curl -s "$BASE_URL/api/colors/history" | jq '. | length // 0')
echo -e "${BLUE}$HISTORY_COUNT${NC}"

echo ""
echo -e "${GREEN}🎉 Test Suite Complete!${NC}"
echo ""
echo "🌐 Application is accessible at: $BASE_URL"
echo "📱 Open in browser to see the web interface"
echo ""
echo "🔧 Additional manual tests:"
echo "  - Open $BASE_URL in a web browser"
echo "  - Try the manual color picker"
echo "  - Watch the real-time updates"
echo "  - Check the timeline visualization"
