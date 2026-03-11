const { Router } = require('express');
const tagsController = require('./tags.controller');
const { validate } = require('../../middleware/validate');
const { createTagSchema } = require('./tags.schemas');
const { authenticate } = require('../../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/', tagsController.listTags);
router.post('/', validate(createTagSchema), tagsController.createTag);
router.delete('/:id', tagsController.deleteTag);

module.exports = router;
