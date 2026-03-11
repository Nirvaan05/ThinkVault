const notesRepository = require('./notes.repository');
const tagsRepository = require('../tags/tags.repository');
const { AppError } = require('../../middleware/errorHandler');

class NotesService {
    async createNote(userId, { title, content, is_pinned, category_id, priority, tag_ids }) {
        const { id } = await notesRepository.create({ userId, title, content, is_pinned, category_id, priority });
        if (tag_ids && tag_ids.length > 0) {
            await tagsRepository.setTagsForNote(id, tag_ids, userId);
        }
        return notesRepository.findById(id);
    }

    async listNotes(userId, opts) {
        const { notes, total } = await notesRepository.findAllByUser(userId, opts);
        return {
            notes,
            pagination: {
                total,
                page: opts.page,
                limit: opts.limit,
                pages: Math.ceil(total / opts.limit),
            },
        };
    }

    async getNote(noteId, userId) {
        const note = await notesRepository.findById(noteId);
        if (!note) throw new AppError('Note not found', 404);
        if (note.user_id !== userId) throw new AppError('You do not have access to this note', 403);
        return note;
    }

    async updateNote(noteId, userId, data) {
        await this.getNote(noteId, userId); // ownership check
        await notesRepository.update(noteId, data);
        if (data.tag_ids !== undefined) {
            await tagsRepository.setTagsForNote(noteId, data.tag_ids, userId);
        }
        return notesRepository.findById(noteId);
    }

    async deleteNote(noteId, userId) {
        await this.getNote(noteId, userId); // ownership check
        await notesRepository.deleteById(noteId);
    }

    async searchNotes(userId, params) {
        const { notes, total } = await notesRepository.search(userId, params);
        return {
            notes,
            pagination: {
                total,
                page: params.page,
                limit: params.limit,
                pages: Math.ceil(total / params.limit),
            },
        };
    }
}

module.exports = new NotesService();
