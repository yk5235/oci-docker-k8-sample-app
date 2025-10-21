const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDatabase = require('./config/database');
const customerRoutes = require('./routes/customerRoutes');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./middleware/logger');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(cors());
app.use(logger);

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Customer Data Entry API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      customers: '/customers'
    }
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  const mongoose = require('mongoose');
  const health = {
    status: 'OK',
    uptime: process.uptime(),
    timestamp: Date.now(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  };
  res.status(200).json(health);
});

// Customer routes
app.use('/customers', customerRoutes);

// Error handler (must be last)
app.use(errorHandler);

// Connect to database and start server
const startServer = async () => {
  await connectDatabase();
  
  app.listen(PORT, () => {
    console.log(`✓ Server is running on http://localhost:${PORT}`);
    console.log(`✓ Health check: http://localhost:${PORT}/health`);
  });
};

startServer();