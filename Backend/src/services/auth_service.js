const userRepository = require("../repository/user_repository");
const {
  generateToken,
  refreshToken,
  verifyRefreshToken,
  verifyEmailToken,
  generatePasswordResetToken,
  verifyPasswordResetToken,
} = require("../helper/token_generator");
const bcrypt = require('bcrypt');

class AuthService {
  async register(name, email, password, profilePicture) {
    const user = await userRepository.findByEmail(email);
    if (user) {
      return { success: false, message: "User already exists" };
    }

    const savedUser = await userRepository.createUser({
      name,
      email,
      password,
      profilePicture,
    });
    return {
      success: true,
      data: {
        id: savedUser._id,
        name: savedUser.name,
        email: savedUser.email,
        profilePicture: savedUser.profilePicture,
      },
    };
  }

  async login(email, password) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      return { success: false, message: "User not found" };
    }

    if (!user.verified) {
      return { success: false, message: "Please verify your email before signing in. Check your inbox for the verification link." };
    }

    try {
      const result = await bcrypt.compare(password, user.password);
      if (!result) {
        return { success: false, message: "Incorrect password" };
      }
    } catch (err) {
      throw err;
    }

    const token = generateToken(user.id);
    const generatedRefreshToken = refreshToken(user._id);

    await userRepository.updateRefreshToken(user._id, generatedRefreshToken);

    return {
      success: true,
      data: {
        id: user.id || user._id,
        name: user.name,
        email: user.email,
        profilePicture: user.profilePicture,
        token,
        refreshToken: generatedRefreshToken,
      },
    };
  }

  async refreshUserToken(token) {
    const validRefreshToken = verifyRefreshToken(token);
    if (!validRefreshToken) {
      return { success: false, message: "Invalid refresh token" };
    }

    const user = await userRepository.findById(validRefreshToken.id);
    if (!user) {
      return { success: false, message: "User not found" };
    }

    if (token !== user.refreshToken) {
      return { success: false, message: "Expired refresh token" };
    }

    const newAccessToken = generateToken(user.id || user._id);
    const newRefreshToken = refreshToken(user.id || user._id);

    await userRepository.updateRefreshToken(user._id, newRefreshToken);

    return {
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    };
  }

  async verifyEmailVerificationToken(token) {
    let validToken;
    try {
      validToken = verifyEmailToken(token);
    } catch (err) {
      if (err.name === "TokenExpiredError") {
        return { success: false, message: "Verification link has expired. Please register again or request a new link." };
      }
      return { success: false, message: "Invalid verification token" };
    }

    if (!validToken?.email) {
      return { success: false, message: "Invalid token" };
    }

    const user = await userRepository.findByEmail(validToken.email);
    if (!user) {
      return { success: false, message: "User not found" };
    }

    if (user.verified) {
      return { success: true, data: { message: "Email is already verified" } };
    }

    await userRepository.updateVerificationStatus(true, user.email);

    return {
      success: true,
      data: {
        message: "Email verified successfully",
      },
    };
  }

  async resendVerificationEmail(email) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      return { success: false, message: "No account found with this email" };
    }

    if (user.verified) {
      return { success: false, message: "Email is already verified. You can sign in." };
    }

    return {
      success: true,
      data: {
        name: user.name,
        email: user.email,
      },
    };
  }

  async forgetPassword(email) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      // Do not expose whether the account exists.
      return { success: true, data: null };
    }

    const resetToken = generatePasswordResetToken(user.email);

    return {
      success: true,
      data: {
        resetToken,
        user: {
          email: user.email,
          name: user.name,
        },
      },
    };
  }

  async verifyForgetPasswordToken(token) {
    let decoded;
    try {
      decoded = verifyPasswordResetToken(token);
    } catch (_) {
      return { success: false, message: "Invalid or expired token" };
    }

    if (!decoded?.email) {
      return { success: false, message: "Invalid token" };
    }

    const user = await userRepository.findByEmail(decoded.email);
    if (!user) {
      return { success: false, message: "User not found" };
    }

    return {
      success: true,
      data: {
        email: user.email,
      },
    };
  }

  async changePassword(token, newPassword) {
    let decoded;
    try {
      decoded = verifyPasswordResetToken(token);
    } catch (_) {
      return { success: false, message: "Invalid or expired token" };
    }

    if (!decoded?.email) {
      return { success: false, message: "Invalid token" };
    }

    const user = await userRepository.findByEmail(decoded.email);
    if (!user) {
      return { success: false, message: "User not found" };
    }

    const salt = bcrypt.genSaltSync(12);
    const hashedPassword = bcrypt.hashSync(newPassword, salt);

    await userRepository.updatePasswordByEmail(user.email, hashedPassword);
    await userRepository.updateRefreshToken(user._id, null);

    return {
      success: true,
      data: null,
    };
  }

}

module.exports = new AuthService();
