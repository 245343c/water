const express = require('express');
const multer = require('multer');
const { protect } = require('../middleware/auth');
const { adminOnly } = require('../middleware/role');
const logger = require('../utils/logger');
const config = require('../config/env');
const { saveImage, multerStorage } = require('../services/storageService');

const router = express.Router();

const upload = multer({
  storage: multerStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) return cb(null, true);
    cb(new Error('Only JPEG, PNG, WebP, GIF images allowed'));
  },
});

// POST /api/uploads/image — admin uploads product/shop image
router.post('/image', protect, adminOnly, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    let url;
    if (config.storageMode === 'gcp') {
      url = await saveImage(
        {
          buffer: req.file.buffer,
          mimetype: req.file.mimetype,
          originalname: req.file.originalname,
        },
        req,
      );
    } else {
      const baseUrl = config.publicBaseUrl || `${req.protocol}://${req.get('host')}`;
      url = `${baseUrl.replace(/\/+$/, '')}/uploads/${req.file.filename}`;
    }

    logger.info('Image uploaded', {
      storage: config.storageMode,
      filename: req.file.filename,
      size: req.file.size,
    });
    res.status(201).json({
      success: true,
      url,
      filename: req.file.filename,
      storage: config.storageMode,
    });
  } catch (err) {
    logger.error('Image upload failed', { message: err.message });
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
