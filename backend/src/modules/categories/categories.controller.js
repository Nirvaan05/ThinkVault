const categoriesService = require('./categories.service');

const categoriesController = {
    /** GET /categories */
    async listCategories(req, res, next) {
        try {
            const categories = await categoriesService.listCategories(req.user.id);
            res.json({ status: 'success', data: categories });
        } catch (err) {
            next(err);
        }
    },

    /** POST /categories */
    async createCategory(req, res, next) {
        try {
            const category = await categoriesService.createCategory(req.user.id, req.body.name);
            res.status(201).json({ status: 'success', data: category });
        } catch (err) {
            next(err);
        }
    },

    /** PATCH /categories/:id */
    async updateCategory(req, res, next) {
        try {
            const category = await categoriesService.updateCategory(
                Number(req.params.id),
                req.user.id,
                req.body.name
            );
            res.json({ status: 'success', data: category });
        } catch (err) {
            next(err);
        }
    },

    /** DELETE /categories/:id */
    async deleteCategory(req, res, next) {
        try {
            await categoriesService.deleteCategory(Number(req.params.id), req.user.id);
            res.json({ status: 'success', message: 'Category deleted' });
        } catch (err) {
            next(err);
        }
    },
};

module.exports = categoriesController;
