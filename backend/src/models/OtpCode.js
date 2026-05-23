const mongoose = require('mongoose');

const otpCodeSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, index: true },
    purpose: {
      type: String,
      enum: ['customer_login', 'password_reset'],
      required: true,
    },
    otpHash: { type: String, required: true },
    attempts: { type: Number, default: 0 },
    maxAttempts: { type: Number, default: 5 },
    expiresAt: { type: Date, required: true },
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

otpCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('OtpCode', otpCodeSchema);
