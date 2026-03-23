const express = require('express');
const authRoutes = require('./auth_routes');

const router = express.Router();

router.use('/auth', authRoutes);
router.get('/', (req, res) => {
  res.send('Hello World!');
});

module.exports = router;