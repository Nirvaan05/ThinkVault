const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const config = require('../../config/env');
const authRepository = require('./auth.repository');
const { AppError } = require('../../middleware/errorHandler');

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 15;

class AuthService {
    /**
     * Register a new user.
     * @param {{ name: string, email: string, password: string }} data
     * @returns {Promise<{ id: number, name: string, email: string, role: string }>}
     */
    async register({ name, email, password }) {
        const existing = await authRepository.findByEmail(email);
        if (existing) {
            throw new AppError('Email is already registered', 409);
        }

        const hashedPassword = await argon2.hash(password, {
            type: argon2.argon2id,
            memoryCost: 65536,
            timeCost: 3,
            parallelism: 4,
        });

        const { id } = await authRepository.create({ name, email, password: hashedPassword });
        return { id, name, email, role: 'user' };
    }

    /**
     * Authenticate a user with email and password.
     * Supports optional OTP step when otp_enabled is true.
     * @param {{ email: string, password: string, ipAddress: string, otpToken?: string }} data
     * @returns {Promise<{ user: object, token: string } | { requiresOtp: true }>}
     */
    async login({ email, password, ipAddress, otpToken }) {
        const user = await authRepository.findByEmail(email);

        if (!user) {
            throw new AppError('Invalid email or password', 401);
        }

        // Check lockout
        if (user.is_locked) {
            if (user.locked_until && new Date(user.locked_until) > new Date()) {
                const minutesLeft = Math.ceil(
                    (new Date(user.locked_until) - new Date()) / 60000
                );
                throw new AppError(
                    `Account is locked. Try again in ${minutesLeft} minute(s).`,
                    423
                );
            }
            await authRepository.unlockAccount(user.id);
        }

        // Verify password
        const isValid = await argon2.verify(user.password, password);

        if (!isValid) {
            await authRepository.recordLoginAttempt({ userId: user.id, ipAddress, success: false });

            const failedCount = await authRepository.countRecentFailedAttempts(user.id, LOCKOUT_MINUTES);
            if (failedCount >= MAX_FAILED_ATTEMPTS) {
                const lockUntil = new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000);
                await authRepository.lockAccount(user.id, lockUntil);
                throw new AppError(
                    `Too many failed attempts. Account locked for ${LOCKOUT_MINUTES} minutes.`,
                    423
                );
            }

            throw new AppError('Invalid email or password', 401);
        }

        // OTP check
        if (user.otp_enabled) {
            if (!otpToken) {
                // Signal to client that OTP is required — do NOT issue a token yet
                return { requiresOtp: true };
            }

            const otpValid = speakeasy.totp.verify({
                secret: user.otp_secret,
                encoding: 'base32',
                token: otpToken,
                window: 1, // allow ±30s drift
            });

            if (!otpValid) {
                throw new AppError('Invalid OTP token', 401);
            }
        }

        // Success
        await authRepository.recordLoginAttempt({ userId: user.id, ipAddress, success: true });

        const token = this.generateToken(user);
        return {
            user: { id: user.id, name: user.name, email: user.email, role: user.role },
            token,
        };
    }

    /**
     * Invalidate a JWT by adding its jti to the blocklist.
     * @param {string} rawToken - the raw JWT string
     */
    async logout(rawToken) {
        let decoded;
        try {
            decoded = jwt.verify(rawToken, config.jwt.secret);
        } catch {
            // Already invalid — nothing to blocklist
            return;
        }

        if (decoded.jti) {
            const expiresAt = new Date(decoded.exp * 1000);
            await authRepository.addToBlocklist({
                jti: decoded.jti,
                userId: decoded.id,
                expiresAt,
            });
            // Best-effort cleanup (don't fail the request if this errors)
            authRepository.cleanExpiredBlocklist().catch(() => { });
        }
    }

    /**
     * Generate a JWT with a unique jti for revocation support.
     * @param {{ id: number, email: string, role: string }} user
     * @returns {string}
     */
    generateToken(user) {
        return jwt.sign(
            { id: user.id, email: user.email, role: user.role, jti: uuidv4() },
            config.jwt.secret,
            { expiresIn: config.jwt.expiresIn }
        );
    }

    /**
     * Verify and decode a JWT.
     * @param {string} token
     * @returns {object}
     */
    verifyToken(token) {
        try {
            return jwt.verify(token, config.jwt.secret);
        } catch {
            throw new AppError('Invalid or expired token', 401);
        }
    }

    /**
     * Get user profile by ID (no password).
     * @param {number} id
     * @returns {Promise<object>}
     */
    async getProfile(id) {
        const user = await authRepository.findById(id);
        if (!user) {
            throw new AppError('User not found', 404);
        }
        return user;
    }

    // ── OTP / TOTP ──────────────────────────────────────────────────────────────

    /**
     * Generate a new TOTP secret and QR code URI for the user.
     * The secret is stored but OTP is not yet enabled until verifyAndEnableOtp succeeds.
     * @param {number} userId
     * @param {string} userEmail
     * @returns {Promise<{ otpauthUrl: string, qrDataUri: string }>}
     */
    async setupOtp(userId, userEmail) {
        const secret = speakeasy.generateSecret({
            name: `ThinkVault (${userEmail})`,
            issuer: 'ThinkVault',
            length: 20,
        });

        await authRepository.setOtpSecret(userId, secret.base32);

        const qrDataUri = await QRCode.toDataURL(secret.otpauth_url);

        return {
            otpauthUrl: secret.otpauth_url,
            qrDataUri,
        };
    }

    /**
     * Verify a TOTP token against the stored secret and enable OTP on success.
     * @param {number} userId
     * @param {string} token - 6-digit TOTP code
     */
    async verifyAndEnableOtp(userId, token) {
        const user = await authRepository.findById(userId);
        if (!user) {
            throw new AppError('User not found', 404);
        }

        // findById doesn't include otp_secret — fetch the full record
        const fullUser = await authRepository.findByEmail(user.email);
        if (!fullUser.otp_secret) {
            throw new AppError('OTP setup has not been initiated', 400);
        }

        const valid = speakeasy.totp.verify({
            secret: fullUser.otp_secret,
            encoding: 'base32',
            token,
            window: 1,
        });

        if (!valid) {
            throw new AppError('Invalid OTP token', 400);
        }

        await authRepository.setOtpEnabled(userId, true);
    }

    /**
     * Disable OTP after verifying the user's password.
     * @param {number} userId
     * @param {string} password
     */
    async disableOtp(userId, password) {
        const user = await authRepository.findByEmail(
            (await authRepository.findById(userId)).email
        );

        const isValid = await argon2.verify(user.password, password);
        if (!isValid) {
            throw new AppError('Invalid password', 401);
        }

        await authRepository.clearOtpSecret(userId);
    }
}

module.exports = new AuthService();
