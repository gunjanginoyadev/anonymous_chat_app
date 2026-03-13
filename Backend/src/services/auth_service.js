const userRepository = require("../repository/user_repository");
const {
    generateToken,
    refreshToken,
    verifyRefreshToken,
} = require("../helper/token_generator");

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

    if (password !== user.password) {
      return { success: false, message: "Incorrect password" };
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
}

module.exports = new AuthService();
