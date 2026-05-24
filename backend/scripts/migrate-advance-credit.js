/**
 * Backfill advanceCredit=0 and fix negative totalPendingAmount on existing customers.
 * Run: node scripts/migrate-advance-credit.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Customer = require('../src/models/Customer');

async function migrate() {
  await mongoose.connect(process.env.MONGO_URI);
  const customers = await Customer.find({});
  let fixed = 0;
  for (const c of customers) {
    let changed = false;
    if (c.advanceCredit == null) {
      c.advanceCredit = 0;
      changed = true;
    }
    if (c.totalPendingAmount < 0) {
      c.advanceCredit = (c.advanceCredit || 0) + Math.abs(c.totalPendingAmount);
      c.totalPendingAmount = 0;
      changed = true;
    }
    if (changed) {
      await c.save({ validateBeforeSave: false });
      fixed += 1;
    }
  }
  console.log(`Migrated ${fixed} customer(s).`);
  await mongoose.disconnect();
}

migrate().catch((err) => {
  console.error(err);
  process.exit(1);
});
