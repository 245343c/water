const mongoose = require('mongoose');

const cashCollectionSchema = new mongoose.Schema(
  {
    cashCollectionId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    customerId: { type: String, required: true },
    customerName: { type: String, default: '' },
    orderId: { type: String, default: null },
    deliveryId: { type: String, default: null },
    billId: { type: String, default: null },
    amount: { type: Number, required: true },
    collectionType: {
      type: String,
      enum: ['order_cash', 'delivery_cash', 'monthly_bill_cash', 'advance_cash', 'adjustment'],
      default: 'delivery_cash',
    },
    collectedByUid: { type: String, required: true },
    collectedByRole: { type: String, required: true },
    collectedByName: { type: String, default: '' },
    collectionDate: { type: Date, required: true },
    notes: { type: String, default: null },
  },
  { timestamps: true },
);

cashCollectionSchema.index({ shopId: 1, customerId: 1 });
cashCollectionSchema.index({ shopId: 1, collectionDate: -1 });

module.exports = mongoose.model('CashCollection', cashCollectionSchema);
