const tagsRepository = require('./tags.repository');
const { AppError } = require('../../middleware/errorHandler');

class TagsService {
    /**
     * List all tags for the authenticated user.
     * @param {number} userId
     */
    async listTags(userId) {
        return tagsRepository.findAllByUser(userId);
    }

    /**
     * Create a new tag.
     * @param {number} userId
     * @param {string} name
     */
    async createTag(userId, name) {
        try {
            const { id } = await tagsRepository.create(userId, name);
            return tagsRepository.findById(id);
        } catch (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                throw new AppError(`Tag "${name}" already exists`, 409);
            }
            throw err;
        }
    }

    /**
     * Delete a tag.  Ownership enforced here.
     * @param {number} tagId
     * @param {number} userId
     */
    async deleteTag(tagId, userId) {
        const tag = await tagsRepository.findById(tagId);
        if (!tag) throw new AppError('Tag not found', 404);
        if (tag.user_id !== userId) throw new AppError('Access denied', 403);
        await tagsRepository.deleteById(tagId);
    }
}

module.exports = new TagsService();
