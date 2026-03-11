const { pool } = require('../../config/db');

class AdminRepository {
    async getMetrics() {
        // Run aggregations in parallel
        const [
            [[{ total_users }]],
            [[{ total_notes }]],
            [[{ total_attachments }]],
            [[{ recent_signups }]]
        ] = await Promise.all([
            pool.execute('SELECT COUNT(*) AS total_users FROM users'),
            pool.execute('SELECT COUNT(*) AS total_notes FROM notes'),
            pool.execute('SELECT COUNT(*) AS total_attachments FROM attachments'),
            pool.execute('SELECT COUNT(*) AS recent_signups FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)')
        ]);

        return {
            total_users,
            total_notes,
            total_attachments,
            recent_signups
        };
    }

    async listUsers({ page = 1, limit = 20 }) {
        const limitInt = Math.floor(Number(limit));
        const offsetInt = Math.floor((Number(page) - 1) * limitInt);

        const [rows] = await pool.execute(
            `SELECT id, name, email, role, is_locked, otp_enabled, created_at
             FROM users
             ORDER BY created_at DESC
             LIMIT ${limitInt} OFFSET ${offsetInt}`
        );

        const [[{ total }]] = await pool.execute('SELECT COUNT(*) AS total FROM users');

        return { users: rows, total };
    }

    // Config Management placeholders for 06-03
    async getAllConfig() {
        const [rows] = await pool.execute('SELECT * FROM app_config ORDER BY config_key ASC');
        return rows;
    }

    async getConfigByKey(key) {
        const [rows] = await pool.execute('SELECT * FROM app_config WHERE config_key = ? LIMIT 1', [key]);
        return rows[0] || null;
    }

    async upsertConfig(key, value, description) {
        if (description) {
            await pool.execute(
                `INSERT INTO app_config (config_key, config_value, description)
                 VALUES (?, ?, ?)
                 ON DUPLICATE KEY UPDATE config_value = VALUES(config_value), description = VALUES(description)`,
                [key, value, description]
            );
        } else {
            await pool.execute(
                `INSERT INTO app_config (config_key, config_value)
                 VALUES (?, ?)
                 ON DUPLICATE KEY UPDATE config_value = VALUES(config_value)`,
                [key, value]
            );
        }
    }

    async logConfigChange({ key, old_value, new_value, changed_by }) {
        await pool.execute(
            `INSERT INTO config_audit_log (config_key, old_value, new_value, changed_by)
             VALUES (?, ?, ?, ?)`,
            [key, old_value, new_value, changed_by]
        );
    }

    async getAuditLog({ page = 1, limit = 20 }) {
        const limitInt = Math.floor(Number(limit));
        const offsetInt = Math.floor((Number(page) - 1) * limitInt);

        const [rows] = await pool.execute(
            `SELECT a.id, a.config_key, a.old_value, a.new_value, a.changed_at,
                    u.id as user_id, u.name as user_name, u.email as user_email
             FROM config_audit_log a
             INNER JOIN users u ON u.id = a.changed_by
             ORDER BY a.changed_at DESC
             LIMIT ${limitInt} OFFSET ${offsetInt}`
        );

        const [[{ total }]] = await pool.execute('SELECT COUNT(*) AS total FROM config_audit_log');

        return { logs: rows, total };
    }
}

module.exports = new AdminRepository();
