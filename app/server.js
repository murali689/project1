const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static('public'));

// Simple logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

// Health endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Home page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Azure App Service</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
          h1 { color: #0078d4; }
          .ok { color: green; font-weight: bold; }
        </style>
      </head>
      <body>
        <h1>🚀 Hello from Azure!</h1>
        <p>Node.js app is running successfully</p>
        <p class="ok">✓ Server is ready</p>
        <hr>
        <a href="/api/health">API Health Check</a>
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
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({ error: 'Server error' });
});

// Start server on 0.0.0.0
const server = app.listen(port, '0.0.0.0', () => {
  console.log(`✓ Server running on port ${port}`);
  console.log(`✓ App is ready to handle requests`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
