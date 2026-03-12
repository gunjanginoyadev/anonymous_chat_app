const express = require('express');
const authRoutes = require('./auth_routes');

const router = express.Router();

router.use('/auth', authRoutes);

module.exports = router;