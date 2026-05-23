const mongoose = require('mongoose');

const deliveryLineSchema = new mongoose.Schema(
  {
    kind: {
      type: String,
      enum: ['normalCan', 'coolCan', 'bottle'],
      required: true,
    },
    label: { type: String, required: true },
    productId: { type: String, default: null },
    quantity: { type: Number, required: true },
    unitPrice: { type: Number, required: true },
    lineTotal: { type: Number, required: true },
  },
  { _id: false },
);

const deliverySchema = new mongoose.Schema(
  {
    deliveryId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    orderId: { type: String, default: null },
    customerId: { type: String, required: true },
    customerName: { type: String, default: '' },
    customerPhone: { type: String, default: '' },
    driverId: { type: String, default: null },
    driverName: { type: String, default: null },
    deliveryDate: { type: Date, required: true },
    lines: [deliveryLineSchema],
    totalAmount: { type: Number, default: 0 },
    deliveryType: {
      type: String,
      enum: ['manual_delivery', 'app_order_delivery', 'monthly_contract_delivery'],
      default: 'manual_delivery',
    },
    cashCollectionStatus: {
      type: String,
      enum: ['not_collected', 'collected', 'added_to_monthly_bill'],
      default: 'not_collected',
    },
    recordedByUid: { type: String, default: null },
    recordedByRole: { type: String, default: null },
    notes: { type: String, default: null },
  },
  { timestamps: true },
);

deliverySchema.index({ shopId: 1, deliveryDate: -1 });
deliverySchema.index({ shopId: 1, customerId: 1 });
deliverySchema.index({ shopId: 1, driverId: 1 });

module.exports = mongoose.model('Delivery', deliverySchema);
