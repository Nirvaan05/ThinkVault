const { z } = require('zod');

const createTagSchema = z.object({
    name: z
        .string({ required_error: 'Tag name is required' })
        .min(1, 'Name cannot be empty')
        .max(50, 'Name cannot exceed 50 characters')
        .trim(),
});

module.exports = { createTagSchema };
