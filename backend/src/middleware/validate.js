/**
 * Zod-based request validation middleware factory.
 * Validates body, query, or params against a Zod schema.
 *
 * @param {import('zod').ZodSchema} schema - The Zod schema to validate against
 * @param {'body'|'query'|'params'} source - Which part of the request to validate
 * @returns {import('express').RequestHandler}
 */
function validate(schema, source = 'body') {
    return (req, res, next) => {
        const result = schema.safeParse(req[source]);

        if (!result.success) {
            const errors = result.error.issues.map((issue) => ({
                field: issue.path.join('.'),
                message: issue.message,
            }));

            return res.status(400).json({
                status: 'error',
                message: 'Validation failed',
                errors,
            });
        }

        // Replace the source with the parsed (and transformed) data
        req[source] = result.data;
        next();
    };
}

module.exports = { validate };
