const { pool } = require('../../config/db');

class AttachmentsRepository {
    /**
     * Persist a new attachment record.
     */
    async create({ noteId, userId, filename, mimeType, sizeBytes, storagePath }) {
        const [result] = await pool.execute(
            `INSERT INTO attachments (user_id, note_id, filename, mime_type, size_bytes, storage_path)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, noteId, filename, mimeType, sizeBytes, storagePath]
        );
        return { id: result.insertId };
    }

    /**
     * List all attachments for a given note.
     */
    async findByNoteId(noteId) {
        const [rows] = await pool.execute(
            `SELECT id, user_id, note_id, filename, mime_type, size_bytes, storage_path, created_at
             FROM attachments
             WHERE note_id = ?
             ORDER BY created_at ASC`,
            [noteId]
        );
        return rows;
    }

    /**
     * Fetch a single attachment by ID.
     */
    async findById(id) {
        const [rows] = await pool.execute(
            `SELECT id, user_id, note_id, filename, mime_type, size_bytes, storage_path, created_at
             FROM attachments
             WHERE id = ?
             LIMIT 1`,
            [id]
        );
        return rows[0] ?? null;
    }

    /**
     * Delete an attachment record by ID.
     */
    async deleteById(id) {
        await pool.execute('DELETE FROM attachments WHERE id = ?', [id]);
    }
}

module.exports = new AttachmentsRepository();
