const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema(
  {
    promotionId: { type: String, required: true, unique: true },
    shopId: { type: String, required: true },
    headline: { type: String, required: true },
    body: { type: String, default: '' },
    mediaUrl: { type: String, default: null },
    mediaType: {
      type: String,
      enum: ['image', 'video', 'none'],
      default: 'image',
    },
    badge: { type: String, default: null },
    ctaLabel: { type: String, default: null },
    isActive: { type: Boolean, default: true },
    startsAt: { type: Date, default: null },
    endsAt: { type: Date, default: null },
  },
  { timestamps: true },
);

promotionSchema.index({ shopId: 1, isActive: 1 });

module.exports = mongoose.model('Promotion', promotionSchema);
