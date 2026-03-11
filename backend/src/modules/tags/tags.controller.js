const tagsService = require('./tags.service');

const tagsController = {
    /** GET /tags */
    async listTags(req, res, next) {
        try {
            const tags = await tagsService.listTags(req.user.id);
            res.json({ status: 'success', data: tags });
        } catch (err) {
            next(err);
        }
    },

    /** POST /tags */
    async createTag(req, res, next) {
        try {
            const tag = await tagsService.createTag(req.user.id, req.body.name);
            res.status(201).json({ status: 'success', data: tag });
        } catch (err) {
            next(err);
        }
    },

    /** DELETE /tags/:id */
    async deleteTag(req, res, next) {
        try {
            await tagsService.deleteTag(Number(req.params.id), req.user.id);
            res.json({ status: 'success', message: 'Tag deleted' });
        } catch (err) {
            next(err);
        }
    },
};

module.exports = tagsController;
