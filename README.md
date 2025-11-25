# Project 3: Blue-Green Deployment 🔵🟢

An intermediate-level GCP project implementing zero-downtime blue-green deployments using custom images built with Packer, managed instance groups, and load balancers.

## 🏗️ Architecture

```
                         ┌─────────────────────┐
                         │   Global HTTP       │
                         │   Load Balancer     │
                         └──────────┬──────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │     Backend Service           │
                    │  (Traffic Switching Point)    │
                    └───────┬───────────────┬───────┘
                            │               │
                    ┌───────▼──────┐ ┌─────▼────────┐
                    │  BLUE MIG    │ │  GREEN MIG   │
                    │              │ │              │
                    │ - 2 VMs      │ │ - 2 VMs      │
                    │ - Version A  │ │ - Version B  │
                    │ - Active 🔵  │ │ - Standby 🟢 │
                    └──────────────┘ └──────────────┘

Custom Image Built with Packer:
┌─────────────────────────────────────────┐
│  Ubuntu 22.04 + Node.js + Application   │
│  - Pre-installed dependencies           │
│  - Application code baked in            │
│  - Fast boot time                       │
│  - Immutable infrastructure             │
└─────────────────────────────────────────┘
```

## 🎯 Learning Objectives

- Build custom GCP images with Packer
- Implement blue-green deployment strategy
- Configure managed instance groups (MIGs)
- Set up HTTP load balancers
- Manage backend services and traffic switching
- Implement zero-downtime deployments
- Use immutable infrastructure patterns
- Automate image building in CI/CD
- Manage multiple environments simultaneously
- Implement health-based traffic routing

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

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd project-03-blue-green-deployment
```

### 2. Build Custom Image with Packer
```bash
cd packer

# Initialize Packer
packer init .

# Validate Packer template
packer validate -var "project_id=your-project-id" .

# Build image
packer build -var "project_id=your-project-id" .
```

### 3. Deploy Blue Environment
```bash
cd terraform

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy blue environment
terraform init
terraform plan -var="active_environment=blue"
terraform apply -var="active_environment=blue"
```

### 4. Test Blue Environment
```bash
# Get load balancer IP
terraform output lb_ip_address

# Test application
curl http://<LB_IP>/api/health
curl http://<LB_IP>/api/version
```

### 5. Deploy Green Environment
```bash
# Build new image with updated application
cd packer
packer build -var "project_id=your-project-id" -var "version=2.0.0" .

# Deploy green environment (traffic still on blue)
cd terraform
terraform apply -var="active_environment=blue" -var="green_image=<new-image-name>"
```

### 6. Switch Traffic to Green
```bash
# Verify green is healthy
curl http://<GREEN_INTERNAL_IP>/api/health

# Switch traffic
terraform apply -var="active_environment=green"

# Traffic is now on green! 🟢
```

### 7. Rollback if Needed
```bash
# Instant rollback to blue
terraform apply -var="active_environment=blue"
```

## 📁 Project Structure

```
project-03-blue-green-deployment/
├── .github/
│   └── workflows/
│       ├── build-image.yml       # Build custom image with Packer
│       ├── deploy-blue.yml       # Deploy blue environment
│       ├── deploy-green.yml      # Deploy green environment
│       ├── switch-traffic.yml    # Switch traffic between environments
│       └── destroy.yml           # Destroy infrastructure
├── packer/
│   ├── image.pkr.hcl             # Packer template (HCL2)
│   └── scripts/
│       └── provision.sh          # Image provisioning script
├── terraform/
│   ├── main.tf                   # Provider configuration
│   ├── variables.tf              # Input variables
│   ├── terraform.tfvars.example  # Example values
│   ├── load-balancer.tf          # Load balancer resources
│   ├── blue-environment.tf       # Blue MIG and resources
│   ├── green-environment.tf      # Green MIG and resources
│   └── outputs.tf                # Output values
├── scripts/
│   ├── app/                      # Application code
│   │   ├── server.js             # Node.js application
│   │   └── package.json          # Dependencies
│   └── health-check.sh           # Health check script
├── tests/
│   └── test_blue_green.sh        # Blue-green testing
├── README.md
└── .gitignore
```

## 🔄 Blue-Green Deployment Workflow

### Phase 1: Initial Deployment (Blue)
1. Build custom image with Packer (v1.0.0)
2. Deploy blue environment with MIG
3. Configure load balancer pointing to blue
4. Verify application is healthy
5. **Blue is serving 100% traffic** 🔵

### Phase 2: Deploy Green (New Version)
1. Build new image with Packer (v2.0.0)
2. Deploy green environment with new image
3. Green instances start up (not receiving traffic)
4. Verify green instances are healthy
5. **Blue still serving 100% traffic** 🔵

### Phase 3: Switch Traffic
1. Update load balancer backend to point to green
2. Health checks ensure green is ready
3. Traffic gradually switches to green
4. Monitor metrics and logs
5. **Green now serving 100% traffic** 🟢
6. Blue instances remain running (ready for rollback)

### Phase 4: Verify and Cleanup
1. Monitor green environment for issues
2. If issues found: instant rollback to blue
3. If stable: keep green active
4. Optionally scale down or destroy blue
5. **Green continues serving traffic** 🟢

### Phase 5: Next Deployment
1. Blue becomes the new deployment target
2. Build new image (v3.0.0)
3. Deploy to blue environment
4. Switch traffic from green to blue
5. **Continuous zero-downtime deployments** 🔄

## 🎨 Deployment Strategies Supported

### 1. Instant Switch (Default)
- Immediate traffic cutover from blue to green
- Fastest deployment method
- Easy rollback

### 2. Canary Deployment
- Route 10% traffic to green initially
- Monitor metrics
- Gradually increase to 100%

### 3. A/B Testing
- Split traffic 50/50 between blue and green
- Compare performance metrics
- Choose winning version

## 🔐 Security Architecture

**Service Account:**
- Single custom service account for both environments
- `roles/logging.logWriter` - Write logs
- `roles/monitoring.metricWriter` - Write metrics
- `roles/compute.instanceAdmin` - Manage instances

**Network Security:**
- Load balancer handles external traffic
- Health checks on dedicated port
- Firewall rules per environment
- Tags for traffic management

## 🧪 Testing

### Test Image Build
```bash
cd packer
packer validate -var "project_id=your-project" .
```

### Test Blue Environment
```bash
cd terraform
terraform plan -var="active_environment=blue"
terraform apply -var="active_environment=blue"

# Get blue MIG IP
gcloud compute instances list --filter="name:blue-"

# Test directly
curl http://<BLUE_INSTANCE_IP>/api/version
```

### Test Green Environment
```bash
terraform apply -var="active_environment=blue" -var="deploy_green=true"

# Get green MIG IP
gcloud compute instances list --filter="name:green-"

# Test directly
curl http://<GREEN_INSTANCE_IP>/api/version
```

### Test Traffic Switching
```bash
# Initial: Blue active
curl http://<LB_IP>/api/version
# Returns: {"version": "1.0.0", "environment": "blue"}

# Switch to green
terraform apply -var="active_environment=green"

# Verify switch
curl http://<LB_IP>/api/version
# Returns: {"version": "2.0.0", "environment": "green"}
```

### Automated Testing
```bash
cd tests
chmod +x test_blue_green.sh
./test_blue_green.sh
```

## 📊 Monitoring

### Key Metrics to Monitor

**Load Balancer Metrics:**
- Request count
- Request latency (p50, p95, p99)
- Error rate (4xx, 5xx)
- Backend response time

**MIG Metrics:**
- Instance count per environment
- CPU utilization
- Memory usage
- Health check status

**Application Metrics:**
- Active environment (blue vs green)
- Application version
- Request success rate
- Response times

### Cloud Logging Queries

**View Active Environment:**
```
resource.type="http_load_balancer"
jsonPayload.statusDetails="response_from_backend"
```

**View Health Check Status:**
```
resource.type="gce_instance"
labels.instance_name=~"(blue|green)-.*"
"health check"
```

## 💰 Cost Estimate

**Monthly Cost (US Central1):**
- Load Balancer: ~$18/month (forwarding rules + traffic)
- Blue MIG (2x e2-micro): ~$15/month
- Green MIG (2x e2-micro): ~$15/month (during deployment)
- External IP: ~$4/month
- Image Storage: ~$0.50/month
- **Total (Both Environments)**: ~$52.50/month
- **Total (Single Environment)**: ~$37.50/month

**Cost Optimization:**
- Keep only one environment active
- Scale down standby environment to 0 instances
- Use preemptible VMs for testing (~70% discount)
- Delete old images regularly

## 🛡️ Advantages of Blue-Green Deployment

**Zero Downtime:**
- No service interruption during deployments
- Instant traffic switching

**Easy Rollback:**
- One command to revert to previous version
- Previous environment always ready

**Testing in Production:**
- Test new version in production environment
- Validate before switching traffic

**Reduced Risk:**
- New version fully tested before traffic switch
- Can run smoke tests on standby environment

**Fast Disaster Recovery:**
- Always have a working version ready
- Instant failover capability

## 🐛 Troubleshooting

### Image build fails
```bash
# Check Packer logs
packer build -debug -var "project_id=your-project" .

# Verify GCP permissions
gcloud projects get-iam-policy your-project

# Check if compute API is enabled
gcloud services list --enabled | grep compute
```

### MIG instances not healthy
```bash
# Check instance template
gcloud compute instance-templates describe blue-template-<version>

# Check instance logs
gcloud compute instances list --filter="name:blue-"
gcloud compute ssh blue-<instance> --command="journalctl -u webapp -n 100"

# Check health check configuration
gcloud compute health-checks describe http-health-check
```

### Traffic not switching
```bash
# Verify backend service configuration
gcloud compute backend-services describe web-backend-service

# Check which backend is active
gcloud compute backend-services get-health web-backend-service

# Verify URL map
gcloud compute url-maps describe web-url-map
```

### Load balancer not accessible
```bash
# Check forwarding rule
gcloud compute forwarding-rules list

# Verify firewall rules
gcloud compute firewall-rules list --filter="name:allow-lb"

# Check backend health
gcloud compute backend-services get-health web-backend-service
```

## 🧹 Cleanup

### Destroy Entire Infrastructure
```bash
cd terraform
terraform destroy
```

### Destroy Specific Environment
```bash
# Destroy green only
terraform destroy -target=google_compute_instance_group_manager.green_mig

# Destroy blue only
terraform destroy -target=google_compute_instance_group_manager.blue_mig
```

### Delete Old Images
```bash
# List images
gcloud compute images list --filter="name:webapp-"

# Delete specific image
gcloud compute images delete webapp-v1-0-0-20250101
```

## 🎓 Learning Outcomes

After completing this project, you'll understand:
- ✅ Packer image building and provisioning
- ✅ Blue-green deployment strategy
- ✅ Managed instance groups
- ✅ HTTP load balancers and backend services
- ✅ Zero-downtime deployments
- ✅ Traffic switching techniques
- ✅ Immutable infrastructure patterns
- ✅ Automated image building
- ✅ Production deployment strategies
- ✅ Rollback procedures

## 📚 Next Steps

**Project Progression:**
1. ✅ **Project 1**: Simple Web Server (completed)
2. ✅ **Project 2**: Multi-VM Application Stack (completed)
3. ✅ **Project 3**: Blue-Green Deployment (current)
4. 🔜 **Project 4**: Auto-Healing MIG
5. 🔜 **Project 5**: Scheduled VM Management

**Enhancement Ideas:**
- Implement canary deployments (10% → 50% → 100%)
- Add automated rollback on health check failures
- Implement feature flags
- Add performance comparison dashboards
- Implement A/B testing
- Add smoke tests in CI/CD
- Use Cloud Build instead of GitHub Actions

## 🤝 Contributing

Contributions welcome! Please open issues or pull requests.

## 📄 License

MIT License - free for learning purposes.

---

**Master Blue-Green Deployments! 🔵🟢🚀**
