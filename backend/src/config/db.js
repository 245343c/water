const mongoose = require('mongoose');
const logger = require('../utils/logger');

const connectDB = async () => {
  try {
    const uri = process.env.MONGO_URI;
    if (!uri) {
      throw new Error('MONGO_URI is not set');
    }

    const conn = await mongoose.connect(uri, {
      maxPoolSize: parseInt(process.env.MONGO_MAX_POOL_SIZE || '50', 10),
      minPoolSize: parseInt(process.env.MONGO_MIN_POOL_SIZE || '5', 10),
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });

    logger.info('MongoDB connected', {
      host: conn.connection.host,
      name: conn.connection.name,
      maxPoolSize: conn.connection.client?.options?.maxPoolSize,
    });
  } catch (err) {
    logger.error('MongoDB connection error', { message: err.message });
    process.exit(1);
  }
};

module.exports = connectDB;
