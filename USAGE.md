# Blue-Green Deployment - Quick Usage Guide

## Simple Automated Workflow

### One-Time Setup
1. Configure GitHub Secrets:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `GCP_SA_KEY`: Service account JSON key

### Deployment Flow

#### 1. Build Image
```
Run: build-image workflow
→ Builds custom image with your app
```

#### 2. First Deployment
```
Run: deploy workflow (1st time)
→ Deploys to BLUE environment
→ Creates load balancer
→ Blue serves 100% traffic 🔵
```

#### 3. Deploy New Version
```
Update code → Run: build-image workflow
Run: deploy workflow (2nd time)
→ Deploys to GREEN environment
→ Auto-switches traffic to green 🟢
→ Auto-scales blue to 0 instances
```

#### 4. Next Deployment
```
Update code → Run: build-image workflow
Run: deploy workflow (3rd time)
→ Deploys to BLUE environment
→ Auto-switches traffic to blue 🔵
→ Auto-scales green to 0 instances
```

**Pattern:** Automatically toggles between blue ↔ green with each deployment!

### Rollback
```
Run: rollback workflow
→ Instant switch to previous environment
→ Automatic scaling handled
```

### Cleanup
```
Run: destroy workflow
→ Type "destroy" to confirm
→ Deletes all infrastructure
```

## Key Points

✅ **Fully Automated** - No manual switching needed  
✅ **Zero Downtime** - Traffic switches seamlessly  
✅ **Auto-Scaling** - Active: 2 instances, Standby: 0 instances  
✅ **Cost Optimized** - Only pay for active environment  
✅ **One-Click Rollback** - Instant recovery  

## Architecture

```
Load Balancer (always active)
    ↓
[Blue MIG] ←→ [Green MIG]
 
Deployment 1: Blue=2, Green=0  🔵 Active
Deployment 2: Blue=0, Green=2  🟢 Active  
Deployment 3: Blue=2, Green=0  🔵 Active
...continuous toggle...
```

## Workflows

| Workflow | Purpose | Runs |
|----------|---------|------|
| `build-image` | Build custom image with Packer | Manual |
| `deploy` | Auto blue-green toggle deploy | Manual |
| `rollback` | Switch back to previous | Manual |
| `destroy` | Delete all infrastructure | Manual |

## That's It!

No complex configurations. No manual traffic switching. Just build and deploy!
