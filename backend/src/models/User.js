const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    uid: { type: String, required: true, unique: true },
    role: {
      type: String,
      enum: ['shop_admin', 'driver', 'customer'],
      required: true,
    },
    shopId: { type: String, default: null },
    driverId: { type: String, default: null },
    customerProfileId: { type: String, default: null },
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    phone: { type: String, trim: true, default: '' },
    photoUrl: { type: String, default: null },
    authProvider: {
      type: String,
      enum: ['email_password', 'google', 'phone_otp'],
      default: 'email_password',
    },
    password: { type: String, select: false },
    isActive: { type: Boolean, default: true },
    isBlocked: { type: Boolean, default: false },
    profileCompleted: { type: Boolean, default: false },
    lastLoginAt: { type: Date, default: null },
  },
  { timestamps: true },
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidate) {
  return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('User', userSchema);
