const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const Product = require('../models/Product');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');
const { writeAuditLog } = require('../utils/auditLog');

// GET /api/products — list products
router.get('/', protect, async (req, res) => {
  try {
    const filter = { shopId: req.user.shopId };
    if (req.query.active === 'true') filter.isActive = true;
    if (req.query.q) {
      filter.$or = [
        { name: { $regex: req.query.q, $options: 'i' } },
        { description: { $regex: req.query.q, $options: 'i' } },
      ];
    }
    const products = await Product.find(filter).sort({ createdAt: -1 });
    res.status(200).json({ success: true, products });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/products/:id
router.get('/:id', protect, async (req, res) => {
  try {
    const product = await Product.findOne({ productId: req.params.id, shopId: req.user.shopId });
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.status(200).json({ success: true, product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/products — create product
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { name, description, category, variantLabel, price, isCool, imageUrl } = req.body;
    if (!name || !category || price === undefined) {
      return res.status(400).json({ success: false, message: 'name, category, price required' });
    }

    const productId = uuidv4();
    const variantId = uuidv4();
    const product = await Product.create({
      productId,
      shopId: req.user.shopId,
      name: name.trim(),
      description: description || '',
      category,
      variants: [{ variantId, label: variantLabel || name.trim(), price, isCool: isCool || false }],
      imageUrl: imageUrl || null,
      isActive: true,
    });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'CREATE_PRODUCT', entityType: 'product', entityId: productId, newData: product,
    });

    res.status(201).json({ success: true, product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/products/:id — update product
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const allowed = ['name', 'description', 'variants', 'imageUrl', 'isActive'];
    const updates = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const product = await Product.findOneAndUpdate(
      { productId: req.params.id, shopId: req.user.shopId },
      updates,
      { new: true },
    );
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'UPDATE_PRODUCT', entityType: 'product', entityId: req.params.id, newData: updates,
    });

    res.status(200).json({ success: true, product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/products/:id/active
router.patch('/:id/active', protect, adminOnly, async (req, res) => {
  try {
    const { active } = req.body;
    const product = await Product.findOneAndUpdate(
      { productId: req.params.id, shopId: req.user.shopId },
      { isActive: active },
      { new: true },
    );
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.status(200).json({ success: true, product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/products/:id
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const product = await Product.findOneAndDelete({ productId: req.params.id, shopId: req.user.shopId });
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    await writeAuditLog({
      shopId: req.user.shopId, actorUid: req.user.uid, actorRole: req.user.role,
      action: 'DELETE_PRODUCT', entityType: 'product', entityId: req.params.id,
    });

    res.status(200).json({ success: true, message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
