const path = require('path');
const attachmentsService = require('./attachments.service');

class AttachmentsController {
    /**
     * POST /api/notes/:noteId/attachments
     * Upload a file and link it to the note.
     */
    async uploadAttachment(req, res, next) {
        try {
            const noteId = Number(req.params.noteId);
            const userId = req.user.id;
            const attachment = await attachmentsService.uploadAttachment(noteId, userId, req.file);
            res.status(201).json({ status: 'ok', data: attachment });
        } catch (err) {
            next(err);
        }
    }

    /**
     * GET /api/notes/:noteId/attachments
     * List all attachments for a note.
     */
    async listAttachments(req, res, next) {
        try {
            const noteId = Number(req.params.noteId);
            const userId = req.user.id;
            const attachments = await attachmentsService.listAttachments(noteId, userId);
            res.json({ status: 'ok', data: attachments });
        } catch (err) {
            next(err);
        }
    }

    /**
     * GET /api/attachments/:id/download
     * Stream the file to the client with appropriate headers.
     */
    async downloadAttachment(req, res, next) {
        try {
            const attachmentId = Number(req.params.id);
            const userId = req.user.id;
            const attachment = await attachmentsService.getAttachmentForDownload(attachmentId, userId);
            res.setHeader('Content-Type', attachment.mime_type);
            res.setHeader(
                'Content-Disposition',
                `attachment; filename="${encodeURIComponent(attachment.filename)}"`
            );
            res.setHeader('Content-Length', attachment.size_bytes);
            res.sendFile(path.resolve(attachment.storage_path));
        } catch (err) {
            next(err);
        }
    }

    /**
     * DELETE /api/attachments/:id
     * Delete an attachment and its disk file.
     */
    async deleteAttachment(req, res, next) {
        try {
            const attachmentId = Number(req.params.id);
            const userId = req.user.id;
            await attachmentsService.deleteAttachment(attachmentId, userId);
            res.json({ status: 'ok', message: 'Attachment deleted' });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = new AttachmentsController();
