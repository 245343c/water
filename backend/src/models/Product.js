const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema(
  {
    variantId: { type: String, required: true },
    label: { type: String, required: true },
    price: { type: Number, required: true },
    isCool: { type: Boolean, default: false },
  },
  { _id: false },
);

const productSchema = new mongoose.Schema(
  {
    productId: { type: String, required: true },
    shopId: { type: String, required: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    category: {
      type: String,
      enum: ['can', 'bottle'],
      required: true,
    },
    variants: [variantSchema],
    imageUrl: { type: String, default: null },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

productSchema.index({ shopId: 1 });

module.exports = mongoose.model('Product', productSchema);
