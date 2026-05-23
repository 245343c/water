const jwt = require('jsonwebtoken');

const signToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

const sendTokenResponse = (res, user, statusCode = 200) => {
  const token = signToken({ uid: user.uid, role: user.role, shopId: user.shopId });

  res.status(statusCode).json({
    success: true,
    token,
    user: {
      uid: user.uid,
      role: user.role,
      shopId: user.shopId,
      driverId: user.driverId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photoUrl,
      isActive: user.isActive,
      profileCompleted: user.profileCompleted,
    },
  });
};

module.exports = { signToken, sendTokenResponse };
