#!/bin/bash
###############################################################################
# Packer Provisioning Script for Web Application Image
# 
# This script prepares a custom GCP image with:
# 1. Node.js runtime
# 2. Application code and dependencies
# 3. Systemd service configuration
# 4. Health check endpoints
###############################################################################

set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting image provisioning..."
log "Application version: ${APP_VERSION:-1.0.0}"

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Node.js 18.x
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install additional tools
log "Installing additional tools..."
apt-get install -y \
    curl \
    wget \
    git \
    jq \
    htop \
    net-tools

# Create application directory
log "Creating application directory..."
mkdir -p /opt/webapp
cd /opt/webapp

# Copy application files from /tmp/app to /opt/webapp
log "Copying application files..."
if [ -d "/tmp/app" ]; then
    cp -r /tmp/app/* /opt/webapp/
else
    log "ERROR: Application files not found in /tmp/app"
    exit 1
fi

# Ensure package.json exists
if [ ! -f "/opt/webapp/package.json" ]; then
    log "ERROR: package.json not found"
    exit 1
fi

# Install Node.js dependencies
log "Installing Node.js dependencies..."
npm install --production --no-audit

# Create environment file template
log "Creating environment file template..."
cat > /opt/webapp/.env.template <<'EOF'
NODE_ENV=production
PORT=8080
APP_VERSION=${APP_VERSION}
ENVIRONMENT=${ENVIRONMENT}
EOF

# Create default .env file so service can start immediately
cat > /opt/webapp/.env <<'EOF'
NODE_ENV=production
PORT=8080
APP_VERSION=1.0.0
ENVIRONMENT=unknown
EOF

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/webapp.service <<'EOF'
[Unit]
Description=Web Application for Blue-Green Deployment
After=network.target webapp-configure.service
Wants=webapp-configure.service
Documentation=https://github.com/your-org/blue-green-deployment

[Service]
Type=simple
User=root
WorkingDirectory=/opt/webapp
Environment="NODE_ENV=production"
Environment="PORT=8080"
EnvironmentFile=-/opt/webapp/.env
ExecStartPre=/bin/sh -c 'echo "Starting webapp service..."'
ExecStart=/usr/bin/node /opt/webapp/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webapp

# Security settings
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Enable service (will start on boot)
log "Enabling webapp service..."
systemctl daemon-reload
systemctl enable webapp.service

# Create startup script that will run on first boot
log "Creating first-boot configuration script..."
cat > /usr/local/bin/webapp-configure.sh <<'FIRSTBOOT_EOF'
#!/bin/bash
# This script runs on first boot to configure environment-specific settings

# Get instance metadata
ENVIRONMENT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment -H "Metadata-Flavor: Google" || echo "unknown")
APP_VERSION=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/app_version -H "Metadata-Flavor: Google" || echo "1.0.0")

# Create environment file
cat > /opt/webapp/.env <<EOF
NODE_ENV=production
PORT=8080
APP_VERSION=${APP_VERSION}
ENVIRONMENT=${ENVIRONMENT}
INSTANCE_NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google")
INSTANCE_ID=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/id -H "Metadata-Flavor: Google")
ZONE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | cut -d/ -f4)
EOF

# Restart service to pick up new environment
systemctl restart webapp.service

echo "Webapp configured for environment: ${ENVIRONMENT}, version: ${APP_VERSION}"
FIRSTBOOT_EOF

chmod +x /usr/local/bin/webapp-configure.sh

# Create systemd oneshot service for first boot configuration
cat > /etc/systemd/system/webapp-configure.service <<'EOF'
[Unit]
Description=Configure Web Application on First Boot
After=network-online.target
Wants=network-online.target
Before=webapp.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/webapp-configure.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable webapp-configure.service

# Create health check script
log "Creating health check script..."
cat > /usr/local/bin/health-check.sh <<'EOF'
#!/bin/bash
# Health check script for load balancer

HEALTH_ENDPOINT="http://localhost:8080/api/health"
TIMEOUT=5

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$HEALTH_ENDPOINT")

if [ "$HTTP_STATUS" -eq 200 ]; then
    exit 0  # Healthy
else
    exit 1  # Unhealthy
fi
EOF

chmod +x /usr/local/bin/health-check.sh

# Set proper permissions
log "Setting permissions..."
chown -R root:root /opt/webapp
chmod -R 755 /opt/webapp
chmod 644 /opt/webapp/.env.template

# Verify Node.js installation
log "Verifying Node.js installation..."
node --version
npm --version

# Verify application files
log "Verifying application files..."
ls -la /opt/webapp

# Display summary
log "==============================================="
log "Image Provisioning Complete!"
log "==============================================="
log "Node.js version: $(node --version)"
log "NPM version: $(npm --version)"
log "Application directory: /opt/webapp"
log "Application version: ${APP_VERSION:-1.0.0}"
log "Systemd service: webapp.service (enabled)"
log "Health check: /usr/local/bin/health-check.sh"
log "==============================================="

exit 0
