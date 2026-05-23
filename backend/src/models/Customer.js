const mongoose = require('mongoose');
const { phoneDigits } = require('../utils/phone');

const customerProductPriceSchema = new mongoose.Schema(
  {
    productId: { type: String, required: true },
    variantId: { type: String, required: true },
    unitPrice: { type: Number, required: true },
    enabled: { type: Boolean, default: true },
  },
  { _id: false },
);

const customerSchema = new mongoose.Schema(
  {
    customerId: { type: String, required: true },
    shopId: { type: String, required: true },
    appUserId: { type: String, default: null },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    phoneLast10: { type: String, trim: true, default: '' },
    email: { type: String, lowercase: true, trim: true, default: '' },
    address: { type: String, trim: true, default: '' },
    place: { type: String, trim: true, default: '' },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    customerType: {
      type: String,
      enum: ['manual_customer', 'app_customer'],
      default: 'manual_customer',
    },
    billingMode: {
      type: String,
      enum: ['monthly_contract', 'on_demand'],
      default: 'monthly_contract',
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'blocked', 'deleted'],
      default: 'active',
    },
    productPrices: [customerProductPriceSchema],
    totalPendingAmount: { type: Number, default: 0 },
    lastDeliveryAt: { type: Date, default: null },
    lastCashCollectionAt: { type: Date, default: null },
  },
  { timestamps: true },
);

customerSchema.index({ shopId: 1 });
customerSchema.index({ shopId: 1, phone: 1 });
customerSchema.index({ shopId: 1, name: 1 });
customerSchema.index({ phoneLast10: 1, status: 1 });

customerSchema.pre('save', function setPhoneLast10(next) {
  if (this.isModified('phone') || !this.phoneLast10) {
    this.phoneLast10 = phoneDigits(this.phone);
  }
  next();
});

module.exports = mongoose.model('Customer', customerSchema);
