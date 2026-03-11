/**
 * Centralized error handling middleware.
 * Catches all unhandled errors and returns a structured JSON response.
 */
function errorHandler(err, req, res, _next) {
    // Log the full error in development
    if (process.env.NODE_ENV !== 'production') {
        console.error('🔥 Error:', err);
    }

    // Determine status code
    const statusCode = err.statusCode || err.status || 500;

    // Build response
    const response = {
        status: 'error',
        message: err.message || 'Internal server error',
    };

    // Include stack trace in development only
    if (process.env.NODE_ENV !== 'production') {
        response.stack = err.stack;
    }

    res.status(statusCode).json(response);
}

/**
 * Custom application error with HTTP status code.
 */
class AppError extends Error {
    constructor(message, statusCode = 500) {
        super(message);
        this.statusCode = statusCode;
        this.name = 'AppError';
        Error.captureStackTrace(this, this.constructor);
    }
}

module.exports = { errorHandler, AppError };
