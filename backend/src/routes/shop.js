const express = require('express');
const router = express.Router();
const Shop = require('../models/Shop');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/shop — get current admin's shop
router.get('/', protect, adminOnly, async (req, res) => {
  try {
    const shop = await Shop.findOne({ shopId: req.user.shopId });
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });
    res.status(200).json({ success: true, shop });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/shop — update shop settings
router.put('/', protect, adminOnly, async (req, res) => {
  try {
    const allowed = [
      'shopName', 'phone', 'email', 'address', 'place', 'latitude', 'longitude',
      'homeDeliveryAvailable', 'isListed', 'normalCanPrice', 'coolCanPrice',
      'deliveryCharge', 'minimumOrderQuantity', 'acceptingOrders', 'workingHours',
      'invoicePrefix', 'billDueDays', 'tagline',
    ];
    const updates = {};
    allowed.forEach((key) => {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    });

    const old = await Shop.findOne({ shopId: req.user.shopId }).lean();
    const shop = await Shop.findOneAndUpdate(
      { shopId: req.user.shopId },
      updates,
      { new: true, upsert: true },
    );

    await writeAuditLog({
      shopId: req.user.shopId,
      actorUid: req.user.uid,
      actorRole: req.user.role,
      action: 'UPDATE_SHOP_SETTINGS',
      entityType: 'shop',
      entityId: req.user.shopId,
      oldData: old,
      newData: updates,
    });

    res.status(200).json({ success: true, shop });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/shop/public/:shopId — customer app
router.get('/public/:shopId', async (req, res) => {
  try {
    const shop = await Shop.findOne({ shopId: req.params.shopId, isListed: true });
    if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });
    res.status(200).json({ success: true, shop });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/shop/listed — list all listed shops for customer app
router.get('/listed', async (req, res) => {
  try {
    const { q } = req.query;
    const filter = { isListed: true };
    if (q) {
      filter.$or = [
        { shopName: { $regex: q, $options: 'i' } },
        { place: { $regex: q, $options: 'i' } },
        { address: { $regex: q, $options: 'i' } },
      ];
    }
    const shops = await Shop.find(filter).sort({ rating: -1 });
    res.status(200).json({ success: true, shops });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
