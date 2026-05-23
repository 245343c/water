const mongoose = require('mongoose');

const billLineSchema = new mongoose.Schema(
  {
    deliveryId: { type: String },
    date: { type: Date },
    description: { type: String },
    normalQty: { type: Number, default: 0 },
    coolQty: { type: Number, default: 0 },
    amount: { type: Number, default: 0 },
  },
  { _id: false },
);

const monthlyBillSchema = new mongoose.Schema(
  {
    billId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    customerId: { type: String, required: true },
    customerName: { type: String, default: '' },
    month: { type: Number, required: true },
    year: { type: Number, required: true },
    billingPeriodStart: { type: Date },
    billingPeriodEnd: { type: Date },
    totalNormalCans: { type: Number, default: 0 },
    totalCoolCans: { type: Number, default: 0 },
    itemsSummary: [billLineSchema],
    currentMonthAmount: { type: Number, default: 0 },
    previousPendingAmount: { type: Number, default: 0 },
    cashCollectedAmount: { type: Number, default: 0 },
    finalPendingAmount: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['draft', 'generated', 'sent', 'paid', 'partially_paid', 'overdue', 'cancelled'],
      default: 'draft',
    },
    pdfUrl: { type: String, default: null },
    generatedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

monthlyBillSchema.index({ shopId: 1, customerId: 1, year: 1, month: 1 });
monthlyBillSchema.index({ shopId: 1, status: 1 });

module.exports = mongoose.model('MonthlyBill', monthlyBillSchema);
