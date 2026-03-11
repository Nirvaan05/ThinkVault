const categoriesRepository = require('./categories.repository');
const { AppError } = require('../../middleware/errorHandler');

class CategoriesService {
    /**
     * List all categories for the authenticated user.
     * @param {number} userId
     */
    async listCategories(userId) {
        return categoriesRepository.findAllByUser(userId);
    }

    /**
     * Create a new category.
     * @param {number} userId
     * @param {string} name
     */
    async createCategory(userId, name) {
        try {
            const { id } = await categoriesRepository.create(userId, name);
            return categoriesRepository.findById(id);
        } catch (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                throw new AppError(`Category "${name}" already exists`, 409);
            }
            throw err;
        }
    }

    /**
     * Rename a category.  Ownership enforced here.
     * @param {number} categoryId
     * @param {number} userId
     * @param {string} name
     */
    async updateCategory(categoryId, userId, name) {
        const category = await categoriesRepository.findById(categoryId);
        if (!category) throw new AppError('Category not found', 404);
        if (category.user_id !== userId) throw new AppError('Access denied', 403);

        try {
            await categoriesRepository.update(categoryId, name);
            return categoriesRepository.findById(categoryId);
        } catch (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                throw new AppError(`Category "${name}" already exists`, 409);
            }
            throw err;
        }
    }

    /**
     * Delete a category.  Ownership enforced here.
     * @param {number} categoryId
     * @param {number} userId
     */
    async deleteCategory(categoryId, userId) {
        const category = await categoriesRepository.findById(categoryId);
        if (!category) throw new AppError('Category not found', 404);
        if (category.user_id !== userId) throw new AppError('Access denied', 403);
        await categoriesRepository.deleteById(categoryId);
    }
}

module.exports = new CategoriesService();
