const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    shopId: { type: String, required: true },
    actorUid: { type: String, required: true },
    actorRole: { type: String, required: true },
    action: { type: String, required: true },
    entityType: { type: String, required: true },
    entityId: { type: String, required: true },
    oldData: { type: mongoose.Schema.Types.Mixed, default: null },
    newData: { type: mongoose.Schema.Types.Mixed, default: null },
  },
  { timestamps: true },
);

auditLogSchema.index({ shopId: 1, createdAt: -1 });
auditLogSchema.index({ shopId: 1, actorUid: 1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
