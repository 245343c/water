require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const connectDB = require('./src/config/db');
const logger = require('./src/utils/logger');
const requestLogger = require('./src/middleware/requestLogger');

const app = express();

connectDB();

const corsOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((s) => s.trim())
  : true;

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(compression());
app.use(cors({ origin: corsOrigins }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));
app.use(requestLogger);

app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX || '500', 10),
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Too many requests, please try again later' },
  }),
);

app.use(
  '/api/auth/customer/request-otp',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: parseInt(process.env.OTP_RATE_LIMIT_MAX || '20', 10),
    message: { success: false, message: 'Too many OTP requests' },
  }),
);

app.use('/uploads', express.static(path.join(__dirname, 'uploads'), { maxAge: '7d' }));

app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/shop', require('./src/routes/shop'));
app.use('/api/customers', require('./src/routes/customers'));
app.use('/api/delivery-routes', require('./src/routes/deliveryRoutes'));
app.use('/api/drivers', require('./src/routes/drivers'));
app.use('/api/products', require('./src/routes/products'));
app.use('/api/orders', require('./src/routes/orders'));
app.use('/api/deliveries', require('./src/routes/deliveries'));
app.use('/api/cash', require('./src/routes/cashCollections'));
app.use('/api/bills', require('./src/routes/monthlyBills'));
app.use('/api/notifications', require('./src/routes/notifications'));
app.use('/api/promotions', require('./src/routes/promotions'));
app.use('/api/reports', require('./src/routes/reports'));
app.use('/api/uploads', require('./src/routes/uploads'));

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    time: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development',
  });
});

app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use((err, req, res, _next) => {
  logger.error('Unhandled error', {
    requestId: req.requestId,
    message: err.message,
    stack: err.stack,
  });
  res.status(err.status || 500).json({
    success: false,
    message: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
  });
});

const PORT = parseInt(process.env.PORT || '3000', 10);
app.listen(PORT, () => {
  logger.info('Server started', {
    port: PORT,
    nodeEnv: process.env.NODE_ENV || 'development',
    mongoUri: process.env.MONGO_URI ? '(configured)' : '(missing)',
  });
});

module.exports = app;
