const bcrypt = require('bcryptjs');
const OtpCode = require('../models/OtpCode');
const config = require('../config/env');
const logger = require('../utils/logger');

const OTP_TTL_MS = 10 * 60 * 1000;

function generateOtp() {
  if (config.otpMode === 'local') {
    return config.customerDemoOtp;
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

async function sendSms(to, message) {
  const digits = String(to).replace(/\D/g, '');
  if (config.sms.provider === 'msg91' && config.sms.msg91AuthKey) {
    const url = 'https://control.msg91.com/api/v5/flow/';
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        authkey: config.sms.msg91AuthKey,
      },
      body: JSON.stringify({
        template_id: process.env.MSG91_OTP_TEMPLATE_ID || '',
        recipients: [{ mobiles: digits, var: message }],
      }),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`MSG91 failed: ${text}`);
    }
    return;
  }

  if (config.sms.twilioAccountSid && config.sms.twilioAuthToken && config.sms.twilioFrom) {
    const auth = Buffer.from(
      `${config.sms.twilioAccountSid}:${config.sms.twilioAuthToken}`,
    ).toString('base64');
    const body = new URLSearchParams({
      To: digits.startsWith('91') ? `+${digits}` : `+91${digits.slice(-10)}`,
      From: config.sms.twilioFrom,
      Body: message,
    });
    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${config.sms.twilioAccountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body,
      },
    );
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Twilio SMS failed: ${text}`);
    }
    return;
  }

  if (config.isProduction) {
    throw new Error('SMS provider not configured (set Twilio or MSG91 env vars)');
  }
  logger.warn('SMS not configured — OTP logged only (local mode)', { to: digits.slice(-4) });
}

async function dispatchOtp({ channel, to, otp, purpose }) {
  const message =
    purpose === 'password_reset'
      ? `Sri Sai RO Water password reset code: ${otp}. Valid 10 minutes.`
      : `Sri Sai RO Water login code: ${otp}. Valid 10 minutes. Do not share.`;

  if (config.otpMode === 'local') {
    logger.debug('OTP dispatch (local — not sent)', { channel, to, purpose });
    return;
  }

  if (channel === 'sms') {
    await sendSms(to, message);
    logger.info('OTP SMS sent', { to: String(to).slice(-4), purpose });
    return;
  }

  if (channel === 'email') {
    // Production: integrate SendGrid/SES. Never log OTP in production.
    if (config.isProduction) {
      logger.info('Email OTP dispatch (configure EMAIL provider)', { to, purpose });
      throw new Error('Email OTP provider not configured');
    }
    logger.debug('OTP email (local)', { to, purpose, otp });
  }
}

/** Whether OTP may be returned in HTTP JSON (local dev only). */
function exposeOtpInResponse() {
  return config.otpMode === 'local' && !config.isProduction;
}

module.exports = {
  generateOtp,
  storeOtp,
  verifyOtp,
  dispatchOtp,
  exposeOtpInResponse,
  isProd: config.isProduction,
};
