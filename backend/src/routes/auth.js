const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const User = require('../models/User');
const Customer = require('../models/Customer');
const { sendTokenResponse } = require('../utils/jwt');
const { protect } = require('../middleware/auth');

function phoneDigits(phone) {
  const digits = String(phone || '').replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : digits;
}

async function findCustomerByPhone(phone) {
  const last10 = phoneDigits(phone);
  if (last10.length < 10) return null;
  const customers = await Customer.find({ status: { $ne: 'deleted' } });
  return customers.find((c) => phoneDigits(c.phone) === last10) || null;
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

    const demoOtp = process.env.CUSTOMER_DEMO_OTP || '123456';
    const otp =
      process.env.NODE_ENV === 'production'
        ? Math.floor(100000 + Math.random() * 900000).toString()
        : demoOtp;

    global._customerOtpStore = global._customerOtpStore || {};
    global._customerOtpStore[digits] = {
      otp,
      expiresAt: Date.now() + 10 * 60 * 1000,
      customerId: customer.customerId,
      shopId: customer.shopId,
    };

    const payload = {
      success: true,
      message: 'OTP sent',
    };
    if (process.env.NODE_ENV !== 'production') {
      payload.otp = otp;
    }
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

    global._customerOtpStore = global._customerOtpStore || {};
    const pending = global._customerOtpStore[digits];
    if (!pending) {
      return res.status(400).json({ success: false, message: 'Send OTP to your phone first' });
    }
    if (Date.now() > pending.expiresAt) {
      delete global._customerOtpStore[digits];
      return res.status(400).json({ success: false, message: 'OTP expired. Request again' });
    }
    if (String(otp).trim() !== pending.otp) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
    delete global._customerOtpStore[digits];

    const customer = await Customer.findOne({
      customerId: pending.customerId,
      shopId: pending.shopId,
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

    const samePhoneCustomers = await Customer.find({ shopId: customer.shopId });
    for (const row of samePhoneCustomers) {
      if (phoneDigits(row.phone) === digits) {
        row.appUserId = user.uid;
        row.customerType = 'app_customer';
        await row.save({ validateBeforeSave: false });
      }
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

// POST /api/auth/customer/google — customer Google login (verifies idToken in production)
router.post('/customer/google', async (req, res) => {
  try {
    const { idToken, name, email, phone, photoUrl } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email required from Google token' });
    }

    // In production: verify idToken with Firebase Admin SDK
    // For local dev: trust the payload directly
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
      const user = await User.findOne({ email: email.toLowerCase().trim(), role: { $in: ['shop_admin', 'driver'] } });

      if (!user) {
        // Don't reveal if email exists
        return res.status(200).json({ success: true, message: 'If account exists, reset instructions sent' });
      }

      // In production: send email with reset link. For local dev: return OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      // Store OTP temporarily (in production use Redis/DB; here we use a simple in-memory store)
      global._otpStore = global._otpStore || {};
      global._otpStore[email.toLowerCase()] = {
        otp,
        expiresAt: Date.now() + 10 * 60 * 1000,
      };

      res.status(200).json({
        success: true,
        message: 'OTP sent (dev mode: OTP returned in response)',
        otp, // Remove in production
      });
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

      global._otpStore = global._otpStore || {};
      const pending = global._otpStore[normalized];

      if (!pending || pending.otp !== otp || Date.now() > pending.expiresAt) {
        return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
      }

      const user = await User.findOne({ email: normalized }).select('+password');
      if (!user) {
        return res.status(404).json({ success: false, message: 'Account not found' });
      }

      user.password = newPassword;
      await user.save();
      delete global._otpStore[normalized];

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
