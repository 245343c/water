const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const CashCollection = require('../models/CashCollection');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, adminOrDriver } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/cash — list cash collections
router.get('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { customerId, startDate, endDate, limit = 50, skip = 0 } = req.query;
    const filter = { shopId: req.user.shopId };
    if (customerId) filter.customerId = customerId;
    if (startDate || endDate) {
      filter.collectionDate = {};
      if (startDate) filter.collectionDate.$gte = new Date(startDate);
      if (endDate) filter.collectionDate.$lte = new Date(endDate);
    }

    const collections = await CashCollection.find(filter)
      .sort({ collectionDate: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await CashCollection.countDocuments(filter);
    res.status(200).json({ success: true, collections, total });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/cash/pending/:customerId — pending amount for a customer
router.get('/pending/:customerId', protect, adminOrDriver, async (req, res) => {
  try {
    const customer = await Customer.findOne({ customerId: req.params.customerId, shopId: req.user.shopId });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });
    res.status(200).json({ success: true, pendingAmount: customer.totalPendingAmount || 0 });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/cash/:id
router.get('/:id', protect, adminOrDriver, async (req, res) => {
  try {
    const col = await CashCollection.findOne({ cashCollectionId: req.params.id, shopId: req.user.shopId });
    if (!col) return res.status(404).json({ success: false, message: 'Collection not found' });
    res.status(200).json({ success: true, collection: col });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/cash — record cash collection
router.post('/', protect, adminOrDriver, async (req, res) => {
  try {
    const { customerId, amount, collectionType, collectionDate, notes, orderId, deliveryId, billId } = req.body;
    if (!customerId || !amount) {
      return res.status(400).json({ success: false, message: 'customerId and amount required' });
    }

    const customer = await Customer.findOne({ customerId, shopId: req.user.shopId });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    const cashCollectionId = uuidv4();
    const collection = await CashCollection.create({
      cashCollectionId,
      shopId: req.user.shopId,
      customerId,
      customerName: customer.name,
      orderId: orderId || null,
      deliveryId: deliveryId || null,
      billId: billId || null,
      amount,
      collectionType: collectionType || 'delivery_cash',
      collectedByUid: req.user.uid,
      collectedByRole: req.user.role,
      collectedByName: req.user.name,
      collectionDate: collectionDate ? new Date(collectionDate) : new Date(),
      notes: notes || null,
    });

    // Reduce pending amount
    await Customer.findOneAndUpdate(
      { customerId, shopId: req.user.shopId },
      { $inc: { totalPendingAmount: -amount }, lastCashCollectionAt: collection.collectionDate },
    );

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'RECORD_CASH_COLLECTION', entityType: 'cashCollection', entityId: cashCollectionId,
      newData: collection,
    });

    res.status(201).json({ success: true, collection });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/cash/:id
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const allowed = ['amount', 'notes', 'collectionDate', 'collectionType'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const col = await CashCollection.findOneAndUpdate(
      { cashCollectionId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );
    if (!col) return res.status(404).json({ success: false, message: 'Collection not found' });
    res.status(200).json({ success: true, collection: col });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/cash/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const col = await CashCollection.findOne({ cashCollectionId: req.params.id, shopId: req.user.shopId });
    if (!col) return res.status(404).json({ success: false, message: 'Collection not found' });

    // Reverse the amount deduction
    await Customer.findOneAndUpdate(
      { customerId: col.customerId, shopId: req.user.shopId },
      { $inc: { totalPendingAmount: col.amount } },
    );

    await col.deleteOne();

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'DELETE_CASH_COLLECTION', entityType: 'cashCollection', entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Collection deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
