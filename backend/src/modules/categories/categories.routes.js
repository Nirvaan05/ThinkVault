const { Router } = require('express');
const categoriesController = require('./categories.controller');
const { validate } = require('../../middleware/validate');
const { createCategorySchema, updateCategorySchema } = require('./categories.schemas');
const { authenticate } = require('../../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/', categoriesController.listCategories);
router.post('/', validate(createCategorySchema), categoriesController.createCategory);
router.patch('/:id', validate(updateCategorySchema), categoriesController.updateCategory);
router.delete('/:id', categoriesController.deleteCategory);

module.exports = router;
