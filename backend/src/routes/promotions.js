const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Promotion = require('../models/Promotion');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/promotions — list all active promotions (public for customer app)
router.get('/', async (req, res) => {
  try {
    const { shopId, active } = req.query;
    const filter = {};
    if (shopId) filter.shopId = shopId;
    if (active !== 'false') filter.isActive = true;

    const promotions = await Promotion.find(filter).sort({ createdAt: -1 });
    res.status(200).json({ success: true, promotions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/promotions/:id
router.get('/:id', protect, async (req, res) => {
  try {
    const promo = await Promotion.findOne({ promotionId: req.params.id });
    if (!promo) return res.status(404).json({ success: false, message: 'Promotion not found' });
    res.status(200).json({ success: true, promotion: promo });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/promotions — create promotion
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { headline, body, mediaUrl, mediaType, badge, ctaLabel, startsAt, endsAt } = req.body;
    if (!headline) return res.status(400).json({ success: false, message: 'headline required' });

    const promotionId = uuidv4();
    const promo = await Promotion.create({
      promotionId,
      shopId: req.user.shopId,
      headline,
      body: body || '',
      mediaUrl: mediaUrl || null,
      mediaType: mediaType || 'image',
      badge: badge || null,
      ctaLabel: ctaLabel || null,
      isActive: true,
      startsAt: startsAt ? new Date(startsAt) : null,
      endsAt: endsAt ? new Date(endsAt) : null,
    });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'CREATE_PROMOTION', entityType: 'promotion', entityId: promotionId, newData: promo,
    });

    res.status(201).json({ success: true, promotion: promo });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/promotions/:id
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const allowed = ['headline', 'body', 'mediaUrl', 'mediaType', 'badge', 'ctaLabel', 'isActive', 'startsAt', 'endsAt'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const promo = await Promotion.findOneAndUpdate(
      { promotionId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );
    if (!promo) return res.status(404).json({ success: false, message: 'Promotion not found' });
    res.status(200).json({ success: true, promotion: promo });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/promotions/:id/active
router.patch('/:id/active', protect, adminOnly, async (req, res) => {
  try {
    const { active } = req.body;
    const promo = await Promotion.findOneAndUpdate(
      { promotionId: req.params.id, shopId: req.user.shopId },
      { isActive: active },
      { new: true },
    );
    if (!promo) return res.status(404).json({ success: false, message: 'Promotion not found' });
    res.status(200).json({ success: true, promotion: promo });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/promotions/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    await Promotion.findOneAndDelete({ promotionId: req.params.id, shopId: req.user.shopId });
    res.status(200).json({ success: true, message: 'Promotion deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
