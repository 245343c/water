const express = require('express');
const router = express.Router();
const Delivery = require('../models/Delivery');
const CashCollection = require('../models/CashCollection');
const Customer = require('../models/Customer');
const Order = require('../models/Order');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');

// GET /api/reports/dashboard?month=5&year=2026
router.get('/dashboard', protect, adminOnly, async (req, res) => {
  try {
    const { month, year } = req.query;
    const now = new Date();
    const m = parseInt(month || now.getMonth() + 1);
    const y = parseInt(year || now.getFullYear());
    const startDate = new Date(y, m - 1, 1);
    const endDate = new Date(y, m, 0, 23, 59, 59);

    const [deliveryStats, cashStats, customerCount, pendingOrders] = await Promise.all([
      Delivery.aggregate([
        { $match: { shopId: req.user.shopId, deliveryDate: { $gte: startDate, $lte: endDate } } },
        {
          $group: {
            _id: null,
            totalDeliveries: { $sum: 1 },
            totalAmount: { $sum: '$totalAmount' },
            totalNormalCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'normalCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
            totalCoolCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'coolCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
          },
        },
      ]),
      CashCollection.aggregate([
        { $match: { shopId: req.user.shopId, collectionDate: { $gte: startDate, $lte: endDate } } },
        { $group: { _id: null, totalCollected: { $sum: '$amount' } } },
      ]),
      Customer.countDocuments({ shopId: req.user.shopId, status: 'active' }),
      Order.countDocuments({ shopId: req.user.shopId, orderStatus: 'pending' }),
    ]);

    const pendingAmountResult = await Customer.aggregate([
      { $match: { shopId: req.user.shopId, status: 'active' } },
      { $group: { _id: null, totalPending: { $sum: '$totalPendingAmount' } } },
    ]);

    res.status(200).json({
      success: true,
      stats: {
        totalDeliveries: deliveryStats[0]?.totalDeliveries || 0,
        totalSales: deliveryStats[0]?.totalAmount || 0,
        totalNormalCans: deliveryStats[0]?.totalNormalCans || 0,
        totalCoolCans: deliveryStats[0]?.totalCoolCans || 0,
        cashCollected: cashStats[0]?.totalCollected || 0,
        activeCustomers: customerCount,
        pendingOrders,
        totalPendingAmount: pendingAmountResult[0]?.totalPending || 0,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/reports/daily?date=2026-05-23
router.get('/daily', protect, adminOnly, async (req, res) => {
  try {
    const date = req.query.date ? new Date(req.query.date) : new Date();
    const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const end = new Date(start);
    end.setDate(end.getDate() + 1);

    const deliveries = await Delivery.find({
      shopId: req.user.shopId,
      deliveryDate: { $gte: start, $lt: end },
    }).sort({ deliveryDate: -1 });

    const totalAmount = deliveries.reduce((s, d) => s + d.totalAmount, 0);
    const totalNormal = deliveries.reduce((s, d) => s + (d.lines.find(l => l.kind === 'normalCan')?.quantity || 0), 0);
    const totalCool = deliveries.reduce((s, d) => s + (d.lines.find(l => l.kind === 'coolCan')?.quantity || 0), 0);

    res.status(200).json({
      success: true,
      date: start.toISOString().split('T')[0],
      totalDeliveries: deliveries.length,
      totalNormalCans: totalNormal,
      totalCoolCans: totalCool,
      totalAmount,
      deliveries,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/reports/pending — pending amounts per customer
router.get('/pending', protect, adminOnly, async (req, res) => {
  try {
    const customers = await Customer.find({
      shopId: req.user.shopId,
      status: 'active',
      totalPendingAmount: { $gt: 0 },
    }).sort({ totalPendingAmount: -1 });

    const totalPending = customers.reduce((s, c) => s + c.totalPendingAmount, 0);
    res.status(200).json({ success: true, customers, totalPending });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/reports/monthly?month=5&year=2026
router.get('/monthly', protect, adminOnly, async (req, res) => {
  try {
    const { month, year } = req.query;
    const now = new Date();
    const m = parseInt(month || now.getMonth() + 1);
    const y = parseInt(year || now.getFullYear());
    const startDate = new Date(y, m - 1, 1);
    const endDate = new Date(y, m, 0, 23, 59, 59);

    const daily = await Delivery.aggregate([
      { $match: { shopId: req.user.shopId, deliveryDate: { $gte: startDate, $lte: endDate } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$deliveryDate' } },
          totalDeliveries: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.status(200).json({ success: true, month: m, year: y, daily });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/reports/range?startDate=2026-01-01&endDate=2026-01-31
router.get('/range', protect, adminOnly, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    if (!startDate || !endDate) {
      return res.status(400).json({ success: false, message: 'startDate and endDate required' });
    }
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const [deliveryStats, cashStats, daily, activeCustomers] = await Promise.all([
      Delivery.aggregate([
        { $match: { shopId: req.user.shopId, deliveryDate: { $gte: start, $lte: end } } },
        {
          $group: {
            _id: null,
            totalDeliveries: { $sum: 1 },
            totalAmount: { $sum: '$totalAmount' },
            totalNormalCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'normalCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
            totalCoolCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'coolCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
          },
        },
      ]),
      CashCollection.aggregate([
        { $match: { shopId: req.user.shopId, collectionDate: { $gte: start, $lte: end } } },
        { $group: { _id: null, totalCollected: { $sum: '$amount' } } },
      ]),
      Delivery.aggregate([
        { $match: { shopId: req.user.shopId, deliveryDate: { $gte: start, $lte: end } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$deliveryDate' } },
            totalDeliveries: { $sum: 1 },
            totalAmount: { $sum: '$totalAmount' },
            normalCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'normalCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
            coolCans: {
              $sum: {
                $reduce: {
                  input: { $filter: { input: '$lines', as: 'l', cond: { $eq: ['$$l.kind', 'coolCan'] } } },
                  initialValue: 0,
                  in: { $add: ['$$value', '$$this.quantity'] },
                },
              },
            },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      Delivery.distinct('customerId', {
        shopId: req.user.shopId,
        deliveryDate: { $gte: start, $lte: end },
      }),
    ]);

    const pendingAmountResult = await Customer.aggregate([
      { $match: { shopId: req.user.shopId, status: 'active' } },
      { $group: { _id: null, totalPending: { $sum: '$totalPendingAmount' } } },
    ]);

    const ds = deliveryStats[0] || {};
    res.status(200).json({
      success: true,
      stats: {
        totalDeliveries: ds.totalDeliveries || 0,
        totalSales: ds.totalAmount || 0,
        totalNormalCans: ds.totalNormalCans || 0,
        totalCoolCans: ds.totalCoolCans || 0,
        cashCollected: cashStats[0]?.totalCollected || 0,
        activeCustomers: activeCustomers.length,
        totalPendingAmount: pendingAmountResult[0]?.totalPending || 0,
      },
      daily,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
