const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema(
  {
    shopId: { type: String, required: true, unique: true },
    shopName: { type: String, required: true, trim: true },
    ownerUid: { type: String, required: true },
    ownerName: { type: String, trim: true, default: '' },
    phone: { type: String, trim: true, default: '' },
    email: { type: String, lowercase: true, trim: true, default: '' },
    address: { type: String, trim: true, default: '' },
    place: { type: String, trim: true, default: '' },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    coverImageUrl: { type: String, default: null },
    ownerPhotoUrl: { type: String, default: null },
    homeDeliveryAvailable: { type: Boolean, default: false },
    isListed: { type: Boolean, default: true },
    normalCanPrice: { type: Number, default: 20 },
    coolCanPrice: { type: Number, default: 30 },
    deliveryCharge: { type: Number, default: 0 },
    minimumOrderQuantity: { type: Number, default: 1 },
    acceptingOrders: { type: Boolean, default: true },
    invoicePrefix: { type: String, default: 'INV' },
    billDueDays: { type: Number, default: 7 },
    workingHours: { type: String, default: '8:00 AM - 8:00 PM' },
    rating: { type: Number, default: 0 },
    reviewCount: { type: Number, default: 0 },
    tagline: { type: String, default: '' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Shop', shopSchema);
