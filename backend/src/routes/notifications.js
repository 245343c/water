const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');
const logger = require('../utils/logger');

function buildNotificationFilter(user, query) {
  const limit = Math.min(parseInt(query.limit, 10) || 50, 100);
  const skip = parseInt(query.skip, 10) || 0;

  if (user.role === 'customer') {
    const filter = {
      $or: [
        { targetUid: user.uid },
        { audience: 'customer', customerId: user.customerProfileId },
      ],
    };
    if (query.unread === 'true') filter.read = false;
    return { filter, limit, skip };
  }

  const filter = {
    shopId: user.shopId,
    $or: [
      { targetUid: user.uid },
      { audience: user.role },
      { audience: 'all' },
    ],
  };
  if (query.unread === 'true') filter.read = false;
  return { filter, limit, skip };
}

function canAccessNotification(user, notif) {
  if (user.role === 'customer') {
    return (
      notif.targetUid === user.uid ||
      (notif.audience === 'customer' && notif.customerId === user.customerProfileId)
    );
  }
  if (notif.shopId !== user.shopId) return false;
  if (notif.targetUid && notif.targetUid === user.uid) return true;
  if (notif.audience === 'all') return true;
  if (notif.audience === user.role) return true;
  return false;
}

// GET /api/notifications — get my notifications (paginated)
router.get('/', protect, async (req, res) => {
  try {
    const { filter, limit, skip } = buildNotificationFilter(req.user, req.query);

    const [notifications, unreadCount, total] = await Promise.all([
      Notification.find(filter).sort({ createdAt: -1 }).limit(limit).skip(skip),
      Notification.countDocuments({ ...filter, read: false }),
      Notification.countDocuments(filter),
    ]);

    res.status(200).json({ success: true, notifications, unreadCount, total, limit, skip });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/notifications/:id/read — mark read (owner only)
router.patch('/:id/read', protect, async (req, res) => {
  try {
    const notif = await Notification.findOne({ notificationId: req.params.id });
    if (!notif) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    if (!canAccessNotification(req.user, notif)) {
      return res.status(403).json({ success: false, message: 'Not allowed' });
    }

    notif.read = true;
    notif.readAt = new Date();
    await notif.save();

    res.status(200).json({ success: true, notification: notif });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/notifications/read-all — mark all notifications read for current user
router.patch('/read-all', protect, async (req, res) => {
  try {
    const { filter } = buildNotificationFilter(req.user, req.query);
    const result = await Notification.updateMany(
      { ...filter, read: false },
      { $set: { read: true, readAt: new Date() } },
    );
    res.status(200).json({
      success: true,
      updated: result.modifiedCount ?? result.nModified ?? 0,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/notifications — admin sends notification
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { v4: uuidv4 } = require('uuid');
    const { type, title, body, audience, targetUid, customerId, driverId, orderId, deliveryId } = req.body;
    if (!type || !title) {
      return res.status(400).json({ success: false, message: 'type and title required' });
    }

    const notif = await Notification.create({
      notificationId: uuidv4(),
      shopId: req.user.shopId,
      type,
      title,
      body: body || '',
      audience: audience || 'admin',
      targetUid: targetUid || null,
      customerId: customerId || null,
      driverId: driverId || null,
      orderId: orderId || null,
      deliveryId: deliveryId || null,
    });

    logger.info('Admin notification sent', { type, audience: notif.audience, shopId: req.user.shopId });
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
