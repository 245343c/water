const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const MonthlyBill = require('../models/MonthlyBill');
const Delivery = require('../models/Delivery');
const CashCollection = require('../models/CashCollection');
const Customer = require('../models/Customer');
const { protect } = require('../middleware/auth');
const { adminOnly, customerOnly } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/bills — list bills (admin)
router.get('/', protect, adminOnly, async (req, res) => {
  try {
    const { customerId, status, month, year } = req.query;
    const filter = { shopId: req.user.shopId };
    if (customerId) filter.customerId = customerId;
    if (status) filter.status = status;
    if (month) filter.month = parseInt(month);
    if (year) filter.year = parseInt(year);

    const bills = await MonthlyBill.find(filter).sort({ year: -1, month: -1 });
    res.status(200).json({ success: true, bills });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bills/customer/mine — must be before /:id
router.get('/customer/mine', protect, customerOnly, async (req, res) => {
  try {
    const bills = await MonthlyBill.find({ shopId: req.query.shopId, customerId: req.user.customerProfileId })
      .sort({ year: -1, month: -1 });
    res.status(200).json({ success: true, bills });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bills/:id
router.get('/:id', protect, async (req, res) => {
  try {
    const bill = await MonthlyBill.findOne({ billId: req.params.id, shopId: req.user.shopId });
    if (!bill) return res.status(404).json({ success: false, message: 'Bill not found' });
    res.status(200).json({ success: true, bill });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/bills/generate — generate monthly bill for a customer
router.post('/generate', protect, adminOnly, async (req, res) => {
  try {
    const { customerId, month, year } = req.body;
    if (!customerId || !month || !year) {
      return res.status(400).json({ success: false, message: 'customerId, month, year required' });
    }

    const customer = await Customer.findOne({ customerId, shopId: req.user.shopId });
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const deliveries = await Delivery.find({
      shopId: req.user.shopId,
      customerId,
      deliveryDate: { $gte: startDate, $lte: endDate },
    });

    const cashCollected = await CashCollection.aggregate([
      { $match: { shopId: req.user.shopId, customerId, collectionDate: { $gte: startDate, $lte: endDate } } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);

    const totalNormalCans = deliveries.reduce((s, d) => s + (d.lines.find(l => l.kind === 'normalCan')?.quantity || 0), 0);
    const totalCoolCans = deliveries.reduce((s, d) => s + (d.lines.find(l => l.kind === 'coolCan')?.quantity || 0), 0);
    const currentMonthAmount = deliveries.reduce((s, d) => s + d.totalAmount, 0);
    const cashCollectedAmount = cashCollected[0]?.total || 0;
    const finalPendingAmount = Math.max(0, currentMonthAmount - cashCollectedAmount);

    const billId = uuidv4();
    const bill = await MonthlyBill.create({
      billId,
      shopId: req.user.shopId,
      customerId,
      customerName: customer.name,
      month: parseInt(month),
      year: parseInt(year),
      billingPeriodStart: startDate,
      billingPeriodEnd: endDate,
      totalNormalCans,
      totalCoolCans,
      currentMonthAmount,
      cashCollectedAmount,
      finalPendingAmount,
      status: 'generated',
      generatedAt: new Date(),
    });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'GENERATE_MONTHLY_BILL', entityType: 'monthlyBill', entityId: billId, newData: bill,
    });

    res.status(201).json({ success: true, bill });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/bills/:id/status — update bill status
router.patch('/:id/status', protect, adminOnly, async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['draft', 'generated', 'sent', 'paid', 'partially_paid', 'overdue', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ success: false, message: `Invalid status` });
    }

    const bill = await MonthlyBill.findOneAndUpdate(
      { billId: req.params.id, shopId: req.user.shopId },
      { status },
      { new: true },
    );
    if (!bill) return res.status(404).json({ success: false, message: 'Bill not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: `BILL_STATUS_${status.toUpperCase()}`, entityType: 'monthlyBill', entityId: req.params.id,
    });

    res.status(200).json({ success: true, bill });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});


module.exports = router;
