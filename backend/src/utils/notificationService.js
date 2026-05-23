const { v4: uuidv4 } = require('uuid');
const Notification = require('../models/Notification');
const logger = require('./logger');

async function createNotification(payload) {
  try {
    const notif = await Notification.create({
      notificationId: uuidv4(),
      read: false,
      ...payload,
    });
    logger.info('Notification created', {
      type: payload.type,
      audience: payload.audience,
      shopId: payload.shopId,
    });
    return notif;
  } catch (err) {
    logger.error('Notification create failed', { error: err.message, type: payload.type });
    return null;
  }
}

async function notifyOrderPlaced(order, customerName, shopName) {
  const qty = `${order.normalQty || 0} normal + ${order.coolQty || 0} cool`;
  return createNotification({
    shopId: order.shopId,
    type: 'orderPlaced',
    title: 'New water request',
    body: `${customerName} requested ${qty} from ${shopName}. Accept or decline from Orders.`,
    audience: 'admin',
    customerId: order.customerId,
    orderId: order.orderId,
  });
}

async function notifyOrderAccepted(order, shopName) {
  await createNotification({
    shopId: order.shopId,
    type: 'orderAccepted',
    title: 'Go deliver — ' + (order.customerName || 'Customer'),
    body: `Admin confirmed order. Ask customer & record actual cans delivered.`,
    audience: 'driver',
    customerId: order.customerId,
    orderId: order.orderId,
    driverId: order.assignedDriverId || null,
  });
  await createNotification({
    shopId: order.shopId,
    type: 'orderAccepted',
    title: 'Request accepted',
    body: `${shopName} confirmed your request. Driver will deliver soon.`,
    audience: 'customer',
    customerId: order.customerId,
    orderId: order.orderId,
    targetUid: order.appUserId || null,
  });
}

async function notifyOrderRejected(order, shopName, reason) {
  return createNotification({
    shopId: order.shopId,
    type: 'orderRejected',
    title: 'Request declined',
    body: `${shopName} declined your request. Reason: ${reason || 'Not available'}`,
    audience: 'customer',
    customerId: order.customerId,
    orderId: order.orderId,
    targetUid: order.appUserId || null,
  });
}

async function notifyDriverAssigned(order, driverName) {
  return createNotification({
    shopId: order.shopId,
    type: 'orderAccepted',
    title: 'Delivery assigned to you',
    body: `${order.customerName || 'Customer'} — ${driverName || 'Driver'} assigned.`,
    audience: 'driver',
    customerId: order.customerId,
    orderId: order.orderId,
    driverId: order.assignedDriverId || null,
  });
}

async function notifyDeliveryRecorded({ shopId, delivery, customer, driverName }) {
  const summary = delivery.lines?.map((l) => `${l.quantity} ${l.kind}`).join(', ') || 'Delivery';
  await createNotification({
    shopId,
    type: 'deliveryRecorded',
    title: 'Delivery recorded',
    body: `${driverName} delivered to ${customer.name}. Bill updated.`,
    audience: 'admin',
    customerId: customer.customerId || customer.id,
    deliveryId: delivery.deliveryId,
    driverId: delivery.driverId || null,
  });
  await createNotification({
    shopId,
    type: 'deliveryRecorded',
    title: 'Water delivered today',
    body: `${summary} recorded for your address.`,
    audience: 'customer',
    customerId: customer.customerId || customer.id,
    deliveryId: delivery.deliveryId,
  });
}

module.exports = {
  createNotification,
  notifyOrderPlaced,
  notifyOrderAccepted,
  notifyOrderRejected,
  notifyDriverAssigned,
  notifyDeliveryRecorded,
};
