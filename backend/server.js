require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/db');

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logger (dev only)
if (process.env.NODE_ENV === 'development') {
  app.use((req, _res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
    next();
  });
}

// Routes
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/shop', require('./src/routes/shop'));
app.use('/api/customers', require('./src/routes/customers'));
app.use('/api/drivers', require('./src/routes/drivers'));
app.use('/api/products', require('./src/routes/products'));
app.use('/api/orders', require('./src/routes/orders'));
app.use('/api/deliveries', require('./src/routes/deliveries'));
app.use('/api/cash', require('./src/routes/cashCollections'));
app.use('/api/bills', require('./src/routes/monthlyBills'));
app.use('/api/notifications', require('./src/routes/notifications'));
app.use('/api/promotions', require('./src/routes/promotions'));
app.use('/api/reports', require('./src/routes/reports'));

// Health check
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', time: new Date().toISOString() });
});

// 404
app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// Global error handler
app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ success: false, message: err.message || 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Sri Sai RO Water backend running on port ${PORT}`);
  console.log(`MongoDB: ${process.env.MONGO_URI}`);
});

module.exports = app;
