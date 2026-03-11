const fs = require('fs');
const path = require('path');
const attachmentsRepository = require('./attachments.repository');
const notesService = require('../notes/notes.service');
const { AppError } = require('../../middleware/errorHandler');

// ── Validation constants ─────────────────────────────────────────────────────
const MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB
const ALLOWED_MIME_PREFIXES = ['image/'];
const ALLOWED_MIME_EXACT = ['application/pdf', 'text/plain'];

function isAllowedMime(mimeType) {
    if (ALLOWED_MIME_EXACT.includes(mimeType)) return true;
    return ALLOWED_MIME_PREFIXES.some((prefix) => mimeType.startsWith(prefix));
}

class AttachmentsService {
    /**
     * Upload and persist a new attachment linked to a note.
     * Validates ownership, MIME type, and file size.
     */
    async uploadAttachment(noteId, userId, file) {
        // Verify the note exists and the caller owns it
        await notesService.getNote(noteId, userId);

        if (!isAllowedMime(file.mimetype)) {
            // Remove uploaded file from disk if type is invalid
            fs.unlink(file.path, () => { });
            throw new AppError(
                'Unsupported file type. Allowed: images, PDF, or plain text.',
                422
            );
        }

        if (file.size > MAX_SIZE_BYTES) {
            fs.unlink(file.path, () => { });
            throw new AppError('File exceeds the 10 MB size limit.', 413);
        }

        const { id } = await attachmentsRepository.create({
            noteId,
            userId,
            filename: file.originalname,
            mimeType: file.mimetype,
            sizeBytes: file.size,
            storagePath: file.path,
        });

        return attachmentsRepository.findById(id);
    }

    /**
     * List all attachments for a note (ownership verified).
     */
    async listAttachments(noteId, userId) {
        await notesService.getNote(noteId, userId);
        return attachmentsRepository.findByNoteId(noteId);
    }

    /**
     * Resolve the file path for streaming to the client (ownership verified).
     */
    async getAttachmentForDownload(attachmentId, userId) {
        const attachment = await attachmentsRepository.findById(attachmentId);
        if (!attachment) throw new AppError('Attachment not found', 404);
        if (attachment.user_id !== userId) {
            throw new AppError('You do not have access to this attachment', 403);
        }
        if (!fs.existsSync(attachment.storage_path)) {
            throw new AppError('Attachment file not found on server', 404);
        }
        return attachment;
    }

    /**
     * Delete an attachment record and its file from disk (ownership verified).
     */
    async deleteAttachment(attachmentId, userId) {
        const attachment = await attachmentsRepository.findById(attachmentId);
        if (!attachment) throw new AppError('Attachment not found', 404);
        if (attachment.user_id !== userId) {
            throw new AppError('You do not have access to this attachment', 403);
        }
        // Remove from disk (best-effort)
        fs.unlink(attachment.storage_path, () => { });
        await attachmentsRepository.deleteById(attachmentId);
    }
}

module.exports = new AttachmentsService();
