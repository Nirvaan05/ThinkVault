/**
 * HTML entity sanitization for string inputs.
 * Prevents basic XSS by escaping dangerous characters.
 */
function escapeHtml(str) {
    if (typeof str !== 'string') return str;
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;');
}

/**
 * Recursively sanitize all string values in an object.
 */
function sanitizeObject(obj) {
    if (typeof obj === 'string') return escapeHtml(obj.trim());
    if (Array.isArray(obj)) return obj.map(sanitizeObject);
    if (obj && typeof obj === 'object') {
        const sanitized = {};
        for (const [key, value] of Object.entries(obj)) {
            sanitized[key] = sanitizeObject(value);
        }
        return sanitized;
    }
    return obj;
}

/**
 * Express middleware that sanitizes req.body string fields.
 */
function sanitize(req, _res, next) {
    if (req.body && typeof req.body === 'object') {
        req.body = sanitizeObject(req.body);
    }
    next();
}

module.exports = { sanitize, escapeHtml, sanitizeObject };
