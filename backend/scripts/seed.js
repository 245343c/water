/**
 * Seed script — creates initial admin and driver accounts in MongoDB.
 * Run: node scripts/seed.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Shop = require('../src/models/Shop');
const Driver = require('../src/models/Driver');
const Customer = require('../src/models/Customer');

const SHOP_ID = 'shop-1';

const users = [
  {
    uid: 'admin-1',
    role: 'shop_admin',
    shopId: SHOP_ID,
    name: 'Shop Owner',
    email: 'admin@srisai.com',
    phone: '+91 98765 43210',
    password: 'admin123',
    profileCompleted: true,
    isActive: true,
  },
  {
    uid: 'user-driver-1',
    role: 'driver',
    shopId: SHOP_ID,
    driverId: 'driver-1',
    name: 'Rajesh Kumar',
    email: 'driver@srisai.com',
    phone: '+91 91234 56780',
    password: 'driver123',
    profileCompleted: true,
    isActive: true,
  },
];

const shop = {
  shopId: SHOP_ID,
  shopName: 'Sri Sai RO Water Plant',
  ownerUid: 'admin-1',
  ownerName: 'Shop Owner',
  phone: '+91 98765 43210',
  email: 'info@srisairowater.com',
  address: 'Main Road, Rajahmundry, Andhra Pradesh - 533101',
  place: 'Rajahmundry',
  latitude: 16.9902,
  longitude: 81.7780,
  homeDeliveryAvailable: true,
  isListed: true,
  normalCanPrice: 20,
  coolCanPrice: 30,
  tagline: 'Pure RO water · Fast home delivery',
  acceptingOrders: true,
};

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  // Upsert shop
  await Shop.findOneAndUpdate({ shopId: shop.shopId }, shop, { upsert: true, new: true });
  console.log('Shop seeded:', shop.shopName);

  // Upsert users
  for (const userData of users) {
    const existing = await User.findOne({ uid: userData.uid });
    if (existing) {
      console.log('User already exists:', userData.email);
      continue;
    }
    await User.create(userData);
    console.log('User created:', userData.email, '/', userData.role);
  }

  // Ensure driver record exists in drivers collection
  const driverUserData = users.find((u) => u.role === 'driver');
  if (driverUserData) {
    const existingDriver = await Driver.findOne({ uid: driverUserData.uid });
    if (!existingDriver) {
      await Driver.create({
        driverId: driverUserData.driverId,
        shopId: SHOP_ID,
        uid: driverUserData.uid,
        name: driverUserData.name,
        phone: driverUserData.phone,
        email: driverUserData.email,
        active: true,
      });
      console.log('Driver record created:', driverUserData.name);
    } else {
      console.log('Driver record already exists:', driverUserData.name);
    }
  }

  await Customer.findOneAndUpdate(
    { customerId: 'cust-demo-1', shopId: SHOP_ID },
    {
      customerId: 'cust-demo-1',
      shopId: SHOP_ID,
      name: 'Demo Customer',
      phone: '+91 99999 99999',
      address: 'Sample Street, Rajahmundry',
      place: 'Rajahmundry',
      customerType: 'manual_customer',
      billingMode: 'on_demand',
      status: 'active',
    },
    { upsert: true, new: true },
  );
  console.log('Customer seeded for OTP login: +91 99999 99999 (OTP: 123456)');

  console.log('\nSeed complete. Login credentials:');
  console.log('  Admin:  admin@srisai.com / admin123');
  console.log('  Driver: driver@srisai.com / driver123');
  console.log('  Customer OTP: 9999999999 / 123456');

  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
