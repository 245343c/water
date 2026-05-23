const AuditLog = require('../models/AuditLog');

const writeAuditLog = async ({ shopId, actorUid, actorRole, action, entityType, entityId, oldData = null, newData = null }) => {
  try {
    await AuditLog.create({ shopId, actorUid, actorRole, action, entityType, entityId, oldData, newData });
  } catch (err) {
    console.error('Audit log write failed:', err.message);
  }
};

module.exports = { writeAuditLog };
