const { z } = require('zod');

// ── Create Note ──────────────────────────────────────────────────────────────
const createNoteSchema = z.object({
    title: z
        .string({ required_error: 'Title is required' })
        .min(1, 'Title cannot be empty')
        .max(200, 'Title cannot exceed 200 characters')
        .trim(),

    content: z
        .string()
        .max(512000, 'Content cannot exceed 500 KB')
        .optional()
        .default(''),

    is_pinned: z.boolean().optional().default(false),

    // Phase 4
    category_id: z.coerce.number().int().positive().optional().nullable().default(null),
    tag_ids: z.array(z.coerce.number().int().positive()).optional().default([]),
    priority: z.enum(['low', 'medium', 'high']).optional().default('medium'),
});

// ── Update Note (PATCH — all fields optional) ────────────────────────────────
const updateNoteSchema = z.object({
    title: z
        .string()
        .min(1, 'Title cannot be empty')
        .max(200, 'Title cannot exceed 200 characters')
        .trim()
        .optional(),

    content: z
        .string()
        .max(512000, 'Content cannot exceed 500 KB')
        .optional(),

    is_pinned: z.boolean().optional(),

    // Phase 4
    category_id: z.coerce.number().int().positive().optional().nullable(),
    tag_ids: z.array(z.coerce.number().int().positive()).optional(),
    priority: z.enum(['low', 'medium', 'high']).optional(),
}).refine(
    (data) => Object.keys(data).length > 0,
    { message: 'At least one field must be provided for update' }
);

// ── List Notes (query params) ────────────────────────────────────────────────
const listNotesSchema = z.object({
    page: z.coerce.number().int().min(1).optional().default(1),
    limit: z.coerce.number().int().min(1).max(100).optional().default(20),
    sort: z.enum(['updated_at', 'created_at', 'title', 'priority']).optional().default('updated_at'),
    order: z.enum(['asc', 'desc']).optional().default('desc'),
    // Phase 4 filters
    category_id: z.coerce.number().int().positive().optional(),
    tag_id: z.coerce.number().int().positive().optional(),
    priority: z.enum(['low', 'medium', 'high']).optional(),
});

// ── Search Notes (query params) ──────────────────────────────────────────────
const searchNotesSchema = z.object({
    q: z.string().min(1, 'Search query cannot be empty').max(500).optional(),
    category_id: z.coerce.number().int().positive().optional(),
    tag_id: z.coerce.number().int().positive().optional(),
    priority: z.enum(['low', 'medium', 'high']).optional(),
    date_from: z.string().optional(), // ISO date string
    date_to: z.string().optional(),
    page: z.coerce.number().int().min(1).optional().default(1),
    limit: z.coerce.number().int().min(1).max(100).optional().default(20),
}).refine(
    (data) => data.q || data.category_id || data.tag_id || data.priority || data.date_from || data.date_to,
    { message: 'At least one search or filter parameter is required' }
);

module.exports = { createNoteSchema, updateNoteSchema, listNotesSchema, searchNotesSchema };
