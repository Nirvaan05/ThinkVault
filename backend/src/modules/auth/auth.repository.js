const { pool } = require('../../config/db');


class AuthRepository {
    /**
     * Find a user by email.
     * @param {string} email
     * @returns {Promise<object|null>}
     */
    async findByEmail(email) {
        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE email = ? LIMIT 1',
            [email]
        );
        return rows[0] || null;
    }

    /**
     * Find a user by ID.
     * @param {number} id
     * @returns {Promise<object|null>}
     */
    async findById(id) {
        const [rows] = await pool.execute(
            'SELECT id, name, email, role, is_locked, otp_enabled, created_at, updated_at FROM users WHERE id = ? LIMIT 1',
            [id]
        );
        return rows[0] || null;
    }

    /**
     * Create a new user.
     * @param {{ name: string, email: string, password: string, role?: string }} data
     * @returns {Promise<{ id: number }>}
     */
    async create({ name, email, password, role = 'user' }) {
        const [result] = await pool.execute(
            'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
            [name, email, password, role]
        );
        return { id: result.insertId };
    }

    /**
     * Record a login attempt.
     * @param {{ userId: number, ipAddress: string, success: boolean }} data
     */
    async recordLoginAttempt({ userId, ipAddress, success }) {
        await pool.execute(
            'INSERT INTO login_attempts (user_id, ip_address, success) VALUES (?, ?, ?)',
            [userId, ipAddress, success]
        );
    }

    /**
     * Count recent failed login attempts for a user.
     * @param {number} userId
     * @param {number} windowMinutes
     * @returns {Promise<number>}
     */
    async countRecentFailedAttempts(userId, windowMinutes = 15) {
        const [rows] = await pool.execute(
            `SELECT COUNT(*) as count FROM login_attempts 
       WHERE user_id = ? AND success = FALSE 
       AND attempted_at > DATE_SUB(NOW(), INTERVAL ? MINUTE)`,
            [userId, windowMinutes]
        );
        return rows[0].count;
    }

    /**
     * Lock a user account until a specified time.
     * @param {number} userId
     * @param {Date} until
     */
    async lockAccount(userId, until) {
        await pool.execute(
            'UPDATE users SET is_locked = TRUE, locked_until = ? WHERE id = ?',
            [until, userId]
        );
    }

    /**
     * Unlock a user account.
     * @param {number} userId
     */
    async unlockAccount(userId) {
        await pool.execute(
            'UPDATE users SET is_locked = FALSE, locked_until = NULL WHERE id = ?',
            [userId]
        );
    }

    // ── Token Blocklist ──────────────────────────────────────────────────────

    /**
     * Add a JWT jti to the blocklist.
     * @param {{ jti: string, userId: number, expiresAt: Date }} data
     */
    async addToBlocklist({ jti, userId, expiresAt }) {
        await pool.execute(
            'INSERT IGNORE INTO token_blocklist (jti, user_id, expires_at) VALUES (?, ?, ?)',
            [jti, userId, expiresAt]
        );
    }

    /**
     * Check if a jti is in the blocklist.
     * @param {string} jti
     * @returns {Promise<boolean>}
     */
    async isBlocklisted(jti) {
        const [rows] = await pool.execute(
            'SELECT 1 FROM token_blocklist WHERE jti = ? AND expires_at > NOW() LIMIT 1',
            [jti]
        );
        return rows.length > 0;
    }

    /**
     * Remove expired entries from the blocklist.
     */
    async cleanExpiredBlocklist() {
        await pool.execute('DELETE FROM token_blocklist WHERE expires_at <= NOW()');
    }

    // ── OTP / TOTP ────────────────────────────────────────────────────────────

    /**
     * Store an OTP secret (unverified until enable is called).
     * @param {number} userId
     * @param {string} secret
     */
    async setOtpSecret(userId, secret) {
        await pool.execute(
            'UPDATE users SET otp_secret = ? WHERE id = ?',
            [secret, userId]
        );
    }

    /**
     * Enable or disable OTP for a user.
     * @param {number} userId
     * @param {boolean} enabled
     */
    async setOtpEnabled(userId, enabled) {
        await pool.execute(
            'UPDATE users SET otp_enabled = ? WHERE id = ?',
            [enabled, userId]
        );
    }

    /**
     * Clear the OTP secret and disable OTP.
     * @param {number} userId
     */
    async clearOtpSecret(userId) {
        await pool.execute(
            'UPDATE users SET otp_secret = NULL, otp_enabled = FALSE WHERE id = ?',
            [userId]
        );
    }
}

module.exports = new AuthRepository();
