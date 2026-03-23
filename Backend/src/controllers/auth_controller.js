const authService = require("../services/auth_service");
const bcrypt = require('bcrypt');
const EmailHelper = require('../helper/email_helper');
const EmailTemplates = require('../helper/email_templates');
const Env = require("../config/env");

const {
  errorResponse,
  successResponse,
  serverErrorResponse,
} = require("../helper/api_response");
const { verifyUserEmailToken } = require("../helper/token_generator");

class AuthController {
  async register(req, res) {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return errorResponse(res, "Name, email and password are required");
    }

    let hashedPassword = '';
    try {

      const salt = bcrypt.genSaltSync(12);
      hashedPassword = bcrypt.hashSync(password, salt);
      console.log('hashedPassword', hashedPassword);
    } catch (err) {
      console.log(err);
      return serverErrorResponse(res, "Error creating user", err);
    }

    try {
      const result = await authService.register(
        name,
        email,
        hashedPassword,
        `https://api.dicebear.com/9.x/fun-emoji/png?seed=${name}`,
      );

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      const token = verifyUserEmailToken(email);

      const html = EmailTemplates.verifyEmail({
        username: result.data.name,
        verificationLink: `${Env.FRONTEND_BASE_URL}/#/verify-email?token=${token}`,
      });

      const emailResult = await EmailHelper.sendMail({
        from: Env.EMAIL_SMTP_USERNAME,
        to: email,
        subject: "Verify your email",
        html: html,
      });
      console.log(emailResult);

      return successResponse(res, "User created successfully, We have sent you an email to verify your email", result.data);
    } catch (err) {
      console.log('Register api', err);
      return serverErrorResponse(res, "Error creating user", err);
    }
  }

  async login(req, res) {
    const { email, password } = req.body;
    if (!email || !password) {
      return errorResponse(res, "Email and password are required");
    }

    try {
      const result = await authService.login(email, password);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      return successResponse(res, "Login successful", result.data);
    } catch (err) {
      console.log(err);
      return serverErrorResponse(res, "Error during login", err);
    }
  }

  async refreshToken(req, res) {
    const { token } = req.body;
    if (!token) {
      return errorResponse(res, "Access token is required");
    }

    try {
      const result = await authService.refreshUserToken(token);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      return successResponse(res, "Refresh token successful", result.data);
    } catch (err) {
      return serverErrorResponse(res, "Error during token refresh", err);
    }
  }

  async verifyEmailVerificationToken(req, res) {
    const token = req.body?.token || req.query?.token;
    if (!token) {
      return errorResponse(res, "Token is required");
    }

    try {
      const result = await authService.verifyEmailVerificationToken(token);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      return successResponse(res, result.data?.message || "Email verified successfully");
    } catch (err) {
      return serverErrorResponse(res, "Error during email verification", err);
    }
  }

  async resendVerificationEmail(req, res) {
    const { email } = req.body;
    if (!email) {
      return errorResponse(res, "Email is required");
    }

    try {
      const result = await authService.resendVerificationEmail(email);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      const token = verifyUserEmailToken(result.data.email);

      const html = EmailTemplates.verifyEmail({
        username: result.data.name,
        verificationLink: `${Env.FRONTEND_BASE_URL}/#/verify-email?token=${token}`,
      });

      await EmailHelper.sendMail({
        from: Env.EMAIL_SMTP_USERNAME,
        to: result.data.email,
        subject: "Verify your email",
        html: html,
      });

      return successResponse(res, "Verification email sent. Please check your inbox.");
    } catch (err) {
      return serverErrorResponse(res, "Error sending verification email", err);
    }
  }

  async forgetPassword(req, res) {
    const { email } = req.body;
    if (!email) {
      return errorResponse(res, "Email is required");
    }

    try {
      const result = await authService.forgetPassword(email);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      if (result.data?.resetToken && result.data?.user?.email) {
        const html = EmailTemplates.forgotPassword({
          username: result.data.user.name,
          resetLink: `${Env.FRONTEND_BASE_URL}/#/reset-password?token=${result.data.resetToken}`,
        });

        await EmailHelper.sendMail({
          from: Env.EMAIL_SMTP_USERNAME,
          to: result.data.user.email,
          subject: "Reset your password",
          html: html,
        });
      }

      return successResponse(res, "We have sent you an email to reset your password");
    } catch (err) {
      return serverErrorResponse(res, "Error during forgot password", err);
    }
  }

  async verifyForgetPasswordToken(req, res) {
    const { token } = req.body;
    if (!token) {
      return errorResponse(res, "Token is required");
    }

    try {
      const result = await authService.verifyForgetPasswordToken(token);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      return successResponse(res, "Token verified successfully", result.data);
    } catch (err) {
      return serverErrorResponse(res, "Error verifying forgot password token", err);
    }
  }

  async changePassword(req, res) {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) {
      return errorResponse(res, "Token and newPassword are required");
    }
    if (newPassword.length < 6) {
      return errorResponse(res, "Password must be at least 6 characters long");
    }

    try {
      const result = await authService.changePassword(token, newPassword);

      if (!result.success) {
        return errorResponse(res, result.message);
      }

      return successResponse(res, "Password changed successfully");
    } catch (err) {
      return serverErrorResponse(res, "Error changing password", err);
    }
  }
}

module.exports = new AuthController();
