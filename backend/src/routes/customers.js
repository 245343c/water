const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, adminOrDriver } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/customers — list all customers for shop
router.get('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { q, status, billingMode } = req.query;
    const filter = { shopId: req.user.shopId };
    if (status) filter.status = status;
    if (billingMode) filter.billingMode = billingMode;
    if (q) {
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { phone: { $regex: q.replace(/\D/g, ''), $options: 'i' } },
      ];
    }
    const customers = await Customer.find(filter).sort({ createdAt: -1 });
    res.status(200).json({ success: true, customers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/customers/:id
router.get('/:id', protect, adminOrDriver, async (req, res) => {
  try {
    const customer = await Customer.findOne({ customerId: req.params.id, shopId: req.user.shopId });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });
    res.status(200).json({ success: true, customer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/customers — create customer
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { name, phone, email, address, place, billingMode, productPrices } = req.body;
    if (!name || !phone) {
      return res.status(400).json({ success: false, message: 'name and phone required' });
    }

    const customerId = uuidv4();
    const customer = await Customer.create({
      customerId,
      shopId: req.user.shopId,
      name: name.trim(),
      phone: phone.trim(),
      email: email || '',
      address: address || '',
      place: place || '',
      billingMode: billingMode || 'monthly_contract',
      productPrices: productPrices || [],
    });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'CREATE_CUSTOMER', entityType: 'customer', entityId: customerId, newData: customer,
    });

    res.status(201).json({ success: true, customer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/customers/:id — update customer
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const old = await Customer.findOne({ customerId: req.params.id, shopId: req.user.shopId }).lean();
    if (!old) return res.status(404).json({ success: false, message: 'Customer not found' });

    const allowed = ['name', 'phone', 'email', 'address', 'place', 'billingMode', 'productPrices', 'status'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const customer = await Customer.findOneAndUpdate(
      { customerId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'UPDATE_CUSTOMER', entityType: 'customer', entityId: req.params.id, oldData: old, newData: updates,
    });

    res.status(200).json({ success: true, customer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/customers/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const customer = await Customer.findOneAndUpdate(
      { customerId: req.params.id, shopId: req.user.shopId },
      { status: 'deleted' },
      { new: true },
    );
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'DELETE_CUSTOMER', entityType: 'customer', entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Customer deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/customers/:id/block
router.patch('/:id/block', protect, adminOnly, async (req, res) => {
  try {
    const { blocked } = req.body;
    const status = blocked ? 'blocked' : 'active';
    const customer = await Customer.findOneAndUpdate(
      { customerId: req.params.id, shopId: req.user.shopId },
      { status },
      { new: true },
    );
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: blocked ? 'BLOCK_CUSTOMER' : 'UNBLOCK_CUSTOMER',
      entityType: 'customer', entityId: req.params.id,
    });

    res.status(200).json({ success: true, customer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
