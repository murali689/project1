const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const port = process.env.PORT || 3000;

let appInsightsInitialized = false;

// Load secrets from Key Vault using Managed Identity
async function loadSecretsAndStartTelemetry() {
  const vaultUri = process.env.KEY_VAULT_URI;
  if (!vaultUri) {
    console.warn('[STARTUP] KEY_VAULT_URI not set - skipping Key Vault.');
    return;
  }
  
  try {
    console.log('[STARTUP] Loading secrets from Key Vault:', vaultUri);
    const credential = new DefaultAzureCredential();
    const client = new SecretClient(vaultUri, credential);

    const appInsightsSecret = await client.getSecret('AppInsights-ConnectionString');
    if (appInsightsSecret && appInsightsSecret.value) {
      const appInsights = require('applicationinsights');
      appInsights
        .setup(appInsightsSecret.value)
        .setSendLiveMetrics(true)
        .start();
      appInsightsInitialized = true;
      console.log('[STARTUP] ✓ Application Insights initialized.');
    }
  } catch (err) {
    console.error('[STARTUP] ❌ Failed to load Key Vault secrets:', err.message);
    console.warn('[STARTUP] Continuing without Application Insights...');
  }
}

// Setup routes
app.use(express.json());
app.use(express.static('public'));

// Request logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    uptime: process.uptime(),
    appInsights: appInsightsInitialized
  });
});

// Home page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Azure App Service</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          h1 { color: #0078d4; }
          .status { padding: 10px; background: #f0f0f0; border-radius: 5px; }
        </style>
      </head>
      <body>
        <h1>🚀 Hello from Azure!</h1>
        <div class="status">
          <p><strong>Status:</strong> Running on Node.js ${process.version}</p>
          <p><strong>Uptime:</strong> ${Math.floor(process.uptime())}s</p>
          <p><strong>App Insights:</strong> ${appInsightsInitialized ? '✓ Connected' : '⚠️ Offline'}</p>
          <p><strong>Server Time:</strong> ${new Date().toLocaleString()}</p>
        </div>
        <hr>
        <h3>API Endpoints:</h3>
        <ul>
          <li><a href="/api/health">/api/health</a> - Health check</li>
          <li><a href="/api/greet/World">/api/greet/:name</a> - Greeting API</li>
        </ul>
      </body>
    </html>
  `);
});

// Greeting API
app.get('/api/greet/:name', (req, res) => {
  res.json({ message: `Hello, ${req.params.name}!` });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
async function startServer() {
  try {
    console.log('[STARTUP] Starting application on port', port);
    
    // Load secrets with 30 second timeout
    const loadSecretsPromise = loadSecretsAndStartTelemetry();
    const timeoutPromise = new Promise(resolve => 
      setTimeout(() => {
        console.warn('[STARTUP] Secret loading timeout - continuing');
        resolve();
      }, 30000)
    );
    
    await Promise.race([loadSecretsPromise, timeoutPromise]);
    
    // Start listening on all interfaces
    app.listen(port, '0.0.0.0', () => {
      console.log(`[STARTUP] ✓ Server listening on 0.0.0.0:${port}`);
      console.log('[STARTUP] ✓ Application ready');
    });
    
  } catch (err) {
    console.error('[STARTUP] Error:', err.message);
    // Continue anyway - don't crash
    app.listen(port, '0.0.0.0', () => {
      console.log(`[STARTUP] ✓ Server listening on 0.0.0.0:${port} (with error)`);
    });
  }
}

// Global error handlers
process.on('uncaughtException', (err) => {
  console.error('[UNCAUGHT]', err.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('[UNHANDLED]', reason);
});

// Start the app
startServer();
