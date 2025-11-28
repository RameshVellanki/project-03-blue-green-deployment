# Project 3: Automated Blue-Green Deployment 🔵🟢

A production-ready GCP project implementing **fully automated** zero-downtime blue-green deployments with auto-toggle, auto-scaling, and one-click rollback. Uses custom Packer images, managed instance groups, and intelligent traffic switching.

## 🏗️ Architecture

```
                         ┌─────────────────────┐
                         │   Global HTTP       │
                         │   Load Balancer     │
                         │  (Auto-Switching)   │
                         └──────────┬──────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │     Backend Service           │
                    │  (Intelligent Routing)        │
                    └───────┬───────────────┬───────┘
                            │               │
                    ┌───────▼──────┐ ┌─────▼────────┐
                    │  BLUE MIG    │ │  GREEN MIG   │
                    │              │ │              │
                    │ - 2 VMs      │ │ - 0 VMs      │
                    │ - Version A  │ │ - Standby    │
                    │ - Active 🔵  │ │ - Ready 🟢   │
                    └──────────────┘ └──────────────┘
                            ▲               ▲
                            │               │
                    Auto-scales to 0    Auto-scales to 2
                    when inactive       when deploying

Custom Image (Systemd Service):
┌─────────────────────────────────────────┐
│  Ubuntu 22.04 + Node.js 18 + App        │
│  ✓ Pre-installed dependencies           │
│  ✓ Webapp service auto-starts on boot   │
│  ✓ Health checks on :8080/api/health    │
│  ✓ Immutable infrastructure             │
└─────────────────────────────────────────┘
```

## ✨ Key Features

- 🚀 **Fully Automated** - Zero manual intervention required
- 🔄 **Auto-Toggle** - Automatically switches between blue/green on each deploy
- 📉 **Auto-Scaling** - Active environment: 2 instances, Standby: 0 instances
- ⚡ **90-Second Warmup** - Health check validation before traffic switch
- ↩️ **One-Click Rollback** - Instant revert to previous environment
- 🎯 **Environment Detection** - Intelligently detects current state
- 🛡️ **Health-Based Routing** - Only switches when new environment is healthy
- 🔧 **No Configuration Needed** - Just run deploy workflow

## 📋 Prerequisites

- GCP Project with billing enabled
- Terraform >= 1.6 installed
- Packer >= 1.9 installed
- `gcloud` CLI configured
- GitHub repository
- GitHub Secrets configured (`GCP_SA_KEY`)
- Understanding of load balancers and MIGs

## 🔧 Tech Stack

- **IaC**: Terraform
- **Image Building**: Packer (HCL2)
- **CI/CD**: GitHub Actions
- **Application**: Node.js + Express
- **Compute**: Managed Instance Groups (2 per environment)
- **Load Balancing**: Global HTTP Load Balancer
- **Networking**: Backend services, URL maps, forwarding rules
- **IAM**: Custom Service Account

## 🚀 Quick Start

### Prerequisites
- GCP Project with billing enabled
- GitHub repository with secrets configured:
  - `GCP_PROJECT_ID`: Your GCP project ID
  - `GCP_SA_KEY`: Service account JSON key

### Step 1: Build Custom Image
1. Go to **Actions** → Run **Build Image** workflow
2. Wait ~5-7 minutes for Packer to build image
3. Output: `webapp-blue-green-1-0-0-<timestamp>`

### Step 2: First Deployment (Blue)
1. Run **Deploy** workflow
2. System automatically:
   - Detects: "No active deployment"
   - Creates blue environment (2 instances)
   - Creates load balancer
   - Blue serves 100% traffic 🔵
3. Get load balancer IP from workflow output
4. Test: `curl http://<LB_IP>/api/health`

### Step 3: Second Deployment (Auto-Switch to Green)
1. Make code changes (optional)
2. Run **Build Image** workflow (new version)
3. Run **Deploy** workflow
4. System automatically:
   - Detects: "Blue is active"
   - Deploys to green (2 instances)
   - Waits 90 seconds for health checks
   - **Auto-switches traffic to green** 🟢
   - **Auto-scales blue to 0** 
5. Test: `curl http://<LB_IP>/api/version`
   - Returns: `"environment": "green"`

### Step 4: Third Deployment (Auto-Switch to Blue)
1. Run **Build Image** workflow (newer version)
2. Run **Deploy** workflow
3. System automatically:
   - Detects: "Green is active"
   - Deploys to blue (2 instances)
   - Waits 90 seconds for health checks
   - **Auto-switches traffic to blue** 🔵
   - **Auto-scales green to 0**
4. Continuous auto-toggle forever! 🔄

### Step 5: Rollback (If Needed)
1. Run **Rollback** workflow
2. System automatically:
   - Detects current active environment
   - Scales up previous environment (0→2)
   - Switches traffic instantly
   - Scales down current environment (2→0)
3. Rollback complete in ~30 seconds! ↩️

### Step 6: Cleanup
1. Run **Destroy** workflow
2. All resources deleted (cost: $0/month)

## 📁 Project Structure

```
project-03-blue-green-deployment/
├── .github/workflows/
│   ├── build-image.yml          # Build custom Packer image (~5-7 min)
│   ├── deploy.yml               # Auto blue-green toggle deploy (~4-6 min)
│   ├── rollback.yml             # One-click rollback (~30 sec)
│   └── destroy.yml              # Clean up all resources (~2-3 min)
├── packer/
│   ├── image.pkr.hcl            # Packer HCL2 template
│   └── scripts/
│       └── provision.sh         # Install Node.js, app, systemd service
├── terraform/
│   ├── main.tf                  # Provider and backend config
│   ├── variables.tf             # All input variables
│   ├── terraform.tfvars         # Variable values (git-ignored)
│   ├── load-balancer.tf         # LB, backend service, health checks
│   ├── blue-environment.tf      # Blue MIG, template, autoscaler, SA
│   ├── green-environment.tf     # Green MIG, template, autoscaler, SA
│   └── outputs.tf               # Deployment summary and test commands
├── scripts/app/
│   ├── server.js                # Express.js app with health endpoints
│   └── package.json             # Node.js dependencies
├── README.md                    # This file
├── USAGE.md                     # Quick reference guide
└── .gitignore
```

## 🎮 GitHub Actions Workflows

### 1. build-image.yml
**Purpose:** Build custom VM image with Packer  
**Trigger:** Manual (workflow_dispatch)  
**Duration:** ~5-7 minutes  
**Steps:**
1. Checkout code
2. Authenticate to GCP
3. Initialize Packer
4. Build image with provisioning script
5. Output: Image name (e.g., `webapp-blue-green-1-0-0-20251128041608`)

**Key Features:**
- Installs Node.js 18, app dependencies
- Creates systemd service for auto-start
- Configures health check endpoints
- Uses webapp image family for easy lookup

### 2. deploy.yml
**Purpose:** Automated blue-green toggle deployment  
**Trigger:** Manual (workflow_dispatch) with optional image input  
**Duration:** ~4-6 minutes  
**Steps:**
1. **Detect Target:** Check current active environment (blue/green/none)
2. **Deploy:** Create/update inactive environment with 2 instances
3. **Wait:** 90 seconds for health checks to pass
4. **Switch Traffic:** Update backend service to new environment
5. **Force Scale Down:** Scale old environment to 0 instances

**Intelligence:**
- First deploy → blue
- Blue active → deploy green, switch, scale blue to 0
- Green active → deploy blue, switch, scale green to 0
- Uses latest image from webapp family by default

### 3. rollback.yml
**Purpose:** Instant rollback to previous environment  
**Trigger:** Manual (workflow_dispatch)  
**Duration:** ~30 seconds  
**Steps:**
1. Detect current active environment
2. Scale up previous environment (0→2)
3. Switch traffic to previous environment
4. Scale down current environment (2→0)

**Safety:**
- Validates previous environment exists
- Checks health before switching
- Automatic scaling management

### 4. destroy.yml
**Purpose:** Delete all infrastructure  
**Trigger:** Manual (workflow_dispatch)  
**Duration:** ~2-3 minutes  
**Steps:**
1. Run `terraform destroy -auto-approve`
2. Deletes: MIGs, LB, backend service, health checks, SAs, IAM bindings

**Safety:** Requires manual workflow trigger

## 🔄 How Auto-Toggle Works

### Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│  DEPLOYMENT 1: Initial State (No existing deployment)       │
└─────────────────────────────────────────────────────────────┘
   Run: deploy workflow
   
   System detects: CURRENT = none
   Decision: TARGET = blue, FIRST = true
   
   Actions:
   ✓ Create blue MIG (2 instances)
   ✓ Create load balancer → blue
   ✓ Green not created (0 instances)
   
   Result: 🔵 Blue active (100% traffic), Green standby (0%)

┌─────────────────────────────────────────────────────────────┐
│  DEPLOYMENT 2: Blue → Green Switch                          │
└─────────────────────────────────────────────────────────────┘
   Run: deploy workflow (with new image)
   
   System detects: CURRENT = blue
   Decision: TARGET = green, FIRST = false
   
   Actions:
   ✓ Create green MIG (2 instances) [Blue still serving]
   ✓ Wait 90 seconds for green health checks
   ✓ Switch LB backend: blue → green
   ✓ Force scale down blue: 2 → 0 instances
   
   Result: 🟢 Green active (100% traffic), Blue standby (0%)

┌─────────────────────────────────────────────────────────────┐
│  DEPLOYMENT 3: Green → Blue Switch                          │
└─────────────────────────────────────────────────────────────┘
   Run: deploy workflow (with newer image)
   
   System detects: CURRENT = green
   Decision: TARGET = blue, FIRST = false
   
   Actions:
   ✓ Update blue MIG (2 instances) [Green still serving]
   ✓ Wait 90 seconds for blue health checks
   ✓ Switch LB backend: green → blue
   ✓ Force scale down green: 2 → 0 instances
   
   Result: 🔵 Blue active (100% traffic), Green standby (0%)

   ... continues toggling forever! 🔄
```

### Rollback Flow

```
┌─────────────────────────────────────────────────────────────┐
│  ROLLBACK: Instant revert to previous environment           │
└─────────────────────────────────────────────────────────────┘
   Run: rollback workflow
   
   System detects: CURRENT = green (example)
   Decision: TARGET = blue
   
   Actions:
   ✓ Scale up blue: 0 → 2 instances (~20 seconds)
   ✓ Wait for blue health checks
   ✓ Switch LB backend: green → blue
   ✓ Scale down green: 2 → 0 instances
   
   Result: ↩️ Rolled back to blue in ~30 seconds!
```

## 🔐 Security & IAM

**Service Accounts:**
- `webapp-blue-sa@<project>.iam.gserviceaccount.com` - For blue environment
- `webapp-green-sa@<project>.iam.gserviceaccount.com` - For green environment

**IAM Roles (Least Privilege):**
- `roles/logging.logWriter` - Write application logs
- `roles/monitoring.metricWriter` - Write custom metrics

**Firewall Rules:**
1. `allow-http-from-internet` - Allow port 80 from 0.0.0.0/0 to LB
2. `allow-health-check` - Allow port 8080 from Google health check IPs
3. `allow-lb-to-backends` - Allow port 8080 from LB to backends

**Network Security:**
- External IPs on instances (for debugging; can be removed in production)
- Load balancer is the only public entry point
- Backends only accessible via load balancer
- Health checks use dedicated port and path

**Best Practices Implemented:**
- ✅ Custom service accounts per environment
- ✅ Minimal IAM permissions
- ✅ Firewall rules with specific source ranges
- ✅ Health checks isolated from application traffic
- ✅ No SSH keys in metadata (use IAP for access)

## 🧪 Testing Your Deployment

### Quick Health Check
```bash
# Get load balancer IP from deploy workflow output
LB_IP="34.107.175.101"  # Replace with your IP

# Test health endpoint
curl http://$LB_IP/api/health

# Expected response:
# {"status":"healthy","environment":"blue","version":"..."}
```

### Verify Active Environment
```bash
# Check version endpoint
curl http://$LB_IP/api/version

# Returns environment and image version:
# {
#   "version": "webapp-blue-green-1-0-0-20251128041608",
#   "environment": "blue",
#   "instance": "blue-instance-xyz"
# }
```

### Load Testing
```bash
# Generate load to test autoscaling
for i in {1..100}; do
  curl http://$LB_IP/api/stress?duration=1000 &
done

# Watch autoscaler response
gcloud compute instance-groups managed describe blue-mig --zone=us-central1-a
```

### Test Complete Blue-Green Cycle
```bash
# 1. Deploy to blue (first time)
# Run: Deploy workflow
# Verify: curl http://$LB_IP/api/version → "environment": "blue"

# 2. Deploy to green (second time)  
# Run: Build Image + Deploy workflow
# Verify: curl http://$LB_IP/api/version → "environment": "green"
# Verify: Blue scaled to 0

# 3. Deploy to blue (third time)
# Run: Build Image + Deploy workflow  
# Verify: curl http://$LB_IP/api/version → "environment": "blue"
# Verify: Green scaled to 0

# 4. Rollback to green
# Run: Rollback workflow
# Verify: curl http://$LB_IP/api/version → "environment": "green"
# Verify: Blue scaled to 0
```

### Verify Zero Downtime
```bash
# Continuous requests during deployment
while true; do
  curl -s http://$LB_IP/api/health | jq -r '.environment'
  sleep 1
done

# Run deploy workflow in another terminal
# You should see smooth transition: blue → blue → green → green
# No errors or connection refused!
```

## 📊 Monitoring & Observability

### Key Metrics in GCP Console

**Load Balancer (Menu: Network Services → Load Balancing)**
- Request count and latency (p50, p95, p99)
- Error rate (4xx, 5xx responses)
- Backend latency
- Active backend service (blue-mig vs green-mig)

**Instance Groups (Menu: Compute Engine → Instance Groups)**
- Instance count per environment
- Health check status (% healthy)
- CPU utilization
- Autoscaling activity

**Logging (Menu: Logging → Logs Explorer)**
```
# View load balancer requests
resource.type="http_load_balancer"
httpRequest.requestUrl=~".*"

# View which environment served request
resource.type="http_load_balancer"
jsonPayload.statusDetails=~".*backend.*"

# View health check logs
resource.type="gce_instance"
labels.instance_name=~"(blue|green)-.*"
"health check"

# View webapp application logs
resource.type="gce_instance"  
logName="projects/<project>/logs/webapp"
```

### Quick Status Check Commands
```bash
# Current active environment
gcloud compute backend-services describe webapp-backend-service --global \
  --format="value(backends[0].group)"

# Instance counts
gcloud compute instance-groups managed describe blue-mig --zone=us-central1-a \
  --format="value(targetSize)"
gcloud compute instance-groups managed describe green-mig --zone=us-central1-a \
  --format="value(targetSize)"

# Health status
gcloud compute backend-services get-health webapp-backend-service --global
```

## 💰 Cost Estimate

**Active Deployment (One environment serving traffic):**
- Load Balancer (forwarding rule): $18/month
- Active MIG (2x e2-micro): $15/month  
- Standby MIG (0 instances): $0/month
- External IP: $4/month
- Image Storage: $0.50/month
- **Total: ~$37.50/month**

**During Deployment (Both environments temporarily):**
- Both MIGs running (4x e2-micro): $30/month
- Duration: ~2 minutes per deployment
- Additional cost: ~$0.04 per deployment

**Cost Optimization Tips:**
- ✅ Standby environment auto-scales to 0 (saves ~$15/month)
- ✅ Only runs 2 instances when active
- ✅ Use e2-micro (cheapest option)
- ✅ Delete old unused images
- ✅ Use preemptible VMs for dev/test (~70% discount)

**If you keep both environments running 24/7:** ~$52/month

## 🐛 Troubleshooting

### Health Checks Failing (Timeout)

**Symptoms:** Instances show "Timeout" in health check status

**Solutions:**
```bash
# 1. SSH into instance and check service
gcloud compute ssh <instance-name> --zone=us-central1-a
sudo systemctl status webapp.service

# 2. If service not running, check logs
sudo journalctl -u webapp.service -n 100

# 3. Manually start service
sudo systemctl start webapp.service

# 4. Test health endpoint locally
curl http://localhost:8080/api/health

# 5. Check firewall rules allow health checks
gcloud compute firewall-rules list --filter="name:allow-health-check"
```

**Common Causes:**
- Systemd service not starting automatically
- Port 8080 not listening
- Health check path incorrect
- Firewall blocking Google health check IPs (35.191.0.0/16, 130.211.0.0/22)

### Load Balancer Not Accessible

**Symptoms:** Cannot reach LB IP from internet

**Solutions:**
```bash
# 1. Get LB IP
gcloud compute forwarding-rules list

# 2. Check backend health
gcloud compute backend-services get-health webapp-backend-service --global

# 3. Verify firewall allows port 80
gcloud compute firewall-rules describe allow-http-from-internet

# 4. Test directly on instance external IP
curl http://<instance-external-ip>:8080/api/health
```

### Instances Not Scaling Down to 0

**Symptoms:** Blue/Green shows 1 instance instead of 0 after traffic switch

**Solutions:**
```bash
# Force scale down manually
gcloud compute instance-groups managed set-autoscaling blue-mig \
  --zone=us-central1-a --mode=off

gcloud compute instance-groups managed resize blue-mig \
  --zone=us-central1-a --size=0
```

**Note:** The deploy workflow now includes automatic force scale-down. This should not happen with the latest version.

### Image Build Fails

**Symptoms:** Packer build workflow fails

**Solutions:**
```bash
# 1. Check Packer logs in GitHub Actions

# 2. Verify GCP service account has permissions:
# - compute.images.create
# - compute.instances.create
# - compute.instances.delete

# 3. Test locally
cd packer
packer validate -var="project_id=your-project" image.pkr.hcl
packer build -var="project_id=your-project" image.pkr.hcl

# 4. Check if Compute Engine API is enabled
gcloud services enable compute.googleapis.com
```

### Terraform State Issues

**Symptoms:** Terraform errors about existing resources or state drift

**Solutions:**
```bash
# 1. Refresh state
cd terraform
terraform refresh

# 2. If severe drift, reimport resources
terraform import google_compute_instance_group_manager.blue_mig projects/<project>/zones/us-central1-a/instanceGroupManagers/blue-mig

# 3. Nuclear option: delete state and recreate
# WARNING: Only use if you understand the consequences
terraform destroy
rm -rf .terraform terraform.tfstate*
terraform init
```

### Deploy Workflow Detects Wrong Environment

**Symptoms:** Workflow says "Blue active" but you expected "Green"

**Solutions:**
```bash
# Check Terraform outputs
cd terraform
terraform output active_environment
terraform output blue_instance_count
terraform output green_instance_count

# Verify in GCP Console
gcloud compute instance-groups managed list
gcloud compute backend-services describe webapp-backend-service --global
```

## 🧹 Cleanup

### Option 1: Destroy Everything (Recommended)
```bash
# Run destroy workflow in GitHub Actions
# OR manually:
cd terraform
terraform destroy -auto-approve
```

**What gets deleted:**
- Both blue and green MIGs and instances
- Load balancer, backend service, URL map
- Forwarding rule and external IP
- Health checks and firewall rules
- Service accounts and IAM bindings

**What remains:**
- Custom images (manual deletion required)
- Terraform state in GCS bucket (if using remote state)

### Option 2: Scale Down to Save Costs
```bash
# Keep infrastructure but scale to 0
gcloud compute instance-groups managed resize blue-mig --zone=us-central1-a --size=0
gcloud compute instance-groups managed resize green-mig --zone=us-central1-a --size=0

# Cost: ~$22/month (LB + IPs, no compute)
```

### Option 3: Delete Old Images
```bash
# List all images
gcloud compute images list --filter="family:webapp" --format="table(name,creationTimestamp)"

# Delete old images (keep latest 3)
gcloud compute images delete webapp-blue-green-1-0-0-20251120010000 --quiet
```

### Verify Complete Cleanup
```bash
# Check for remaining resources
gcloud compute instance-groups managed list
gcloud compute forwarding-rules list  
gcloud compute backend-services list --global
gcloud compute images list --filter="family:webapp"

# Should all return empty
```

## 🎓 Learning Outcomes

After completing this project, you will master:

**Infrastructure as Code:**
- ✅ Packer for custom image building and immutable infrastructure
- ✅ Terraform for declarative infrastructure management
- ✅ Managing complex multi-environment deployments
- ✅ Terraform state management and resource dependencies

**GCP Services:**
- ✅ Managed Instance Groups (MIGs) with autoscaling
- ✅ Global HTTP Load Balancers and backend services
- ✅ Health checks and traffic management
- ✅ Custom machine images and image families
- ✅ IAM and service accounts with least privilege

**Deployment Strategies:**
- ✅ Blue-green deployment pattern implementation
- ✅ Zero-downtime deployment techniques
- ✅ Automated traffic switching and validation
- ✅ Rollback procedures and disaster recovery
- ✅ Environment detection and intelligent routing

**Automation & CI/CD:**
- ✅ GitHub Actions workflows for infrastructure
- ✅ Automated image building and testing
- ✅ Fully automated deployment pipelines
- ✅ Integration of IaC with CI/CD

**Production Best Practices:**
- ✅ Immutable infrastructure patterns
- ✅ Health-based routing and validation
- ✅ Auto-scaling and resource optimization  
- ✅ Cost optimization strategies
- ✅ Troubleshooting production issues

## 🚀 Real-World Applications

This architecture is used in production by companies like:
- **Netflix** - Pioneered chaos engineering with similar patterns
- **Amazon** - Uses blue-green for major service updates
- **Spotify** - Deploys microservices with zero downtime
- **GitHub** - Database migrations and service updates
- **Etsy** - Continuous deployment with instant rollback

**Use Cases:**
- Web applications requiring 99.9%+ uptime
- Microservices with frequent deployments
- E-commerce platforms (can't afford downtime)
- SaaS applications with multiple customers
- API services with strict SLAs
- Database schema migrations

## 📚 Next Steps & Enhancements

**Project Progression:**
1. ✅ **Project 1**: Simple Web Server
2. ✅ **Project 2**: Multi-VM Application Stack  
3. ✅ **Project 3**: Automated Blue-Green Deployment (current)
4. 🔜 **Project 4**: Canary Deployments with Traffic Splitting
5. 🔜 **Project 5**: Multi-Region Active-Active Architecture

**Enhancement Ideas:**

**Advanced Deployments:**
- [ ] Implement canary deployments (10% → 25% → 50% → 100%)
- [ ] Add A/B testing with traffic splitting
- [ ] Automated rollback on error rate threshold
- [ ] Feature flags for gradual rollout
- [ ] Dark launches (deploy without traffic)

**Monitoring & Observability:**
- [ ] Cloud Monitoring dashboards for blue/green metrics
- [ ] Custom metrics for deployment success rate
- [ ] Alerting on health check failures
- [ ] Log aggregation and analysis
- [ ] Distributed tracing

**Testing & Quality:**
- [ ] Smoke tests in CI/CD before traffic switch
- [ ] Load testing on standby environment
- [ ] Automated performance regression detection
- [ ] Integration tests in deployment pipeline

**Infrastructure:**
- [ ] Multi-region blue-green deployment
- [ ] Database migration strategies
- [ ] Session persistence during cutover
- [ ] WebSocket support
- [ ] CDN integration

**Security & Compliance:**
- [ ] HTTPS with managed SSL certificates
- [ ] Cloud Armor for DDoS protection
- [ ] VPC Service Controls
- [ ] Secrets management with Secret Manager
- [ ] Compliance logging and audit trails

## 🤝 Contributing

Found a bug or have an improvement? Contributions welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - Free for learning and commercial use.

---

**🎯 Master Production-Ready Blue-Green Deployments! 🔵🟢**

*Zero downtime • Instant rollback • Fully automated • Battle-tested*
