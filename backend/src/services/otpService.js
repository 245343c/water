const bcrypt = require('bcryptjs');
const OtpCode = require('../models/OtpCode');
const logger = require('../utils/logger');

const OTP_TTL_MS = 10 * 60 * 1000;
const isProd = process.env.NODE_ENV === 'production';

function generateOtp() {
  if (!isProd && process.env.CUSTOMER_DEMO_OTP) {
    return process.env.CUSTOMER_DEMO_OTP;
  }
  if (!isProd && process.env.NODE_ENV !== 'production') {
    return process.env.CUSTOMER_DEMO_OTP || '123456';
  }
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function storeOtp({ key, purpose, otp, meta = {} }) {
  const otpHash = await bcrypt.hash(otp, 10);
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  await OtpCode.findOneAndUpdate(
    { key },
    { key, purpose, otpHash, attempts: 0, maxAttempts: 5, expiresAt, meta },
    { upsert: true, new: true },
  );
  logger.info('OTP stored', { purpose, key: key.slice(0, 4) + '***' });
  return otp;
}

async function verifyOtp({ key, purpose, otp }) {
  const record = await OtpCode.findOne({ key, purpose });
  if (!record) return { ok: false, message: 'Send OTP first' };
  if (record.expiresAt < new Date()) {
    await OtpCode.deleteOne({ _id: record._id });
    return { ok: false, message: 'OTP expired. Request again' };
  }
  if (record.attempts >= record.maxAttempts) {
    await OtpCode.deleteOne({ _id: record._id });
    return { ok: false, message: 'Too many attempts. Request again' };
  }
  const match = await bcrypt.compare(String(otp).trim(), record.otpHash);
  if (!match) {
    record.attempts += 1;
    await record.save();
    return { ok: false, message: 'Invalid OTP' };
  }
  await OtpCode.deleteOne({ _id: record._id });
  return { ok: true, meta: record.meta };
}

async function dispatchOtp({ channel, to, otp, purpose }) {
  // Production: plug SMS (MSG91/Twilio) or email here.
  if (isProd) {
    logger.info('OTP dispatch (configure SMS/email provider)', { channel, to: String(to).slice(-4), purpose });
    return;
  }
  logger.debug('OTP dispatch dev mode', { channel, to, purpose, otp });
}

module.exports = {
  generateOtp,
  storeOtp,
  verifyOtp,
  dispatchOtp,
  isProd,
};
