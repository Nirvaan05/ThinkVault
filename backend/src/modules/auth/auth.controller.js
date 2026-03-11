const authService = require('./auth.service');
const { AppError } = require('../../middleware/errorHandler');

/**
 * POST /api/auth/register
 */
async function register(req, res, next) {
    try {
        const { name, email, password } = req.body;
        const user = await authService.register({ name, email, password });

        res.status(201).json({
            status: 'success',
            message: 'User registered successfully',
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/auth/login
 * Supports optional otp_token for accounts with OTP enabled.
 */
async function login(req, res, next) {
    try {
        const { email, password, otp_token } = req.body;
        const ipAddress = req.ip || req.connection?.remoteAddress || 'unknown';

        const result = await authService.login({
            email,
            password,
            ipAddress,
            otpToken: otp_token,
        });

        // OTP required — signal the client to show the OTP step
        if (result.requiresOtp) {
            return res.status(200).json({
                status: 'success',
                message: 'OTP required',
                data: { requires_otp: true },
            });
        }

        res.status(200).json({
            status: 'success',
            message: 'Login successful',
            data: result,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/auth/logout
 * Requires a valid JWT in the Authorization header.
 */
async function logout(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new AppError('Authentication required', 401);
        }
        const token = authHeader.split(' ')[1];
        await authService.logout(token);

        res.status(200).json({
            status: 'success',
            message: 'Logged out successfully',
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/auth/profile
 */
async function getProfile(req, res, next) {
    try {
        const user = await authService.getProfile(req.user.id);

        res.status(200).json({
            status: 'success',
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/auth/status
 * Returns lockout state and OTP status for the authenticated user.
 */
async function getStatus(req, res, next) {
    try {
        const user = await authService.getProfile(req.user.id);

        res.status(200).json({
            status: 'success',
            data: {
                is_locked: user.is_locked,
                otp_enabled: user.otp_enabled,
            },
        });
    } catch (err) {
        next(err);
    }
}

// ── OTP Handlers ────────────────────────────────────────────────────────────

/**
 * POST /api/auth/otp/setup
 * Generates a TOTP secret + QR code for the authenticated user.
 */
async function setupOtp(req, res, next) {
    try {
        const result = await authService.setupOtp(req.user.id, req.user.email);

        res.status(200).json({
            status: 'success',
            message: 'OTP setup initiated. Scan the QR code and verify to enable.',
            data: result,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/auth/otp/verify
 * Verifies the TOTP token and enables OTP for the authenticated user.
 */
async function verifyOtp(req, res, next) {
    try {
        const { token } = req.body;
        await authService.verifyAndEnableOtp(req.user.id, token);

        res.status(200).json({
            status: 'success',
            message: 'OTP enabled successfully',
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/auth/otp/disable
 * Disables OTP after verifying the user's password.
 */
async function disableOtp(req, res, next) {
    try {
        const { password } = req.body;
        await authService.disableOtp(req.user.id, password);

        res.status(200).json({
            status: 'success',
            message: 'OTP disabled successfully',
        });
    } catch (err) {
        next(err);
    }
}

module.exports = { register, login, logout, getProfile, getStatus, setupOtp, verifyOtp, disableOtp };
