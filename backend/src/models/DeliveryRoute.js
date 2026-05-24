const mongoose = require('mongoose');

const deliveryRouteSchema = new mongoose.Schema(
  {
    routeId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    name: { type: String, required: true, trim: true },
    active: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true },
);

deliveryRouteSchema.index({ shopId: 1, name: 1 }, { unique: true });
deliveryRouteSchema.index({ shopId: 1, active: 1 });

module.exports = mongoose.model('DeliveryRoute', deliveryRouteSchema);
