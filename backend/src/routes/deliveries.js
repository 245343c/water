const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Delivery = require('../models/Delivery');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, adminOrDriver } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/deliveries — list deliveries (admin/driver)
router.get('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { customerId, driverId, date, startDate, endDate, limit = 50, skip = 0 } = req.query;
    const filter = { shopId: req.user.shopId };
    if (customerId) filter.customerId = customerId;
    if (driverId) filter.driverId = driverId;
    if (date) {
      const d = new Date(date);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);
      filter.deliveryDate = { $gte: d, $lt: next };
    } else if (startDate || endDate) {
      filter.deliveryDate = {};
      if (startDate) filter.deliveryDate.$gte = new Date(startDate);
      if (endDate) filter.deliveryDate.$lte = new Date(endDate);
    }

    const deliveries = await Delivery.find(filter)
      .sort({ deliveryDate: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Delivery.countDocuments(filter);
    res.status(200).json({ success: true, deliveries, total });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/deliveries/:id
router.get('/:id', protect, adminOrDriver, async (req, res) => {
  try {
    const delivery = await Delivery.findOne({ deliveryId: req.params.id, shopId: req.user.shopId });
    if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });
    res.status(200).json({ success: true, delivery });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/deliveries — record manual delivery (admin or driver)
router.post('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { customerId, deliveryDate, lines, notes, orderId, deliveryType } = req.body;
    if (!customerId || !lines || lines.length === 0) {
      return res.status(400).json({ success: false, message: 'customerId and lines required' });
    }

    const customer = await Customer.findOne({ customerId, shopId: req.user.shopId });
    const totalAmount = lines.reduce((sum, l) => sum + (l.quantity * l.unitPrice), 0);

    // Add lineTotal to each line
    const processedLines = lines.map((l) => ({
      ...l,
      lineTotal: l.quantity * l.unitPrice,
    }));

    const deliveryId = uuidv4();
    const delivery = await Delivery.create({
      deliveryId,
      shopId: req.user.shopId,
      orderId: orderId || null,
      customerId,
      customerName: customer?.name || '',
      customerPhone: customer?.phone || '',
      driverId: req.user.role === 'driver' ? (req.user.driverId || null) : (req.body.driverId || null),
      deliveryDate: deliveryDate ? new Date(deliveryDate) : new Date(),
      lines: processedLines,
      totalAmount,
      deliveryType: deliveryType || 'manual_delivery',
      recordedByUid: req.user.uid,
      recordedByRole: req.user.role,
      notes: notes || null,
    });

    // Update customer's lastDeliveryAt and totalPendingAmount
    if (customer) {
      await Customer.findOneAndUpdate(
        { customerId, shopId: req.user.shopId },
        { lastDeliveryAt: delivery.deliveryDate, $inc: { totalPendingAmount: totalAmount } },
      );
    }

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'CREATE_DELIVERY', entityType: 'delivery', entityId: deliveryId, newData: delivery,
    });

    res.status(201).json({ success: true, delivery });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/deliveries/:id — update delivery
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const allowed = ['deliveryDate', 'lines', 'notes', 'cashCollectionStatus'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    if (updates.lines) {
      updates.totalAmount = updates.lines.reduce((sum, l) => sum + (l.quantity * l.unitPrice), 0);
      updates.lines = updates.lines.map((l) => ({ ...l, lineTotal: l.quantity * l.unitPrice }));
    }

    const delivery = await Delivery.findOneAndUpdate(
      { deliveryId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );
    if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'UPDATE_DELIVERY', entityType: 'delivery', entityId: req.params.id, newData: updates,
    });

    res.status(200).json({ success: true, delivery });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/deliveries/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const delivery = await Delivery.findOneAndDelete({ deliveryId: req.params.id, shopId: req.user.shopId });
    if (!delivery) return res.status(404).json({ success: false, message: 'Delivery not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'DELETE_DELIVERY', entityType: 'delivery', entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Delivery deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
