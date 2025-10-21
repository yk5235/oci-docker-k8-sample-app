const mongoose = require('mongoose');

const connectDatabase = async () => {
  const mongoUri = `mongodb://${process.env.MONGO_USERNAME}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST}:${process.env.MONGO_PORT}/${process.env.MONGO_DB}?authSource=admin`;

  const options = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 30000,
    maxPoolSize: 10,
    minPoolSize: 2,
  };

  try {
    await mongoose.connect(mongoUri, options);
    console.log('✓ Connected to MongoDB');
  } catch (error) {
    console.error('✗ Error connecting to MongoDB:', error.message);
    process.exit(1);
  }

  // Connection event handlers
  mongoose.connection.on('connected', () => {
    console.log('MongoDB connection established');
  });

  mongoose.connection.on('error', (err) => {
    console.error('MongoDB connection error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.log('MongoDB disconnected');
  });

  // Graceful shutdown
  process.on('SIGINT', async () => {
    await mongoose.connection.close();
    console.log('MongoDB connection closed due to app termination');
    process.exit(0);
  });
};

module.exports = connectDatabase;