const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const port = process.env.PORT || 3000;

// Initialize Application Insights if available
let appInsightsInitialized = false;

// KEY_VAULT_URI is injected as an App Setting by Terraform (no secret values,
// just the vault's address). The actual secrets are fetched below using the
// App Service's system-assigned Managed Identity - nothing is hardcoded.
async function loadSecretsAndStartTelemetry() {
  const vaultUri = process.env.KEY_VAULT_URI;
  if (!vaultUri) {
    console.warn('[STARTUP] KEY_VAULT_URI not set - skipping Key Vault secret retrieval.');
    return;
  }
  
  try {
    console.log('[STARTUP] Attempting to load secrets from Key Vault:', vaultUri);
    const credential = new DefaultAzureCredential(); // uses Managed Identity on Azure
    const client = new SecretClient(vaultUri, credential);

    console.log('[STARTUP] Fetching AppInsights-ConnectionString from Key Vault...');
    const appInsightsSecret = await client.getSecret('AppInsights-ConnectionString');
    if (appInsightsSecret && appInsightsSecret.value) {
      const appInsights = require('applicationinsights');
      appInsights
        .setup(appInsightsSecret.value)
        .setSendLiveMetrics(true)
        .start();
      appInsightsInitialized = true;
      console.log('[STARTUP] ✓ Application Insights initialized from Key Vault secret.');
    }
  } catch (err) {
    console.error('[STARTUP] ❌ Failed to retrieve secrets from Key Vault:', err.message);
    console.warn('[STARTUP] ⚠️  Continuing without Application Insights...');
    // Don't fail startup - the app can run without App Insights
  }
}

// Setup all routes BEFORE starting server
app.use(express.json());
app.use(express.static('public'));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health check endpoint (useful for App Service health checks)
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    uptime: process.uptime(),
    appInsights: appInsightsInitialized,
    timestamp: new Date().toISOString()
  });
});

// Simple home route
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Sample App</title>
        <style>
          body { font-family: sans-serif; text-align: center; margin-top: 80px; }
          .success { color: green; }
          .warning { color: orange; }
        </style>
      </head>
      <body>
        <h1>🚀 Hello from Azure App Service!</h1>
        <p>This is a simple Node.js/Express app.</p>
        <p>Server time: ${new Date().toLocaleString()}</p>
        <p class="${appInsightsInitialized ? 'success' : 'warning'}">
          Application Insights: ${appInsightsInitialized ? '✓ Connected' : '⚠️ Disabled'}
        </p>
        <hr>
        <h3>API Endpoints:</h3>
        <ul>
          <li><a href="/api/health">Health Check</a></li>
          <li><a href="/api/greet/World">Greeting API</a></li>
        </ul>
      </body>
    </html>
  `);
});

// Simple example API route
app.get('/api/greet/:name', (req, res) => {
  res.json({ message: `Hello, ${req.params.name}!` });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Global error handler (must be last)
app.use((err, req, res, next) => {
  console.error('[ERROR]', err);
  res.status(500).json({ 
    error: 'Internal Server Error', 
    message: err.message 
  });
});

// Start the server - NEVER crash, always start
async function startServer() {
  try {
    console.log('[STARTUP] Initializing application...');
    console.log('[STARTUP] PORT:', port);
    console.log('[STARTUP] NODE_ENV:', process.env.NODE_ENV || 'production');
    
    // Set a 30-second timeout for secret loading
    const secretLoadPromise = loadSecretsAndStartTelemetry();
    const timeoutPromise = new Promise((resolve) => 
      setTimeout(() => {
        console.warn('[STARTUP] Secret loading timeout - continuing startup');
        resolve();
      }, 30000)
    );
    
    await Promise.race([secretLoadPromise, timeoutPromise]);
    
    // Bind to 0.0.0.0 to listen on all interfaces (required for Azure App Service)
    app.listen(port, '0.0.0.0', () => {
      console.log(`[STARTUP] ✓ Server listening on 0.0.0.0:${port}`);
      console.log(`[STARTUP] ✓ Application ready for requests`);
    });
    
  } catch (err) {
    console.error('[STARTUP] ❌ Unexpected error during startup:', err);
    console.error('[STARTUP] Stack trace:', err.stack);
    console.warn('[STARTUP] ⚠️  CRITICAL: Error during startup, but NOT exiting. Continuing...');
    // DO NOT call process.exit() - let the app stay running
    // Azure App Service will restart if needed
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('[UNCAUGHT_EXCEPTION]', err);
  console.warn('[UNCAUGHT_EXCEPTION] App is still running despite error');
});

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('[UNHANDLED_REJECTION]', reason);
});

// Start the server
startServer();
