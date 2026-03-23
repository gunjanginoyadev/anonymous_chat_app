const jwt = require("jsonwebtoken");
const env = require("../config/env");

function generateToken(id) {
  const payload = {
    id
  };

  const options = {
    expiresIn: "1h",
  };

  return jwt.sign(payload, env.JET_SECRET, options);
}

function verifyToken(token) {
  return jwt.verify(token, env.JET_SECRET);
}

function refreshToken(id) {
  const payload = {
    id,
  };

  const options = {
    expiresIn: "7d",
  };

  return jwt.sign(payload, env.JET_REFRESH_TOKEN_SECRET, options);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, env.JET_REFRESH_TOKEN_SECRET);
}

// verify email token
function verifyUserEmailToken(email) {
  const payload = {
    email,
  };

  const options = {
    expiresIn: "10m",
  };

  return jwt.sign(payload, env.JET_REFRESH_TOKEN_SECRET, options);
}

function verifyEmailToken(token) {
  return jwt.verify(token, env.JET_REFRESH_TOKEN_SECRET);
}

function generatePasswordResetToken(email) {
  const payload = {
    email,
  };

  const options = {
    expiresIn: "15m",
  };

  return jwt.sign(payload, env.JET_REFRESH_TOKEN_SECRET, options);
}

function verifyPasswordResetToken(token) {
  return jwt.verify(token, env.JET_REFRESH_TOKEN_SECRET);
}

module.exports = {
  generateToken,
  verifyToken,
  refreshToken,
  verifyRefreshToken,
  verifyUserEmailToken,
  verifyEmailToken,
  generatePasswordResetToken,
  verifyPasswordResetToken,
};
