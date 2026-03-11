const notesRepository = require('../notes/notes.repository');
const { AppError } = require('../../middleware/errorHandler');
const { z } = require('zod');

const deltaSchema = z.object({
    since: z.string().datetime({ message: 'since must be a valid ISO 8601 datetime' }).optional(),
});

class SyncController {
    /**
     * GET /api/sync/delta?since=<ISO8601>
     * Returns notes updated after 'since' and deleted note IDs.
     *
     * Conflict resolution: last-write-wins by updated_at.
     * The server's updated_at timestamp is authoritative.
     */
    async delta(req, res, next) {
        try {
            const parsed = deltaSchema.safeParse(req.query);
            if (!parsed.success) {
                throw new AppError(parsed.error.errors[0].message, 400);
            }

            const userId = req.user.id;
            const since = parsed.data.since ?? new Date(0).toISOString();

            const updated = await notesRepository.findUpdatedSince(userId, since);

            res.json({
                status: 'ok',
                data: {
                    updated,
                    deleted_ids: [], // Hard-deletes don't leave a tombstone; placeholder for future soft-delete support
                    server_time: new Date().toISOString(),
                    since,
                },
            });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = new SyncController();
