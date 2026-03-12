const User = require("../model/user_model");

class UserRepository {
    async findByEmail(email) {
        return await User.findOne({ email });
    }

    async findById(id) {
        return await User.findById(id);
    }

    async createUser(userData) {
        return await User.create(userData);
    }

    async updateRefreshToken(userId, refreshToken) {
        return await User.updateOne(
            { _id: userId },
            { $set: { refreshToken } }
        );
    }
}

module.exports = new UserRepository();
