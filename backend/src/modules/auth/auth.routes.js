const { Router } = require('express');
const authController = require('./auth.controller');
const { validate } = require('../../middleware/validate');
const {
    registerSchema,
    loginSchema,
    otpVerifySchema,
    otpDisableSchema,
} = require('./auth.schemas');
const { authenticate } = require('../../middleware/auth');

const router = Router();

// ── Public routes ───────────────────────────────────────────────────────────
router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);

// ── Protected routes (require valid JWT) ───────────────────────────────────
router.post('/logout', authenticate, authController.logout);
router.get('/profile', authenticate, authController.getProfile);
router.get('/status', authenticate, authController.getStatus);

// ── OTP routes (all protected) ──────────────────────────────────────────────
router.post('/otp/setup', authenticate, authController.setupOtp);
router.post('/otp/verify', authenticate, validate(otpVerifySchema), authController.verifyOtp);
router.post('/otp/disable', authenticate, validate(otpDisableSchema), authController.disableOtp);

module.exports = router;
