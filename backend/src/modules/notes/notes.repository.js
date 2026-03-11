const { pool } = require('../../config/db');

/** Columns always selected for note rows */
const NOTE_COLS = `n.id, n.user_id, n.category_id, n.title, n.content,
    n.is_pinned, n.priority, n.created_at, n.updated_at`;

/**
 * Fetch tags for a set of note IDs and return a Map<noteId, tag[]>.
 */
async function fetchTagsMap(noteIds) {
    if (!noteIds.length) return new Map();
    const placeholders = noteIds.map(() => '?').join(',');
    const [rows] = await pool.execute(
        `SELECT nt.note_id, t.id, t.name
         FROM note_tags nt
         INNER JOIN tags t ON t.id = nt.tag_id
         WHERE nt.note_id IN (${placeholders})
         ORDER BY t.name ASC`,
        noteIds
    );
    const map = new Map();
    for (const r of rows) {
        if (!map.has(r.note_id)) map.set(r.note_id, []);
        map.get(r.note_id).push({ id: r.id, name: r.name });
    }
    return map;
}

class NotesRepository {
    async create({ userId, title, content, is_pinned, category_id, priority }) {
        const [result] = await pool.execute(
            `INSERT INTO notes (user_id, category_id, title, content, is_pinned, priority)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, category_id ?? null, title, content ?? '', is_pinned ? 1 : 0, priority ?? 'medium']
        );
        return { id: result.insertId };
    }

    async findById(id) {
        const [rows] = await pool.execute(
            `SELECT ${NOTE_COLS} FROM notes n WHERE n.id = ? LIMIT 1`,
            [id]
        );
        if (!rows[0]) return null;
        const note = rows[0];
        const tagsMap = await fetchTagsMap([note.id]);
        note.tags = tagsMap.get(note.id) ?? [];
        return note;
    }

    /**
     * List notes for a user with pagination, sorting, and optional filters.
     * @param {number} userId
     * @param {{ page, limit, sort, order, category_id?, tag_id?, priority? }} opts
     */
    async findAllByUser(userId, {
        page = 1, limit = 20,
        sort = 'updated_at', order = 'desc',
        category_id, tag_id, priority,
    } = {}) {
        const ALLOWED_SORTS = ['updated_at', 'created_at', 'title', 'priority'];
        const ALLOWED_ORDERS = ['asc', 'desc'];
        const safeSort = ALLOWED_SORTS.includes(sort) ? `n.${sort}` : 'n.updated_at';
        const safeOrder = ALLOWED_ORDERS.includes(order) ? order.toUpperCase() : 'DESC';
        const limitInt = Math.floor(Number(limit));
        const offsetInt = Math.floor((Number(page) - 1) * limitInt);

        // Build dynamic WHERE + optional JOIN
        const joinParts = [];
        const joinParams = [];
        const whereParts = ['n.user_id = ?'];
        const whereParams = [userId];

        if (tag_id != null) {
            joinParts.push('INNER JOIN note_tags _nt ON _nt.note_id = n.id AND _nt.tag_id = ?');
            joinParams.push(Number(tag_id));
        }
        if (category_id != null) {
            whereParts.push('n.category_id = ?');
            whereParams.push(Number(category_id));
        }
        if (priority != null) {
            whereParts.push('n.priority = ?');
            whereParams.push(priority);
        }

        const joinSql = joinParts.join(' ');
        const whereSql = whereParts.join(' AND ');
        const allParams = [...joinParams, ...whereParams];

        const [rows] = await pool.execute(
            `SELECT ${NOTE_COLS}
             FROM notes n ${joinSql}
             WHERE ${whereSql}
             ORDER BY ${safeSort} ${safeOrder}
             LIMIT ${limitInt} OFFSET ${offsetInt}`,
            allParams
        );

        const [[{ total }]] = await pool.execute(
            `SELECT COUNT(*) AS total FROM notes n ${joinSql} WHERE ${whereSql}`,
            allParams
        );

        const tagsMap = await fetchTagsMap(rows.map((r) => r.id));
        for (const note of rows) note.tags = tagsMap.get(note.id) ?? [];

        return { notes: rows, total };
    }

    /**
     * Full-text search + optional metadata filters (user-scoped).
     * @param {number} userId
     * @param {{ q?, category_id?, tag_id?, priority?, date_from?, date_to?, page, limit }} opts
     */
    async search(userId, { q, category_id, tag_id, priority, date_from, date_to, page = 1, limit = 20 }) {
        const limitInt = Math.floor(Number(limit));
        const offsetInt = Math.floor((Number(page) - 1) * limitInt);

        const joinParts = [];
        const joinParams = [];
        const whereParts = ['n.user_id = ?'];
        const whereParams = [userId];

        if (tag_id != null) {
            joinParts.push('INNER JOIN note_tags _nt ON _nt.note_id = n.id AND _nt.tag_id = ?');
            joinParams.push(Number(tag_id));
        }
        if (q) {
            whereParts.push('MATCH(n.title, n.content) AGAINST(? IN BOOLEAN MODE)');
            whereParams.push(q);
        }
        if (category_id != null) {
            whereParts.push('n.category_id = ?');
            whereParams.push(Number(category_id));
        }
        if (priority != null) {
            whereParts.push('n.priority = ?');
            whereParams.push(priority);
        }
        if (date_from) {
            whereParts.push('n.created_at >= ?');
            whereParams.push(date_from);
        }
        if (date_to) {
            whereParts.push('n.created_at <= ?');
            whereParams.push(date_to);
        }

        const joinSql = joinParts.join(' ');
        const whereSql = whereParts.join(' AND ');
        const allParams = [...joinParams, ...whereParams];

        // When full-text query given, sort by relevance score; otherwise by date
        const scoreSelect = q ? ', MATCH(n.title, n.content) AGAINST(? IN BOOLEAN MODE) AS _score' : '';
        const scoreParam = q ? [q] : [];
        const orderBy = q ? '_score DESC' : 'n.updated_at DESC';

        const [rows] = await pool.execute(
            `SELECT ${NOTE_COLS}${scoreSelect}
             FROM notes n ${joinSql}
             WHERE ${whereSql}
             ORDER BY ${orderBy}
             LIMIT ${limitInt} OFFSET ${offsetInt}`,
            [...scoreParam, ...allParams]
        );

        const [[{ total }]] = await pool.execute(
            `SELECT COUNT(*) AS total FROM notes n ${joinSql} WHERE ${whereSql}`,
            allParams
        );

        const tagsMap = await fetchTagsMap(rows.map((r) => r.id));
        for (const note of rows) {
            note.tags = tagsMap.get(note.id) ?? [];
            delete note._score;
        }

        return { notes: rows, total };
    }

    async update(id, data) {
        const fields = [];
        const values = [];

        if (data.title !== undefined) { fields.push('title = ?'); values.push(data.title); }
        if (data.content !== undefined) { fields.push('content = ?'); values.push(data.content); }
        if (data.is_pinned !== undefined) { fields.push('is_pinned = ?'); values.push(data.is_pinned ? 1 : 0); }
        if (data.category_id !== undefined) { fields.push('category_id = ?'); values.push(data.category_id ?? null); }
        if (data.priority !== undefined) { fields.push('priority = ?'); values.push(data.priority); }

        if (fields.length === 0) return;

        values.push(id);
        await pool.execute(
            `UPDATE notes SET ${fields.join(', ')}, updated_at = NOW() WHERE id = ?`,
            values
        );
    }

    /**
     * Find all notes for a user updated (or created) after a given ISO timestamp.
     * Used by the sync delta endpoint.
     * @param {number} userId
     * @param {string} since  ISO 8601 datetime string
     */
    async findUpdatedSince(userId, since) {
        const sinceDate = new Date(since);
        const [rows] = await pool.execute(
            `SELECT ${NOTE_COLS}
             FROM notes n
             WHERE n.user_id = ? AND (n.updated_at > ? OR n.created_at > ?)
             ORDER BY n.updated_at DESC`,
            [userId, sinceDate, sinceDate]
        );
        const tagsMap = await fetchTagsMap(rows.map((r) => r.id));
        for (const note of rows) note.tags = tagsMap.get(note.id) ?? [];
        return rows;
    }

    async deleteById(id) {
        await pool.execute('DELETE FROM notes WHERE id = ?', [id]);
    }
}

module.exports = new NotesRepository();
