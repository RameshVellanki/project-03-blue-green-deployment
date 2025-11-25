#!/bin/bash
###############################################################################
# Health Check Script
# 
# Used by load balancer to determine instance health
###############################################################################

HEALTH_ENDPOINT="http://localhost:8080/api/health"
TIMEOUT=5

# Perform health check
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$HEALTH_ENDPOINT" 2>/dev/null)

# Check response
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Healthy (HTTP $HTTP_STATUS)"
    exit 0
else
    echo "Unhealthy (HTTP $HTTP_STATUS)"
    exit 1
fi
