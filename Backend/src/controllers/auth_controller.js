const authService = require("../services/auth_service");
const {
    errorResponse,
    successResponse,
    serverErrorResponse,
} = require("../helper/api_response");

class AuthController {
    async register(req, res) {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            return errorResponse(res, "Name, email and password are required");
        }

        try {
            const result = await authService.register(name, email, password);

            if (!result.success) {
                return errorResponse(res, result.message);
            }

            return successResponse(res, "User created successfully", result.data);
        } catch (err) {
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
}

module.exports = new AuthController();
