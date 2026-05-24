const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/env');
const logger = require('../utils/logger');

const uploadRoot = path.join(__dirname, '../../uploads');

function ensureLocalDir() {
  if (!fs.existsSync(uploadRoot)) {
    fs.mkdirSync(uploadRoot, { recursive: true });
  }
}

let gcsBucket = null;

function getGcsBucket() {
  if (gcsBucket) return gcsBucket;
  if (!config.gcs.bucket) {
    throw new Error('GCS_BUCKET is required when STORAGE_MODE=gcp');
  }
  // Lazy require so local dev works without @google-cloud/storage installed
  // eslint-disable-next-line global-require
  const { Storage } = require('@google-cloud/storage');
  const storage = new Storage(
    config.gcs.projectId ? { projectId: config.gcs.projectId } : undefined,
  );
  gcsBucket = storage.bucket(config.gcs.bucket);
  return gcsBucket;
}

/**
 * @param {{ buffer: Buffer, mimetype: string, originalname: string }} file
 * @param {{ protocol: string, get: (h: string) => string }} req
 */
async function saveImage(file, req) {
  const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
  const filename = `${uuidv4()}${ext}`;

  if (config.storageMode === 'gcp') {
    const objectName = `uploads/${filename}`;
    const bucket = getGcsBucket();
    const blob = bucket.file(objectName);
    await blob.save(file.buffer, {
      resumable: false,
      metadata: { contentType: file.mimetype, cacheControl: 'public, max-age=31536000' },
    });
    try {
      await blob.makePublic();
    } catch (err) {
      logger.warn('Could not make GCS object public — use signed URLs if needed', {
        message: err.message,
      });
    }
    if (config.publicBaseUrl) {
      return `${config.publicBaseUrl.replace(/\/+$/, '')}/${objectName}`;
    }
    return `https://storage.googleapis.com/${config.gcs.bucket}/${objectName}`;
  }

  ensureLocalDir();
  const dest = path.join(uploadRoot, filename);
  await fs.promises.writeFile(dest, file.buffer);
  const baseUrl = config.publicBaseUrl || `${req.protocol}://${req.get('host')}`;
  return `${baseUrl.replace(/\/+$/, '')}/uploads/${filename}`;
}

function multerStorage() {
  if (config.storageMode === 'gcp') {
    // eslint-disable-next-line global-require
    const multer = require('multer');
    return multer.memoryStorage();
  }
  ensureLocalDir();
  // eslint-disable-next-line global-require
  const multer = require('multer');
  return multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadRoot),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
      cb(null, `${uuidv4()}${ext}`);
    },
  });
}

module.exports = { saveImage, multerStorage, uploadRoot };
