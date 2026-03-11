const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { AppError } = require('./errorHandler');
const authRepository = require('../modules/auth/auth.repository');

/**
 * Authentication middleware — verifies JWT from Authorization header.
 * Also checks the token blocklist so logged-out tokens are rejected.
 */
async function authenticate(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new AppError('Authentication required', 401);
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, config.jwt.secret);

        // Reject tokens that have been explicitly revoked (logout blocklist)
        if (decoded.jti) {
            const blocked = await authRepository.isBlocklisted(decoded.jti);
            if (blocked) {
                return next(new AppError('Token has been revoked', 401));
            }
        }

        // Attach user info to request
        req.user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role,
        };

        next();
    } catch (err) {
        if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
            return next(new AppError('Invalid or expired token', 401));
        }
        next(err);
    }
}

/**
 * Role-based authorization middleware factory.
 * Must be used after authenticate().
 * @param  {...string} roles - Allowed roles (e.g., 'admin', 'user')
 */
function authorize(...roles) {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        if (!roles.includes(req.user.role)) {
            return next(new AppError('Insufficient permissions', 403));
        }

        next();
    };
}

module.exports = { authenticate, authorize };
