const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { adminOnly, driverOnly } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/drivers — list drivers for shop (admin only)
router.get('/', protect, adminOnly, async (req, res) => {
  try {
    const drivers = await Driver.find({ shopId: req.user.shopId }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, drivers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/drivers/:id
router.get('/:id', protect, adminOnly, async (req, res) => {
  try {
    const driver = await Driver.findOne({ driverId: req.params.id, shopId: req.user.shopId });
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });
    res.status(200).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/drivers — create driver
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { name, phone, email, assignedArea, vehicleNumber } = req.body;
    if (!name || !phone) {
      return res.status(400).json({ success: false, message: 'name and phone required' });
    }

    const driverId = uuidv4();
    const driver = await Driver.create({
      driverId,
      shopId: req.user.shopId,
      name: name.trim(),
      phone: phone.trim(),
      email: email || '',
      assignedArea: assignedArea || '',
      vehicleNumber: vehicleNumber || '',
    });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'CREATE_DRIVER', entityType: 'driver', entityId: driverId, newData: driver,
    });

    res.status(201).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/drivers/:id — update driver
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const allowed = ['name', 'phone', 'email', 'assignedArea', 'vehicleNumber', 'photoUrl'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const driver = await Driver.findOneAndUpdate(
      { driverId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'UPDATE_DRIVER', entityType: 'driver', entityId: req.params.id, newData: updates,
    });

    res.status(200).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/drivers/:id/active — activate or deactivate
router.patch('/:id/active', protect, adminOnly, async (req, res) => {
  try {
    const { active } = req.body;
    const driver = await Driver.findOneAndUpdate(
      { driverId: req.params.id, shopId: req.user.shopId },
      { active },
      { new: true },
    );
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: active ? 'ACTIVATE_DRIVER' : 'DEACTIVATE_DRIVER', entityType: 'driver', entityId: req.params.id,
    });

    res.status(200).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/drivers/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const driver = await Driver.findOneAndDelete({ driverId: req.params.id, shopId: req.user.shopId });
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'DELETE_DRIVER', entityType: 'driver', entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Driver deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/drivers/me/profile — driver profile
router.get('/me/profile', protect, driverOnly, async (req, res) => {
  try {
    const driver = await Driver.findOne({ uid: req.user.uid });
    if (!driver) return res.status(404).json({ success: false, message: 'Driver profile not found' });
    res.status(200).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/drivers/me/availability
router.patch('/me/availability', protect, driverOnly, async (req, res) => {
  try {
    const { active } = req.body;
    const driver = await Driver.findOneAndUpdate(
      { uid: req.user.uid },
      { active, lastActiveAt: active ? new Date() : undefined },
      { new: true },
    );
    if (!driver) return res.status(404).json({ success: false, message: 'Driver not found' });
    res.status(200).json({ success: true, driver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
