const { z } = require('zod');

const createCategorySchema = z.object({
    name: z
        .string({ required_error: 'Category name is required' })
        .min(1, 'Name cannot be empty')
        .max(100, 'Name cannot exceed 100 characters')
        .trim(),
});

const updateCategorySchema = z.object({
    name: z
        .string({ required_error: 'Name is required' })
        .min(1, 'Name cannot be empty')
        .max(100, 'Name cannot exceed 100 characters')
        .trim(),
});

module.exports = { createCategorySchema, updateCategorySchema };
