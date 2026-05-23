const allowRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Not authenticated.' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}.`,
      });
    }
    next();
  };
};

const adminOnly = allowRoles('shop_admin');
const driverOnly = allowRoles('driver');
const customerOnly = allowRoles('customer');
const adminOrDriver = allowRoles('shop_admin', 'driver');
const adminOrCustomer = allowRoles('shop_admin', 'customer');

module.exports = { allowRoles, adminOnly, driverOnly, customerOnly, adminOrDriver, adminOrCustomer };
