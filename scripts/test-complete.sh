#!/bin/bash

# Comprehensive Test Suite for Knative Color Demo
set -e

# Source the common library
source "$(dirname "$0")/library.sh"

# Test configuration
BASE_URL="${1:-http://localhost:8080}"
TIMEOUT=5

echo -e "${BLUE}🧪 Knative Color Demo - Test Suite${NC}"
echo "=================================="

# Wait for application to be ready
wait_for_application "$BASE_URL" 30

echo ""
echo -e "${BLUE}🏁 Running Tests...${NC}"
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
echo -e "${BLUE}🎨 Testing CloudEvents Functionality...${NC}"
echo "====================================="

# Test 7: Send RED CloudEvent
echo -n "Sending RED color event... "
if send_cloud_event "$BASE_URL" "RED" "test-suite" "Testing RED color"; then
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
if send_cloud_event "$BASE_URL" "BLUE" "test-suite" "Testing BLUE color"; then
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
if send_cloud_event "$BASE_URL" "GREEN" "test-suite" "Testing GREEN color"; then
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
echo -e "${BLUE}🔧 Testing Manual Color Setting...${NC}"
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
echo -e "${BLUE}📊 Test Summary...${NC}"
echo "================"

# Get final state
echo -e "${BLUE}📋 Final Application State:${NC}"
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
say_success "Test Suite Complete!"
echo ""
echo -e "${GREEN}🌐 Application is accessible at: $BASE_URL${NC}"
echo -e "${BLUE}📱 Open in browser to see the web interface${NC}"
echo ""
echo -e "${BLUE}🔧 Additional manual tests:${NC}"
echo "  - Open $BASE_URL in a web browser"
echo "  - Try the manual color picker"
echo "  - Watch the real-time updates"
echo "  - Check the timeline visualization"
