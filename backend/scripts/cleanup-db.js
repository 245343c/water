/**
 * Remove non-production junk created by smoke tests or old seeds.
 * Run: node scripts/cleanup-db.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Customer = require('../src/models/Customer');
const DeliveryRoute = require('../src/models/DeliveryRoute');
const Order = require('../src/models/Order');
const Delivery = require('../src/models/Delivery');
const Notification = require('../src/models/Notification');

const SHOP_ID = 'shop-1';

async function cleanup() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const smokeRoutes = await DeliveryRoute.deleteMany({
    shopId: SHOP_ID,
    name: { $regex: /^Smoke Route /i },
  });
  console.log(`Removed ${smokeRoutes.deletedCount} smoke-test delivery route(s)`);

  const testCustomers = await Customer.find({
    shopId: SHOP_ID,
    $or: [
      { name: 'Route Test Customer' },
      { customerId: 'cust-demo-2' },
    ],
  }).select('customerId name');

  for (const customer of testCustomers) {
    const customerId = customer.customerId;
    await Order.deleteMany({ customerId });
    await Delivery.deleteMany({ customerId });
    await Notification.deleteMany({ customerId });
    await Customer.deleteOne({ customerId });
    console.log(`Removed test customer: ${customer.name} (${customerId})`);
  }

  console.log('Cleanup complete.');
  await mongoose.disconnect();
}

cleanup().catch((err) => {
  console.error(err);
  process.exit(1);
});
