const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const User = require('../models/User');
const Customer = require('../models/Customer');
const { sendTokenResponse } = require('../utils/jwt');
const { protect } = require('../middleware/auth');
const {
  generateOtp,
  storeOtp,
  verifyOtp,
  dispatchOtp,
  exposeOtpInResponse,
} = require('../services/otpService');
const { phoneDigits } = require('../utils/phone');
const logger = require('../utils/logger');

async function findCustomerByPhone(phone) {
  const last10 = phoneDigits(phone);
  if (last10.length < 10) return null;
  return Customer.findOne({
    status: { $ne: 'deleted' },
    phoneLast10: last10,
  });
}

// POST /api/auth/login — admin or driver
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').notEmpty().withMessage('Password required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { email, password } = req.body;
      const user = await User.findOne({
        email: email.toLowerCase().trim(),
        role: { $in: ['shop_admin', 'driver'] },
      }).select('+password');

      if (!user || !(await user.comparePassword(password))) {
        return res.status(401).json({ success: false, message: 'Invalid email or password' });
      }

      if (!user.isActive || user.isBlocked) {
        return res.status(403).json({ success: false, message: 'Account is inactive or blocked' });
      }

      user.lastLoginAt = new Date();
      await user.save({ validateBeforeSave: false });

      sendTokenResponse(res, user);
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
);

// POST /api/auth/register — register a new shop admin
router.post(
  '/register',
  [
    body('name').notEmpty().trim().withMessage('Name required'),
    body('businessName').notEmpty().trim().withMessage('Business name required'),
    body('phone').isMobilePhone().withMessage('Valid phone required'),
    body('email').isEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { name, businessName, phone, email, password, shopId } = req.body;
      const normalized = email.toLowerCase().trim();

      const existing = await User.findOne({ email: normalized });
      if (existing) {
        return res.status(400).json({ success: false, message: 'Email already registered' });
      }

      const uid = uuidv4();
      const resolvedShopId = shopId || `shop-${uid.substring(0, 8)}`;

      const user = await User.create({
        uid,
        role: 'shop_admin',
        shopId: resolvedShopId,
        name: name.trim(),
        email: normalized,
        phone: phone.trim(),
        password,
        profileCompleted: true,
        isActive: true,
      });

      sendTokenResponse(res, user, 201);
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
);

// POST /api/auth/customer/request-otp — send OTP to registered customer phone (dev returns OTP)
router.post('/customer/request-otp', async (req, res) => {
  try {
    const digits = phoneDigits(req.body.phone);
    if (digits.length < 10) {
      return res.status(400).json({ success: false, message: 'Valid 10-digit mobile number required' });
    }

    const customer = await findCustomerByPhone(digits);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'This mobile number is not added by a water plant admin.',
      });
    }

    const otp = generateOtp();
    await storeOtp({
      key: digits,
      purpose: 'customer_login',
      otp,
      meta: { customerId: customer.customerId, shopId: customer.shopId },
    });
    await dispatchOtp({ channel: 'sms', to: digits, otp, purpose: 'customer_login' });

    const payload = {
      success: true,
      message: 'OTP sent',
    };
    if (exposeOtpInResponse()) {
      payload.otp = otp;
    }
    logger.info('Customer OTP requested', { phone: digits.slice(-4) });
    res.status(200).json(payload);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/customer/verify-otp — verify OTP and sign in customer
router.post('/customer/verify-otp', async (req, res) => {
  try {
    const digits = phoneDigits(req.body.phone);
    const { otp } = req.body;
    if (digits.length < 10 || !otp) {
      return res.status(400).json({ success: false, message: 'Phone and OTP required' });
    }

    const verified = await verifyOtp({
      key: digits,
      purpose: 'customer_login',
      otp: String(otp).trim(),
    });
    if (!verified.ok) {
      return res.status(400).json({ success: false, message: verified.message });
    }

    const customer = await Customer.findOne({
      customerId: verified.meta.customerId,
      shopId: verified.meta.shopId,
    });
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'This mobile number is not added by a water plant admin.',
      });
    }

    let user = null;
    if (customer.appUserId) {
      user = await User.findOne({ uid: customer.appUserId, role: 'customer' });
    }
    if (!user) {
      user = await User.findOne({ phone: digits, role: 'customer' });
    }

    if (!user) {
      const uid = uuidv4();
      user = await User.create({
        uid,
        role: 'customer',
        name: customer.name,
        email: `${digits}@customer.srisai.local`,
        phone: digits,
        authProvider: 'phone_otp',
        profileCompleted: true,
        customerProfileId: customer.customerId,
        isActive: true,
      });
    }

    const samePhoneCustomers = await Customer.find({
      shopId: customer.shopId,
      phoneLast10: digits,
    });
    for (const row of samePhoneCustomers) {
      row.appUserId = user.uid;
      row.customerType = 'app_customer';
      await row.save({ validateBeforeSave: false });
    }

    user.lastLoginAt = new Date();
    user.name = customer.name;
    user.phone = digits;
    user.customerProfileId = customer.customerId;
    user.profileCompleted = true;
    await user.save({ validateBeforeSave: false });

    sendTokenResponse(res, user);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/customer/google — customer Google login
router.post('/customer/google', async (req, res) => {
  try {
    const { idToken, name, email, phone, photoUrl } = req.body;
    const config = require('../config/env');

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email required from Google token' });
    }

    if (config.isProduction && !idToken) {
      return res.status(400).json({ success: false, message: 'Google idToken required in production' });
    }
    // Production: verify idToken with Firebase Admin / Google OAuth (configure separately).

    let user = await User.findOne({ email: email.toLowerCase().trim(), role: 'customer' });

    if (!user) {
      const uid = uuidv4();
      user = await User.create({
        uid,
        role: 'customer',
        name: name || 'Customer',
        email: email.toLowerCase().trim(),
        phone: phone || '',
        photoUrl: photoUrl || null,
        authProvider: 'google',
        profileCompleted: false,
        isActive: true,
      });
    }

    user.lastLoginAt = new Date();
    await user.save({ validateBeforeSave: false });

    sendTokenResponse(res, user);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/logout
router.post('/logout', protect, (req, res) => {
  res.status(200).json({ success: true, message: 'Logged out' });
});

// GET /api/auth/me
router.get('/me', protect, (req, res) => {
  res.status(200).json({ success: true, user: req.user });
});

// PATCH /api/auth/me — update current user profile flags
router.patch('/me', protect, async (req, res) => {
  try {
    const { name, profileCompleted } = req.body;
    const user = await User.findOne({ uid: req.user.uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    if (name !== undefined && String(name).trim()) {
      user.name = String(name).trim();
    }
    if (profileCompleted !== undefined) {
      user.profileCompleted = Boolean(profileCompleted);
    }
    await user.save({ validateBeforeSave: false });
    res.status(200).json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/forgot-password
router.post(
  '/forgot-password',
  [body('email').isEmail().withMessage('Valid email required')],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { email } = req.body;
      const normalized = email.toLowerCase().trim();
      const user = await User.findOne({ email: normalized, role: { $in: ['shop_admin', 'driver'] } });

      if (!user) {
        // Don't reveal if email exists
        return res.status(200).json({ success: true, message: 'If account exists, reset instructions sent' });
      }

      // In production: send email with reset link. For dev: return OTP in response.
      const otp = generateOtp();
      await storeOtp({
        key: normalized,
        purpose: 'password_reset',
        otp,
      });
      await dispatchOtp({ channel: 'email', to: normalized, otp, purpose: 'password_reset' });

      const payload = {
        success: true,
        message: exposeOtpInResponse() ? 'OTP sent' : 'If account exists, reset instructions sent',
      };
      if (exposeOtpInResponse()) {
        payload.otp = otp;
      }
      res.status(200).json(payload);
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
);

// POST /api/auth/reset-password
router.post(
  '/reset-password',
  [
    body('email').isEmail(),
    body('otp').notEmpty(),
    body('newPassword').isLength({ min: 6 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { email, otp, newPassword } = req.body;
      const normalized = email.toLowerCase().trim();

      const verified = await verifyOtp({
        key: normalized,
        purpose: 'password_reset',
        otp: String(otp).trim(),
      });
      if (!verified.ok) {
        return res.status(400).json({ success: false, message: verified.message });
      }

      const user = await User.findOne({ email: normalized }).select('+password');
      if (!user) {
        return res.status(404).json({ success: false, message: 'Account not found' });
      }

      user.password = newPassword;
      await user.save();

      res.status(200).json({ success: true, message: 'Password reset successful' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
);

// POST /api/auth/driver — admin creates a driver login
router.post('/driver', protect, async (req, res) => {
  try {
    const { driverId, name, phone, email, password, shopId } = req.body;
    if (!driverId || !name || !email || !password) {
      return res.status(400).json({ success: false, message: 'driverId, name, email, password required' });
    }

    const normalized = email.toLowerCase().trim();
    const existing = await User.findOne({ email: normalized });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email already used' });
    }

    const uid = uuidv4();
    const user = await User.create({
      uid,
      role: 'driver',
      shopId: shopId || req.user.shopId,
      driverId,
      name: name.trim(),
      email: normalized,
      phone: phone || '',
      password,
      profileCompleted: true,
      isActive: true,
    });

    res.status(201).json({ success: true, user: { uid: user.uid, email: user.email, role: user.role } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
