const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Order = require('../models/Order');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, customerOnly, adminOrDriver } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/orders — list orders (admin/driver)
router.get('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { status, customerId, driverId, limit = 50, skip = 0 } = req.query;
    const filter = { shopId: req.user.shopId };
    if (status) filter.orderStatus = status;
    if (customerId) filter.customerId = customerId;
    if (driverId) filter.assignedDriverId = driverId;

    const orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Order.countDocuments(filter);
    res.status(200).json({ success: true, orders, total });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/orders/:id
router.get('/:id', protect, adminOrDriver, async (req, res) => {
  try {
    const order = await Order.findOne({ orderId: req.params.id, shopId: req.user.shopId });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/orders — customer places order
router.post('/', protect, customerOnly, async (req, res) => {
  try {
    const { shopId, normalQty, coolQty, customerNote, deliveryAddress, deliveryLatitude, deliveryLongitude } = req.body;
    if (!shopId || (normalQty + coolQty) <= 0) {
      return res.status(400).json({ success: false, message: 'shopId and at least 1 can required' });
    }

    const orderId = uuidv4();
    const order = await Order.create({
      orderId,
      shopId,
      customerId: req.user.customerProfileId || req.user.uid,
      appUserId: req.user.uid,
      customerName: req.user.name,
      customerPhone: req.user.phone,
      deliveryAddress: deliveryAddress || '',
      deliveryLatitude: deliveryLatitude || null,
      deliveryLongitude: deliveryLongitude || null,
      normalQty: normalQty || 0,
      coolQty: coolQty || 0,
      customerNote: customerNote || null,
      orderStatus: 'pending',
    });

    res.status(201).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/orders/:id/accept — admin accepts order
router.patch('/:id/accept', protect, adminOnly, async (req, res) => {
  try {
    const { adminNote } = req.body;
    const order = await Order.findOneAndUpdate(
      { orderId: req.params.id, shopId: req.user.shopId, orderStatus: 'pending' },
      { orderStatus: 'accepted', adminNote: adminNote || null, acceptedAt: new Date() },
      { new: true },
    );
    if (!order) return res.status(404).json({ success: false, message: 'Order not found or already processed' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'ACCEPT_ORDER', entityType: 'order', entityId: req.params.id,
    });

    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/orders/:id/reject — admin rejects order
router.patch('/:id/reject', protect, adminOnly, async (req, res) => {
  try {
    const { adminNote } = req.body;
    const order = await Order.findOneAndUpdate(
      { orderId: req.params.id, shopId: req.user.shopId, orderStatus: 'pending' },
      { orderStatus: 'rejected', adminNote: adminNote || null, rejectedAt: new Date() },
      { new: true },
    );
    if (!order) return res.status(404).json({ success: false, message: 'Order not found or already processed' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'REJECT_ORDER', entityType: 'order', entityId: req.params.id,
    });

    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/orders/:id/assign — admin assigns driver
router.patch('/:id/assign', protect, adminOnly, async (req, res) => {
  try {
    const { driverId, driverName } = req.body;
    const order = await Order.findOneAndUpdate(
      { orderId: req.params.id, shopId: req.user.shopId },
      { assignedDriverId: driverId, assignedDriverName: driverName || null, orderStatus: 'assigned', assignedAt: new Date() },
      { new: true },
    );
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'ASSIGN_DRIVER', entityType: 'order', entityId: req.params.id, newData: { driverId },
    });

    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/orders/:id/status — update order status (driver)
router.patch('/:id/status', protect, adminOrDriver, async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['out_for_delivery', 'delivered', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ success: false, message: `Status must be one of: ${allowed.join(', ')}` });
    }

    const update = { orderStatus: status };
    if (status === 'out_for_delivery') update.outForDeliveryAt = new Date();
    if (status === 'delivered') update.deliveredAt = new Date();
    if (status === 'cancelled') update.cancelledAt = new Date();

    const order = await Order.findOneAndUpdate(
      { orderId: req.params.id, shopId: req.user.shopId },
      update,
      { new: true },
    );
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: `ORDER_STATUS_${status.toUpperCase()}`, entityType: 'order', entityId: req.params.id,
    });

    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/orders/customer/mine — customer's own orders
router.get('/customer/mine', protect, customerOnly, async (req, res) => {
  try {
    const orders = await Order.find({ appUserId: req.user.uid }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/orders/:id — cancel order by customer
router.delete('/:id', protect, customerOnly, async (req, res) => {
  try {
    const order = await Order.findOneAndUpdate(
      { orderId: req.params.id, appUserId: req.user.uid, orderStatus: 'pending' },
      { orderStatus: 'cancelled', cancelledAt: new Date() },
      { new: true },
    );
    if (!order) return res.status(404).json({ success: false, message: 'Order not found or cannot be cancelled' });
    res.status(200).json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
