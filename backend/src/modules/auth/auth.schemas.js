const { z } = require('zod');

/**
 * Schema for user registration.
 */
const registerSchema = z.object({
    name: z
        .string({ required_error: 'Name is required' })
        .trim()
        .min(2, 'Name must be at least 2 characters')
        .max(100, 'Name must be at most 100 characters'),

    email: z
        .string({ required_error: 'Email is required' })
        .trim()
        .email('Invalid email address')
        .max(255, 'Email must be at most 255 characters')
        .toLowerCase(),

    password: z
        .string({ required_error: 'Password is required' })
        .min(8, 'Password must be at least 8 characters')
        .max(128, 'Password must be at most 128 characters')
        .regex(
            /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?])/,
            'Password must contain uppercase, lowercase, number, and special character'
        ),
});

/**
 * Schema for user login.
 * otp_token is optional — only required if OTP is enabled on the account.
 */
const loginSchema = z.object({
    email: z
        .string({ required_error: 'Email is required' })
        .trim()
        .email('Invalid email address')
        .toLowerCase(),

    password: z
        .string({ required_error: 'Password is required' })
        .min(1, 'Password is required'),

    otp_token: z
        .string()
        .length(6, 'OTP token must be 6 digits')
        .regex(/^\d{6}$/, 'OTP token must be numeric')
        .optional(),
});

/**
 * Schema for OTP verification (enabling OTP).
 */
const otpVerifySchema = z.object({
    token: z
        .string({ required_error: 'OTP token is required' })
        .length(6, 'OTP token must be 6 digits')
        .regex(/^\d{6}$/, 'OTP token must be numeric'),
});

/**
 * Schema for disabling OTP (requires password confirmation).
 */
const otpDisableSchema = z.object({
    password: z
        .string({ required_error: 'Password is required' })
        .min(1, 'Password is required'),
});

module.exports = { registerSchema, loginSchema, otpVerifySchema, otpDisableSchema };
