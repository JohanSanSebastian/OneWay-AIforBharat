# ============================================================================
# OneWay API - Individual Test Commands
# ============================================================================
# Copy and paste these commands to test specific endpoints
# ============================================================================

# BASE URL (change if needed)
# Local: http://localhost:8000
# Render: https://oneway-backend-fz6l.onrender.com

# ============================================================================
# HEALTH & STATUS
# ============================================================================

# Health check
curl -s http://localhost:8000/health | jq

# Root endpoint
curl -s http://localhost:8000/ | jq

# ============================================================================
# AUTHENTICATION
# ============================================================================

# Login with Consumer ID (Demo user)
curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "DEMO123", "identifierType": "challan"}' | jq

# Login with Vehicle Number
curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "KL01AB1234", "identifierType": "vehicle"}' | jq

# Login with DL Number
curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "DL-1234567890", "identifierType": "dl"}' | jq

# Register new user
curl -s -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "phone": "9876543210",
    "consumer_id": "TEST001",
    "vehicle_number": "KL99ZZ9999",
    "dl_number": "DL-9999999999"
  }' | jq

# ============================================================================
# UTILITIES
# ============================================================================

# Get available services
curl -s http://localhost:8000/api/utilities/services | jq

# Fetch electricity bill (requires AWS Bedrock)
curl -s -X POST http://localhost:8000/api/utilities/fetch-bill \
  -H "Content-Type: application/json" \
  -d '{"service_type": "electricity", "consumer_id": "1234567890"}' | jq

# Fetch water bill
curl -s -X POST http://localhost:8000/api/utilities/fetch-bill \
  -H "Content-Type: application/json" \
  -d '{"service_type": "water", "consumer_id": "WTR987654"}' | jq

# Fetch e-Challan
curl -s -X POST http://localhost:8000/api/utilities/fetch-bill \
  -H "Content-Type: application/json" \
  -d '{"service_type": "echallan", "consumer_id": "KL01AB1234", "number_plate": "KL01AB1234"}' | jq

# ============================================================================
# PROFILES
# ============================================================================

# Get all profiles
curl -s http://localhost:8000/api/profiles/ | jq

# Create a new profile
curl -s -X POST http://localhost:8000/api/profiles/ \
  -H "Content-Type: application/json" \
  -d '{"name": "My Home"}' | jq

# Get specific profile (replace PROFILE_ID)
curl -s http://localhost:8000/api/profiles/PROFILE_ID | jq

# Add account to profile (replace PROFILE_ID)
curl -s -X POST http://localhost:8000/api/profiles/PROFILE_ID/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "service_type": "electricity",
    "consumer_id": "1234567890",
    "label": "Home Electricity"
  }' | jq

# Get profile accounts
curl -s http://localhost:8000/api/profiles/PROFILE_ID/accounts | jq

# Delete profile
curl -s -X DELETE http://localhost:8000/api/profiles/PROFILE_ID | jq

# ============================================================================
# SENTINEL - Traffic Violations
# ============================================================================

# Get all violation reports
curl -s http://localhost:8000/api/sentinel/reports | jq

# Get vehicle registry
curl -s http://localhost:8000/api/sentinel/registry | jq

# Analyze violation image (base64 encoded)
# First, encode your image: base64 -i violation.jpg | tr -d '\n' > violation_b64.txt
# Then use it:
curl -s -X POST http://localhost:8000/api/sentinel/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": "YOUR_BASE64_IMAGE_HERE",
    "device_latitude": 10.0159,
    "device_longitude": 76.3419
  }' | jq

# Add vehicle to registry
curl -s -X POST http://localhost:8000/api/sentinel/registry \
  -H "Content-Type: application/json" \
  -d '{
    "plate_number": "KL01AB1234",
    "owner_name": "John Doe",
    "owner_phone": "9876543210"
  }' | jq

# ============================================================================
# DISASTER SENTINEL
# ============================================================================

# Get active incidents
curl -s http://localhost:8000/api/disaster/incidents/active | jq

# Get all incidents
curl -s http://localhost:8000/api/disaster/incidents | jq

# Get incident statistics
curl -s http://localhost:8000/api/disaster/stats | jq

# Get Kerala districts
curl -s http://localhost:8000/api/disaster/districts | jq

# Get authorities directory
curl -s http://localhost:8000/api/disaster/authorities | jq

# Analyze disaster image (base64 encoded)
curl -s -X POST http://localhost:8000/api/disaster/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": "YOUR_BASE64_IMAGE_HERE",
    "device_latitude": 10.0159,
    "device_longitude": 76.3419
  }' | jq

# Get incidents by district
curl -s http://localhost:8000/api/disaster/incidents/district/Ernakulam | jq

# ============================================================================
# HELPER: Encode image to base64
# ============================================================================
# macOS:
# base64 -i path/to/image.jpg | tr -d '\n' | pbcopy
# 
# Linux:
# base64 -w 0 path/to/image.jpg | xclip -selection clipboard
# ============================================================================
