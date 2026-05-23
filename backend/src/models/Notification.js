const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    notificationId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    type: { type: String, required: true },
    title: { type: String, required: true },
    body: { type: String, default: '' },
    audience: {
      type: String,
      enum: ['admin', 'driver', 'customer', 'all'],
      default: 'admin',
    },
    targetUid: { type: String, default: null },
    customerId: { type: String, default: null },
    driverId: { type: String, default: null },
    orderId: { type: String, default: null },
    deliveryId: { type: String, default: null },
    read: { type: Boolean, default: false },
    readAt: { type: Date, default: null },
  },
  { timestamps: true },
);

notificationSchema.index({ shopId: 1, targetUid: 1, read: 1 });
notificationSchema.index({ shopId: 1, createdAt: -1 });
notificationSchema.index({ shopId: 1, audience: 1, read: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
