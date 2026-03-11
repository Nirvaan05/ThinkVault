const feedbackRepository = require('./feedback.repository');
const { AppError } = require('../../middleware/errorHandler');

const VALID_TYPES = ['feedback', 'bug'];
const VALID_STATUSES = ['open', 'in_progress', 'resolved', 'closed'];

class FeedbackService {
    async submit({ userId, type, subject, body }) {
        if (!VALID_TYPES.includes(type)) {
            throw new AppError(`Invalid type '${type}'. Must be 'feedback' or 'bug'.`, 400);
        }
        if (!subject || subject.trim().length === 0) {
            throw new AppError('Subject is required.', 400);
        }
        if (!body || body.trim().length === 0) {
            throw new AppError('Body is required.', 400);
        }
        return await feedbackRepository.create({ userId, type, subject: subject.trim(), body: body.trim() });
    }

    async list(opts) {
        const { type, status } = opts;
        if (type && !VALID_TYPES.includes(type)) {
            throw new AppError(`Invalid type filter '${type}'.`, 400);
        }
        if (status && !VALID_STATUSES.includes(status)) {
            throw new AppError(`Invalid status filter '${status}'.`, 400);
        }
        return await feedbackRepository.findAll(opts);
    }

    async get(id) {
        const entry = await feedbackRepository.findById(id);
        if (!entry) throw new AppError('Feedback entry not found.', 404);
        return entry;
    }

    async updateStatus(id, status) {
        if (!VALID_STATUSES.includes(status)) {
            throw new AppError(`Invalid status '${status}'.`, 400);
        }
        const entry = await feedbackRepository.findById(id);
        if (!entry) throw new AppError('Feedback entry not found.', 404);
        return await feedbackRepository.updateStatus(id, status);
    }
}

module.exports = new FeedbackService();
