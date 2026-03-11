const { pool } = require('../../config/db');

class CategoriesRepository {
    /**
     * Create a new category for a user.
     * @param {number} userId
     * @param {string} name
     * @returns {Promise<{ id: number }>}
     */
    async create(userId, name) {
        const [result] = await pool.execute(
            'INSERT INTO categories (user_id, name) VALUES (?, ?)',
            [userId, name]
        );
        return { id: result.insertId };
    }

    /**
     * Find all categories belonging to a user.
     * @param {number} userId
     * @returns {Promise<object[]>}
     */
    async findAllByUser(userId) {
        const [rows] = await pool.execute(
            'SELECT id, name, created_at, updated_at FROM categories WHERE user_id = ? ORDER BY name ASC',
            [userId]
        );
        return rows;
    }

    /**
     * Find a single category by ID (does not filter by user — service enforces ownership).
     * @param {number} id
     * @returns {Promise<object|null>}
     */
    async findById(id) {
        const [rows] = await pool.execute(
            'SELECT id, user_id, name, created_at, updated_at FROM categories WHERE id = ? LIMIT 1',
            [id]
        );
        return rows[0] || null;
    }

    /**
     * Update a category's name.
     * @param {number} id
     * @param {string} name
     * @returns {Promise<void>}
     */
    async update(id, name) {
        await pool.execute(
            'UPDATE categories SET name = ?, updated_at = NOW() WHERE id = ?',
            [name, id]
        );
    }

    /**
     * Delete a category by ID.
     * @param {number} id
     * @returns {Promise<void>}
     */
    async deleteById(id) {
        await pool.execute('DELETE FROM categories WHERE id = ?', [id]);
    }
}

module.exports = new CategoriesRepository();
