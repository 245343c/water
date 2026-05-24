const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const DeliveryRoute = require('../models/DeliveryRoute');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, adminOrDriver } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/delivery-routes — list routes for shop
router.get('/', protect, adminOrDriver, async (req, res) => {
  try {
    const routes = await DeliveryRoute.find({ shopId: req.user.shopId })
      .sort({ sortOrder: 1, name: 1 });
    res.status(200).json({ success: true, routes });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/delivery-routes — create route (admin)
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    if (!name) {
      return res.status(400).json({ success: false, message: 'name is required' });
    }

    const existing = await DeliveryRoute.findOne({
      shopId: req.user.shopId,
      name: { $regex: new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
    });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Route already exists' });
    }

    const routeId = uuidv4();
    const route = await DeliveryRoute.create({
      routeId,
      shopId: req.user.shopId,
      name,
    });

    await writeAuditLog({
      shopId: req.user.shopId,
      actorUid: req.user.uid,
      actorRole: req.user.role,
      action: 'CREATE_DELIVERY_ROUTE',
      entityType: 'delivery_route',
      entityId: routeId,
      newData: route,
    });

    res.status(201).json({ success: true, route });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/delivery-routes/:id — rename or activate/deactivate
router.patch('/:id', protect, adminOnly, async (req, res) => {
  try {
    const old = await DeliveryRoute.findOne({
      routeId: req.params.id,
      shopId: req.user.shopId,
    }).lean();
    if (!old) {
      return res.status(404).json({ success: false, message: 'Route not found' });
    }

    const updates = {};
    if (req.body.name !== undefined) {
      const name = String(req.body.name).trim();
      if (!name) {
        return res.status(400).json({ success: false, message: 'name cannot be empty' });
      }
      const duplicate = await DeliveryRoute.findOne({
        shopId: req.user.shopId,
        routeId: { $ne: req.params.id },
        name: { $regex: new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
      });
      if (duplicate) {
        return res.status(409).json({ success: false, message: 'Route already exists' });
      }
      updates.name = name;
    }
    if (req.body.active !== undefined) updates.active = Boolean(req.body.active);

    const route = await DeliveryRoute.findOneAndUpdate(
      { routeId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );

    await writeAuditLog({
      shopId: req.user.shopId,
      actorUid: req.user.uid,
      actorRole: req.user.role,
      action: 'UPDATE_DELIVERY_ROUTE',
      entityType: 'delivery_route',
      entityId: req.params.id,
      oldData: old,
      newData: updates,
    });

    res.status(200).json({ success: true, route });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/delivery-routes/:id — remove route if no customers assigned
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const route = await DeliveryRoute.findOne({
      routeId: req.params.id,
      shopId: req.user.shopId,
    });
    if (!route) {
      return res.status(404).json({ success: false, message: 'Route not found' });
    }

    const assigned = await Customer.countDocuments({
      shopId: req.user.shopId,
      routeId: req.params.id,
      status: { $ne: 'deleted' },
    });
    if (assigned > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete route — ${assigned} customer(s) still assigned`,
      });
    }

    await DeliveryRoute.deleteOne({ routeId: req.params.id, shopId: req.user.shopId });

    await writeAuditLog({
      shopId: req.user.shopId,
      actorUid: req.user.uid,
      actorRole: req.user.role,
      action: 'DELETE_DELIVERY_ROUTE',
      entityType: 'delivery_route',
      entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Route deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
