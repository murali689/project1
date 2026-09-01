const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const port = process.env.PORT || 3000;

// KEY_VAULT_URI is injected as an App Setting by Terraform (no secret values,
// just the vault's address). The actual secrets are fetched below using the
// App Service's system-assigned Managed Identity - nothing is hardcoded.
async function loadSecretsAndStartTelemetry() {
  const vaultUri = process.env.KEY_VAULT_URI;
  if (!vaultUri) {
    console.warn('KEY_VAULT_URI not set - skipping Key Vault secret retrieval.');
    return;
  }
  try {
    const credential = new DefaultAzureCredential(); // uses Managed Identity on Azure
    const client = new SecretClient(vaultUri, credential);

    const appInsightsSecret = await client.getSecret('AppInsights-ConnectionString');
    if (appInsightsSecret.value) {
      const appInsights = require('applicationinsights');
      appInsights
        .setup(appInsightsSecret.value)
        .setSendLiveMetrics(true)
        .start();
      console.log('Application Insights initialized from Key Vault secret.');
    }
    // Example: retrieving DB connection string the same secure way
    // const sqlSecret = await client.getSecret('Sql-ConnectionString');
  } catch (err) {
    console.error('Failed to retrieve secrets from Key Vault:', err.message);
    console.warn('Continuing without Application Insights...');
  }
}

// Start the server only after loading secrets
async function startServer() {
  try {
    await loadSecretsAndStartTelemetry();
    
    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  } catch (err) {
    console.error('Fatal error during startup:', err);
    process.exit(1);
  }
}

app.use(express.json());
app.use(express.static('public'));

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal Server Error', message: err.message });
});

// Simple home route
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Sample App</title></head>
      <body style="font-family: sans-serif; text-align: center; margin-top: 80px;">
        <h1>🚀 Hello from Azure App Service!</h1>
        <p>This is a simple Node.js/Express app.</p>
        <p>Server time: ${new Date().toLocaleString()}</p>
        <p><a href="/api/health">Check health endpoint</a></p>
      </body>
    </html>
  `);
});

// Health check endpoint (useful for App Service health checks)
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Simple example API route
app.get('/api/greet/:name', (req, res) => {
  res.json({ message: `Hello, ${req.params.name}!` });
});

// Start the server
startServer();
