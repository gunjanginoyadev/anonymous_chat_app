const express = require("express");
const authController = require("../controllers/auth_controller");

const router = express.Router();

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/refresh-token", authController.refreshToken);
router.post("/email/verify", authController.verifyEmailVerificationToken);
router.post("/email/resend-verification", authController.resendVerificationEmail);
router.post("/forget-password", authController.forgetPassword);
router.post("/forget-password/verify", authController.verifyForgetPasswordToken);
router.post("/change-password", authController.changePassword);

module.exports = router;
