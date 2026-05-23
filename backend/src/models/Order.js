const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    productId: { type: String },
    variantId: { type: String },
    label: { type: String, required: true },
    quantity: { type: Number, required: true },
    unitPrice: { type: Number, required: true },
    lineTotal: { type: Number, required: true },
  },
  { _id: false },
);

const orderSchema = new mongoose.Schema(
  {
    orderId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    customerId: { type: String, required: true },
    appUserId: { type: String, default: null },
    customerName: { type: String, default: '' },
    customerPhone: { type: String, default: '' },
    deliveryAddress: { type: String, default: '' },
    deliveryLatitude: { type: Number, default: null },
    deliveryLongitude: { type: Number, default: null },
    items: [orderItemSchema],
    normalQty: { type: Number, default: 0 },
    coolQty: { type: Number, default: 0 },
    subtotal: { type: Number, default: 0 },
    deliveryCharge: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    orderStatus: {
      type: String,
      enum: ['pending', 'accepted', 'assigned', 'out_for_delivery', 'delivered', 'rejected', 'cancelled'],
      default: 'pending',
    },
    paymentCollectionStatus: {
      type: String,
      enum: ['not_collected', 'cash_collected', 'added_to_monthly_bill'],
      default: 'not_collected',
    },
    assignedDriverId: { type: String, default: null },
    assignedDriverName: { type: String, default: null },
    customerNote: { type: String, default: null },
    adminNote: { type: String, default: null },
    acceptedAt: { type: Date, default: null },
    rejectedAt: { type: Date, default: null },
    assignedAt: { type: Date, default: null },
    outForDeliveryAt: { type: Date, default: null },
    deliveredAt: { type: Date, default: null },
    cancelledAt: { type: Date, default: null },
    driverAcceptedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

orderSchema.index({ shopId: 1, orderStatus: 1 });
orderSchema.index({ shopId: 1, customerId: 1 });
orderSchema.index({ shopId: 1, createdAt: -1 });
orderSchema.index({ shopId: 1, assignedDriverId: 1, orderStatus: 1 });
orderSchema.index({ appUserId: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
