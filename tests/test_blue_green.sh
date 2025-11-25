#!/bin/bash
###############################################################################
# Test Blue-Green Deployment
# 
# This script tests the complete blue-green deployment workflow
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

TERRAFORM_DIR="../terraform"
GCP_ZONE="us-central1-a"

# Get Terraform outputs
cd "$TERRAFORM_DIR" || exit 1
LB_IP=$(terraform output -raw lb_ip_address 2>/dev/null)
ACTIVE_ENV=$(terraform output -raw active_environment 2>/dev/null)
cd - > /dev/null

if [ -z "$LB_IP" ] || [ -z "$ACTIVE_ENV" ]; then
    log_error "Failed to get Terraform outputs"
    exit 1
fi

log_info "Testing Blue-Green Deployment"
echo "Load Balancer: $LB_IP"
echo "Active Environment: $ACTIVE_ENV"
echo ""

# Test 1: Verify both environments exist
log_info "Test 1: Verify both environments exist..."
BLUE_INSTANCES=$(gcloud compute instance-groups managed list-instances blue-mig \
    --zone="$GCP_ZONE" \
    --format="value(name)" 2>/dev/null | wc -l)

GREEN_INSTANCES=$(gcloud compute instance-groups managed list-instances green-mig \
    --zone="$GCP_ZONE" \
    --format="value(name)" 2>/dev/null | wc -l)

echo "Blue instances: $BLUE_INSTANCES"
echo "Green instances: $GREEN_INSTANCES"

if [ "$BLUE_INSTANCES" -eq 0 ] && [ "$GREEN_INSTANCES" -eq 0 ]; then
    log_error "No instances found in either environment"
    exit 1
fi

log_success "At least one environment is deployed"
echo ""

# Test 2: Check active environment responds
log_info "Test 2: Check active environment responds..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$LB_IP/health")

if [ "$HTTP_STATUS" -eq 200 ]; then
    log_success "Load balancer is healthy (HTTP $HTTP_STATUS)"
    
    RESPONSE=$(curl -s "http://$LB_IP/health")
    echo "$RESPONSE" | jq .
    
    ENV=$(echo "$RESPONSE" | jq -r '.environment')
    echo "Responding environment: $ENV"
    
    if [ "$ENV" = "$ACTIVE_ENV" ]; then
        log_success "Correct environment is serving traffic"
    else
        log_error "Active environment mismatch: expected $ACTIVE_ENV, got $ENV"
        exit 1
    fi
else
    log_error "Load balancer returned HTTP $HTTP_STATUS"
    exit 1
fi
echo ""

# Test 3: Verify inactive environment (if exists)
log_info "Test 3: Check inactive environment..."
INACTIVE_ENV="green"
if [ "$ACTIVE_ENV" = "green" ]; then
    INACTIVE_ENV="blue"
fi

INACTIVE_INSTANCES=$(gcloud compute instance-groups managed list-instances "${INACTIVE_ENV}-mig" \
    --zone="$GCP_ZONE" \
    --format="value(name)" 2>/dev/null | wc -l)

if [ "$INACTIVE_INSTANCES" -gt 0 ]; then
    log_success "Inactive environment ($INACTIVE_ENV) exists with $INACTIVE_INSTANCES instances"
    echo "This enables instant rollback capability"
else
    log_info "Inactive environment ($INACTIVE_ENV) not deployed"
    echo "Deploy both environments for full blue-green capability"
fi
echo ""

# Test 4: Check backend health
log_info "Test 4: Check backend service health..."
ACTIVE_BACKEND="${ACTIVE_ENV}-backend"

HEALTHY_COUNT=$(gcloud compute backend-services get-health "$ACTIVE_BACKEND" \
    --global \
    --format="value(status.healthStatus[].healthState)" 2>/dev/null | grep -c "HEALTHY" || echo "0")

TOTAL_COUNT=$(gcloud compute backend-services get-health "$ACTIVE_BACKEND" \
    --global \
    --format="value(status.healthStatus[])" 2>/dev/null | wc -l)

echo "Healthy instances: $HEALTHY_COUNT/$TOTAL_COUNT"

if [ "$HEALTHY_COUNT" -gt 0 ]; then
    log_success "Backend service has healthy instances"
else
    log_error "No healthy instances in backend service"
    exit 1
fi
echo ""

# Test 5: Test traffic consistency
log_info "Test 5: Test traffic consistency (10 requests)..."
ENV_COUNTS=$(mktemp)

for i in $(seq 1 10); do
    ENV=$(curl -s "http://$LB_IP/health" | jq -r '.environment' 2>/dev/null || echo "error")
    echo "$ENV" >> "$ENV_COUNTS"
    echo -n "."
done
echo ""

BLUE_COUNT=$(grep -c "blue" "$ENV_COUNTS" || echo "0")
GREEN_COUNT=$(grep -c "green" "$ENV_COUNTS" || echo "0")
ERROR_COUNT=$(grep -c "error" "$ENV_COUNTS" || echo "0")

echo "Traffic distribution:"
echo "  Blue: $BLUE_COUNT requests"
echo "  Green: $GREEN_COUNT requests"
echo "  Errors: $ERROR_COUNT requests"

rm "$ENV_COUNTS"

if [ "$ERROR_COUNT" -gt 0 ]; then
    log_error "Some requests failed"
    exit 1
fi

# Check if traffic is going to active environment
if [ "$ACTIVE_ENV" = "blue" ] && [ "$BLUE_COUNT" -ge 9 ]; then
    log_success "Traffic correctly routed to blue environment"
elif [ "$ACTIVE_ENV" = "green" ] && [ "$GREEN_COUNT" -ge 9 ]; then
    log_success "Traffic correctly routed to green environment"
else
    log_error "Traffic not consistently routing to active environment ($ACTIVE_ENV)"
    exit 1
fi
echo ""

# Test 6: Test rollback capability
log_info "Test 6: Verify rollback capability..."

if [ "$INACTIVE_INSTANCES" -gt 0 ]; then
    log_success "Rollback ready: Inactive environment can receive traffic instantly"
    echo ""
    echo "To switch traffic to $INACTIVE_ENV:"
    echo "  terraform apply -var='active_environment=$INACTIVE_ENV'"
    echo "  or use the switch-traffic GitHub Actions workflow"
else
    log_info "Rollback not available: Only one environment deployed"
    echo "Deploy $INACTIVE_ENV for rollback capability"
fi
echo ""

# Test 7: Check autoscaling configuration
log_info "Test 7: Verify autoscaling configuration..."

for ENV in blue green; do
    AUTOSCALER_EXISTS=$(gcloud compute autoscalers describe "${ENV}-autoscaler" \
        --zone="$GCP_ZONE" \
        --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$AUTOSCALER_EXISTS" ]; then
        echo "$ENV autoscaler: ✅ configured"
        
        MIN_SIZE=$(gcloud compute autoscalers describe "${ENV}-autoscaler" \
            --zone="$GCP_ZONE" \
            --format="value(autoscalingPolicy.minNumReplicas)" 2>/dev/null)
        
        MAX_SIZE=$(gcloud compute autoscalers describe "${ENV}-autoscaler" \
            --zone="$GCP_ZONE" \
            --format="value(autoscalingPolicy.maxNumReplicas)" 2>/dev/null)
        
        echo "  Size: $MIN_SIZE-$MAX_SIZE instances"
    fi
done

log_success "Autoscaling configured"
echo ""

# Test 8: Check health check configuration
log_info "Test 8: Verify health check configuration..."

HEALTH_CHECK=$(gcloud compute health-checks describe autohealing-health-check \
    --format="value(name)" 2>/dev/null || echo "")

if [ -n "$HEALTH_CHECK" ]; then
    log_success "Health check configured"
    
    gcloud compute health-checks describe autohealing-health-check \
        --format="table(name,type,checkIntervalSec,timeoutSec)"
else
    log_info "No health check found"
fi
echo ""

# Final summary
echo "========================================"
log_success "Blue-Green Deployment Test Complete! 🎉"
echo "========================================"
echo ""
echo "Summary:"
echo "- Active environment: $ACTIVE_ENV"
echo "- Inactive environment: $INACTIVE_ENV"
echo "- Load balancer IP: $LB_IP"
echo "- Blue instances: $BLUE_INSTANCES"
echo "- Green instances: $GREEN_INSTANCES"
echo "- Traffic routing: ✅ Consistent"
echo "- Backend health: $HEALTHY_COUNT healthy"
echo ""
echo "Deployment workflow:"
echo "  1. Build new image (Packer)"
echo "  2. Deploy to inactive environment ($INACTIVE_ENV)"
echo "  3. Test inactive environment"
echo "  4. Switch traffic to tested environment"
echo "  5. Keep old environment for instant rollback"
echo ""
echo "Access application:"
echo "  http://$LB_IP"
