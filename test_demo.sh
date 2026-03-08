#!/bin/bash
# ============================================================================
# OneWay API Test Suite - Hackathon Demo
# ============================================================================
# Run: chmod +x test_demo.sh && ./test_demo.sh
# ============================================================================

BASE_URL="${1:-http://localhost:8000}"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  OneWay API Test Suite"
echo "  Target: $BASE_URL"
echo "=============================================="
echo ""

# Track results
PASSED=0
FAILED=0

test_endpoint() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    
    echo -n "Testing: $name... "
    
    if [ "$method" == "GET" ]; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
    else
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    if [[ "$http_code" =~ ^2 ]]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        ((FAILED++))
    fi
}

# ============================================================================
# 1. HEALTH CHECK
# ============================================================================
echo ""
echo -e "${YELLOW}[1/7] HEALTH CHECK${NC}"
echo "----------------------------------------------"
test_endpoint "Health endpoint" "GET" "/health" "" ""
test_endpoint "Root endpoint" "GET" "/" "" ""

# ============================================================================
# 2. AUTHENTICATION
# ============================================================================
echo ""
echo -e "${YELLOW}[2/7] AUTHENTICATION${NC}"
echo "----------------------------------------------"
test_endpoint "Login with Consumer ID (DEMO123)" "POST" "/api/auth/login" \
    '{"identifier": "DEMO123", "identifierType": "challan"}' "user"

test_endpoint "Login with Vehicle Number" "POST" "/api/auth/login" \
    '{"identifier": "KL01AB1234", "identifierType": "vehicle"}' "user"

test_endpoint "Login with DL Number" "POST" "/api/auth/login" \
    '{"identifier": "DL-1234567890", "identifierType": "dl"}' "user"

# Test that invalid login is rejected (404 is expected success here)
echo -n "Testing: Login with invalid ID (expect 404)... "
http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"identifier": "INVALID999", "identifierType": "challan"}')
if [ "$http_code" == "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP 404 - correctly rejected)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $http_code - expected 404)"
    ((FAILED++))
fi

# ============================================================================
# 3. UTILITIES
# ============================================================================
echo ""
echo -e "${YELLOW}[3/7] UTILITIES${NC}"
echo "----------------------------------------------"
test_endpoint "Get available services" "GET" "/api/utilities/services" "" "services"

# ============================================================================
# 4. PROFILES
# ============================================================================
echo ""
echo -e "${YELLOW}[4/7] PROFILES${NC}"
echo "----------------------------------------------"
test_endpoint "Get all profiles" "GET" "/api/profiles/" "" ""

# Create a test profile
PROFILE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/profiles/" \
    -H "Content-Type: application/json" \
    -d '{"name": "Test Home"}')
PROFILE_ID=$(echo $PROFILE_RESPONSE | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ ! -z "$PROFILE_ID" ]; then
    echo -e "   Created test profile: $PROFILE_ID"
    
    test_endpoint "Get specific profile" "GET" "/api/profiles/$PROFILE_ID" "" ""
    
    test_endpoint "Add electricity account" "POST" "/api/profiles/$PROFILE_ID/accounts" \
        '{"service_type": "kseb", "consumer_id": "TEST123456", "label": "Home Power"}' ""
    
    test_endpoint "Get profile accounts" "GET" "/api/profiles/$PROFILE_ID/accounts" "" ""
    
    # Cleanup
    curl -s -X DELETE "$BASE_URL/api/profiles/$PROFILE_ID" > /dev/null
    echo "   Cleaned up test profile"
else
    echo -e "${RED}Failed to create test profile${NC}"
    ((FAILED++))
fi

# ============================================================================
# 5. SENTINEL (Traffic Violations)
# ============================================================================
echo ""
echo -e "${YELLOW}[5/7] SENTINEL - Traffic Violations${NC}"
echo "----------------------------------------------"
test_endpoint "Get all violation reports" "GET" "/api/sentinel/reports" "" ""
test_endpoint "Get vehicle registry" "GET" "/api/sentinel/registry" "" ""

# ============================================================================
# 6. DISASTER SENTINEL
# ============================================================================
echo ""
echo -e "${YELLOW}[6/7] DISASTER SENTINEL${NC}"
echo "----------------------------------------------"
test_endpoint "Get all incidents" "GET" "/api/disaster/incidents" "" ""
test_endpoint "Get active incidents only" "GET" "/api/disaster/incidents?active_only=true" "" ""
test_endpoint "Get incident stats" "GET" "/api/disaster/stats" "" ""
test_endpoint "Get authorities" "GET" "/api/disaster/authorities" "" ""

# ============================================================================
# 7. RESPONSE TIME TEST
# ============================================================================
echo ""
echo -e "${YELLOW}[7/7] RESPONSE TIME TEST${NC}"
echo "----------------------------------------------"

measure_time() {
    local name="$1"
    local endpoint="$2"
    local start=$(date +%s%N)
    curl -s "$BASE_URL$endpoint" > /dev/null
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))
    
    if [ $duration -lt 500 ]; then
        echo -e "$name: ${GREEN}${duration}ms${NC}"
    elif [ $duration -lt 2000 ]; then
        echo -e "$name: ${YELLOW}${duration}ms${NC}"
    else
        echo -e "$name: ${RED}${duration}ms${NC}"
    fi
}

measure_time "Health check" "/health"
measure_time "Services list" "/api/utilities/services"
measure_time "Profiles list" "/api/profiles/"
measure_time "Disaster stats" "/api/disaster/stats"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "=============================================="
echo "  TEST SUMMARY"
echo "=============================================="
echo -e "  Passed: ${GREEN}$PASSED${NC}"
echo -e "  Failed: ${RED}$FAILED${NC}"
echo "=============================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Ready for demo.${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. Check the output above.${NC}"
    exit 1
fi
