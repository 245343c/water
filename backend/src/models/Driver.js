const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema(
  {
    driverId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    uid: { type: String, default: null },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    email: { type: String, lowercase: true, trim: true, default: '' },
    active: { type: Boolean, default: true },
    assignedArea: { type: String, default: '' },
    vehicleNumber: { type: String, default: '' },
    photoUrl: { type: String, default: null },
    lastActiveAt: { type: Date, default: null },
  },
  { timestamps: true },
);

driverSchema.index({ shopId: 1 });

module.exports = mongoose.model('Driver', driverSchema);
