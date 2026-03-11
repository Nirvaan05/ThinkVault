const notesService = require('./notes.service');

const notesController = {
    /** POST /notes */
    async createNote(req, res, next) {
        try {
            const { title, content, is_pinned, category_id, priority, tag_ids } = req.body;
            const note = await notesService.createNote(req.user.id, {
                title, content, is_pinned, category_id, priority, tag_ids,
            });
            res.status(201).json({ status: 'success', data: note });
        } catch (err) {
            next(err);
        }
    },

    /** GET /notes */
    async listNotes(req, res, next) {
        try {
            const { page, limit, sort, order, category_id, tag_id, priority } = req.query;
            const result = await notesService.listNotes(req.user.id, {
                page, limit, sort, order, category_id, tag_id, priority,
            });
            res.json({ status: 'success', data: result });
        } catch (err) {
            next(err);
        }
    },

    /** GET /notes/search */
    async searchNotes(req, res, next) {
        try {
            const { q, category_id, tag_id, priority, date_from, date_to, page, limit } = req.query;
            const result = await notesService.searchNotes(req.user.id, {
                q, category_id, tag_id, priority, date_from, date_to, page, limit,
            });
            res.json({ status: 'success', data: result });
        } catch (err) {
            next(err);
        }
    },

    /** GET /notes/:id */
    async getNote(req, res, next) {
        try {
            const note = await notesService.getNote(Number(req.params.id), req.user.id);
            res.json({ status: 'success', data: note });
        } catch (err) {
            next(err);
        }
    },

    /** PATCH /notes/:id */
    async updateNote(req, res, next) {
        try {
            const { title, content, is_pinned, category_id, priority, tag_ids } = req.body;
            const note = await notesService.updateNote(
                Number(req.params.id),
                req.user.id,
                { title, content, is_pinned, category_id, priority, tag_ids }
            );
            res.json({ status: 'success', data: note });
        } catch (err) {
            next(err);
        }
    },

    /** DELETE /notes/:id */
    async deleteNote(req, res, next) {
        try {
            await notesService.deleteNote(Number(req.params.id), req.user.id);
            res.json({ status: 'success', message: 'Note deleted' });
        } catch (err) {
            next(err);
        }
    },
};

module.exports = notesController;
