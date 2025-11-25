const express = require('express');
const os = require('os');

const app = express();
const port = process.env.PORT || 8080;
const appVersion = process.env.APP_VERSION || '1.0.0';
const environment = process.env.ENVIRONMENT || 'unknown';
const instanceName = process.env.INSTANCE_NAME || os.hostname();
const instanceId = process.env.INSTANCE_ID || 'unknown';
const zone = process.env.ZONE || 'unknown';

// Middleware
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - ${req.ip}`);
  next();
});

// Root endpoint
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Blue-Green Deployment - ${environment.toUpperCase()}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 900px;
          margin: 50px auto;
          padding: 20px;
          background: ${environment === 'blue' ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' : 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)'};
          color: white;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          padding: 30px;
          border-radius: 15px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
          font-size: 2.5em;
          margin: 0;
        }
        .badge {
          display: inline-block;
          padding: 8px 20px;
          border-radius: 20px;
          background: ${environment === 'blue' ? '#4169E1' : '#00FA9A'};
          font-weight: bold;
          font-size: 1.2em;
          margin: 10px 0;
        }
        .info-box {
          background: rgba(255, 255, 255, 0.2);
          padding: 20px;
          border-radius: 10px;
          margin: 20px 0;
        }
        .info-item {
          margin: 10px 0;
          font-size: 1.1em;
        }
        .label {
          font-weight: bold;
          opacity: 0.8;
        }
        code {
          background: rgba(0, 0, 0, 0.3);
          padding: 3px 8px;
          border-radius: 4px;
          font-family: 'Courier New', monospace;
        }
        .endpoints {
          background: rgba(255, 255, 255, 0.2);
          padding: 20px;
          border-radius: 10px;
          margin: 20px 0;
        }
        .endpoint {
          margin: 8px 0;
          font-family: 'Courier New', monospace;
        }
        .success { color: #00FF00; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Blue-Green Deployment</h1>
        <div class="badge ${environment === 'blue' ? 'badge-blue' : 'badge-green'}">
          ${environment.toUpperCase()} Environment
        </div>
        
        <div class="info-box">
          <h2>📊 Deployment Information</h2>
          <div class="info-item">
            <span class="label">Environment:</span> 
            <code>${environment}</code>
          </div>
          <div class="info-item">
            <span class="label">Version:</span> 
            <code>${appVersion}</code>
          </div>
          <div class="info-item">
            <span class="label">Instance:</span> 
            <code>${instanceName}</code>
          </div>
          <div class="info-item">
            <span class="label">Instance ID:</span> 
            <code>${instanceId}</code>
          </div>
          <div class="info-item">
            <span class="label">Zone:</span> 
            <code>${zone}</code>
          </div>
          <div class="info-item">
            <span class="label">Node.js:</span> 
            <code>${process.version}</code>
          </div>
          <div class="info-item">
            <span class="label">Uptime:</span> 
            <code>${Math.floor(process.uptime())}s</code>
          </div>
        </div>

        <div class="endpoints">
          <h2>🔗 Available Endpoints</h2>
          <div class="endpoint"><span class="success">GET</span> /api/health - Health check</div>
          <div class="endpoint"><span class="success">GET</span> /api/version - Version info</div>
          <div class="endpoint"><span class="success">GET</span> /api/info - Instance info</div>
          <div class="endpoint"><span class="success">GET</span> /api/stress - Load test endpoint</div>
        </div>

        <div class="info-box">
          <h2>✅ Features</h2>
          <ul>
            <li>Zero-downtime deployments</li>
            <li>Instant rollback capability</li>
            <li>Custom image built with Packer</li>
            <li>Managed instance groups</li>
            <li>HTTP load balancer</li>
            <li>Health-based routing</li>
          </ul>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Health check endpoint (for load balancer)
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: environment,
    version: appVersion,
    uptime: process.uptime()
  });
});

// Version endpoint
app.get('/api/version', (req, res) => {
  res.json({
    version: appVersion,
    environment: environment,
    nodeVersion: process.version,
    instance: instanceName,
    timestamp: new Date().toISOString()
  });
});

// Instance info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    environment: environment,
    version: appVersion,
    instance: {
      name: instanceName,
      id: instanceId,
      zone: zone,
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch()
    },
    process: {
      nodeVersion: process.version,
      pid: process.pid,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage()
    },
    system: {
      cpus: os.cpus().length,
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      loadAverage: os.loadavg()
    },
    timestamp: new Date().toISOString()
  });
});

// Stress test endpoint (for testing auto-scaling)
app.get('/api/stress', (req, res) => {
  const duration = parseInt(req.query.duration) || 1000;
  const start = Date.now();
  
  // Simulate CPU-intensive work
  while (Date.now() - start < duration) {
    Math.sqrt(Math.random());
  }
  
  res.json({
    message: 'Stress test completed',
    duration: duration,
    environment: environment,
    instance: instanceName,
    timestamp: new Date().toISOString()
  });
});

// Metadata endpoint
app.get('/api/metadata', (req, res) => {
  res.json({
    environment: environment,
    version: appVersion,
    deployment: 'blue-green',
    features: [
      'zero-downtime',
      'instant-rollback',
      'health-checks',
      'load-balancing'
    ],
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    environment: environment,
    timestamp: new Date().toISOString()
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
    environment: environment,
    timestamp: new Date().toISOString()
  });
});

// Start server
const server = app.listen(port, '0.0.0.0', () => {
  console.log('='.repeat(50));
  console.log('🚀 Blue-Green Deployment Application Started');
  console.log('='.repeat(50));
  console.log(`Environment: ${environment.toUpperCase()}`);
  console.log(`Version: ${appVersion}`);
  console.log(`Port: ${port}`);
  console.log(`Instance: ${instanceName}`);
  console.log(`Instance ID: ${instanceId}`);
  console.log(`Zone: ${zone}`);
  console.log(`Node.js: ${process.version}`);
  console.log('='.repeat(50));
  console.log(`Health check: http://localhost:${port}/api/health`);
  console.log(`Version info: http://localhost:${port}/api/version`);
  console.log('='.repeat(50));
});

// Graceful shutdown
const shutdown = (signal) => {
  console.log(`\n${signal} received, shutting down gracefully...`);
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
  
  // Force shutdown after 10 seconds
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
