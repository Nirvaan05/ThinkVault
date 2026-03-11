const { pool } = require('../../config/db');

class TagsRepository {
    /**
     * Create a new tag for a user.
     * @param {number} userId
     * @param {string} name
     * @returns {Promise<{ id: number }>}
     */
    async create(userId, name) {
        const [result] = await pool.execute(
            'INSERT INTO tags (user_id, name) VALUES (?, ?)',
            [userId, name]
        );
        return { id: result.insertId };
    }

    /**
     * Find all tags belonging to a user.
     * @param {number} userId
     * @returns {Promise<object[]>}
     */
    async findAllByUser(userId) {
        const [rows] = await pool.execute(
            'SELECT id, name, created_at FROM tags WHERE user_id = ? ORDER BY name ASC',
            [userId]
        );
        return rows;
    }

    /**
     * Find a single tag by ID (does not filter by user — service enforces ownership).
     * @param {number} id
     * @returns {Promise<object|null>}
     */
    async findById(id) {
        const [rows] = await pool.execute(
            'SELECT id, user_id, name, created_at FROM tags WHERE id = ? LIMIT 1',
            [id]
        );
        return rows[0] || null;
    }

    /**
     * Delete a tag by ID.
     * @param {number} id
     * @returns {Promise<void>}
     */
    async deleteById(id) {
        await pool.execute('DELETE FROM tags WHERE id = ?', [id]);
    }

    /**
     * Get all tags for a given note.
     * @param {number} noteId
     * @returns {Promise<object[]>}
     */
    async findByNoteId(noteId) {
        const [rows] = await pool.execute(
            `SELECT t.id, t.name
             FROM tags t
             INNER JOIN note_tags nt ON nt.tag_id = t.id
             WHERE nt.note_id = ?
             ORDER BY t.name ASC`,
            [noteId]
        );
        return rows;
    }

    /**
     * Replace all tags on a note (delete existing, insert new).
     * Validates that all tagIds belong to the given userId before inserting.
     * @param {number} noteId
     * @param {number[]} tagIds
     * @param {number} userId  — used to verify ownership of tags
     * @returns {Promise<void>}
     */
    async setTagsForNote(noteId, tagIds, userId) {
        const conn = await pool.getConnection();
        try {
            await conn.beginTransaction();

            // Remove all existing tag associations for this note
            await conn.execute('DELETE FROM note_tags WHERE note_id = ?', [noteId]);

            if (tagIds && tagIds.length > 0) {
                // Verify all tagIds belong to this user
                const [ownedTags] = await conn.execute(
                    `SELECT id FROM tags WHERE id IN (${tagIds.map(() => '?').join(',')}) AND user_id = ?`,
                    [...tagIds, userId]
                );
                if (ownedTags.length !== tagIds.length) {
                    throw new Error('One or more tag IDs are invalid or do not belong to you');
                }

                // Bulk insert
                const values = tagIds.map((tid) => [noteId, tid]);
                await conn.query('INSERT INTO note_tags (note_id, tag_id) VALUES ?', [values]);
            }

            await conn.commit();
        } catch (err) {
            await conn.rollback();
            throw err;
        } finally {
            conn.release();
        }
    }
}

module.exports = new TagsRepository();
