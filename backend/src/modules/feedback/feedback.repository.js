const { pool } = require('../../config/db');

class FeedbackRepository {
    /**
     * Create a new feedback entry.
     */
    async create({ userId, type, subject, body }) {
        const [result] = await pool.execute(
            `INSERT INTO feedback (user_id, type, subject, body)
             VALUES (?, ?, ?, ?)`,
            [userId, type, subject, body]
        );
        return this.findById(result.insertId);
    }

    /**
     * Find a single entry by id (with submitter info).
     */
    async findById(id) {
        const [rows] = await pool.execute(
            `SELECT f.id, f.type, f.subject, f.body, f.status, f.created_at, f.updated_at,
                    u.id AS user_id, u.name AS user_name, u.email AS user_email
             FROM feedback f
             INNER JOIN users u ON u.id = f.user_id
             WHERE f.id = ?`,
            [id]
        );
        return rows[0] || null;
    }

    /**
     * List all entries with optional filters and pagination (admin).
     */
    async findAll({ type, status, page = 1, limit = 20 }) {
        const limitInt = Math.floor(Number(limit));
        const offsetInt = Math.floor((Number(page) - 1) * limitInt);

        const conditions = [];
        const params = [];

        if (type) { conditions.push('f.type = ?'); params.push(type); }
        if (status) { conditions.push('f.status = ?'); params.push(status); }

        const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

        const [rows] = await pool.query(
            `SELECT f.id, f.type, f.subject, f.body, f.status, f.created_at,
                    u.id AS user_id, u.name AS user_name, u.email AS user_email
             FROM feedback f
             INNER JOIN users u ON u.id = f.user_id
             ${where}
             ORDER BY f.created_at DESC
             LIMIT ${limitInt} OFFSET ${offsetInt}`,
            params
        );

        const [[{ total }]] = await pool.query(
            `SELECT COUNT(*) AS total FROM feedback f ${where}`,
            params
        );

        return { items: rows, total };
    }

    /**
     * Update the status of an entry.
     */
    async updateStatus(id, status) {
        await pool.execute(
            'UPDATE feedback SET status = ? WHERE id = ?',
            [status, id]
        );
        return this.findById(id);
    }
}

module.exports = new FeedbackRepository();
