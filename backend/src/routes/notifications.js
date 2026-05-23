const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Notification = require('../models/Notification');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');

// GET /api/notifications — get my notifications
router.get('/', protect, async (req, res) => {
  try {
    const filter = {
      shopId: req.user.shopId,
      $or: [{ targetUid: req.user.uid }, { audience: req.user.role }, { audience: 'all' }],
    };
    if (req.query.unread === 'true') filter.read = false;

    const notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(50);
    const unreadCount = await Notification.countDocuments({ ...filter, read: false });
    res.status(200).json({ success: true, notifications, unreadCount });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', protect, async (req, res) => {
  try {
    const notif = await Notification.findOneAndUpdate(
      { notificationId: req.params.id },
      { read: true, readAt: new Date() },
      { new: true },
    );
    if (!notif) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.status(200).json({ success: true, notification: notif });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/notifications — admin sends notification
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { type, title, body, audience, targetUid, customerId, driverId, orderId, deliveryId } = req.body;
    if (!type || !title) {
      return res.status(400).json({ success: false, message: 'type and title required' });
    }

    const notif = await Notification.create({
      notificationId: uuidv4(),
      shopId: req.user.shopId,
      type, title,
      body: body || '',
      audience: audience || 'admin',
      targetUid: targetUid || null,
      customerId: customerId || null,
      driverId: driverId || null,
      orderId: orderId || null,
      deliveryId: deliveryId || null,
    });

    res.status(201).json({ success: true, notification: notif });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/notifications/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    await Notification.findOneAndDelete({ notificationId: req.params.id, shopId: req.user.shopId });
    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
