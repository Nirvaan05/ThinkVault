# ThinkVault

## What This Is

ThinkVault is a secure, cross-platform note and information management application that helps users keep personal and professional knowledge in one searchable place. It replaces scattered notes across paper, chat apps, and random folders with a structured digital vault. The first target users are students, professionals, freelancers, and small teams needing organized retrieval.

## Core Value

Users can reliably capture, organize, and instantly find their knowledge from any device in a secure system.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [x] Secure user authentication with account protection
- [x] Full note lifecycle management with organization and search
- [x] Cross-platform access (mobile, web, desktop) with sync
- [ ] Admin monitoring and configuration support
- [ ] Feedback and support collection from users

### Out of Scope

- Enterprise-scale distributed architecture - project scope is a college final project and should avoid overengineering
- Advanced AI note generation/summarization - not required for core v1 value of secure storage and retrieval

## Context

The product addresses information fragmentation: users currently store content in multiple disconnected places and lose retrieval efficiency. The implementation approach is Flutter frontend clients with backend API logic connected to MySQL over HTTPS. The project includes complete software engineering deliverables (UML, DFD, sequence/activity/class/deployment diagrams, test cases, and timeline artifacts) and is intended to demonstrate practical full-stack and security implementation capability.

## Constraints

- **Scope**: College final project scale - avoid unnecessary architectural complexity while still shipping all defined v1 modules
- **Platform**: Flutter single codebase - Android, web, and desktop clients from one codebase
- **Data Layer**: MySQL relational schema - structured tables with integrity constraints
- **Security**: Must include authentication hardening, encryption in transit, input validation, and role-based access
- **Delivery**: v1 includes all listed core modules from project definition

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Include all listed modules in v1 | User explicitly requested complete feature scope for final project | ✅ Confirmed — all modules in scope |
| Use Flutter + MySQL architecture | Matches cross-platform goal and defined system design | ✅ Implemented — Flutter 3.41.2, MySQL 8.4.8, Node.js 22 |
| Keep implementation non-overengineered | Maintain feasibility for academic delivery while preserving core value | ✅ Modular monolith backend; single Flutter codebase |
| Use Argon2id for password hashing | Industry-standard adaptive hash resistant to GPU attacks | ✅ Implemented in Phase 1 — 64MB memory cost, t=3, p=4 |
| Zod for request validation | Type-safe schema validation with clear error messages | ✅ Implemented — middleware factory pattern |
| JWT revocation via jti blocklist | Stateless JWTs need a revocation mechanism for logout without forcing short expiry | ✅ Implemented in Phase 2 — `token_blocklist` DB table; blocklist check on every authenticated request |
| TOTP/OTP via speakeasy (RFC 6238) | Standard, app-agnostic two-factor auth compatible with Google Authenticator and Authy | ✅ Implemented in Phase 2 — `otp_enabled`/`otp_secret` user columns; setup → verify → login flow |
| Admin route namespace with RBAC | Keeps admin endpoints clearly separated and guarded at the router level | ✅ Implemented in Phase 2 — `/api/admin/*` requires `authenticate + authorize('admin')` |
| Notes ownership enforced in service layer | Authorization at the service (not DB) layer keeps controllers thin and ownership logic centralised | ✅ Implemented in Phase 3 — `notesService.getNote()` throws 403 if `note.user_id !== req.user.id` |
| Delta JSON (flutter_quill) for rich text | Platform-agnostic rich text format; stored as `MEDIUMTEXT`; no server-side parsing needed | ✅ Implemented in Phase 3 — `flutter_quill ^10.8.5`; content serialised to JSON string on save |
| LIMIT/OFFSET interpolated as integers | MySQL2 prepared statements reject non-integer LIMIT/OFFSET; safe because values are Zod-validated before use | ✅ Implemented in Phase 3 — `notes.repository.js` uses `LIMIT ${limitInt} OFFSET ${offsetInt}` |
| Categories/tags as separate user-scoped resources | Clean separation: a category or tag belongs to a user and can be reused across notes; note holds `category_id` FK and `tag_ids[]` on write | ✅ Implemented in Phase 4 — `/api/categories` and `/api/tags`; `note_tags` join table with transactional `setTagsForNote` |
| Tag assignment via `tag_ids[]` in note body | Simpler API surface than a separate sub-resource endpoint; one request creates note with tags atomically | ✅ Implemented in Phase 4 — ownership of each tag validated inside the transaction before insert |
| FULLTEXT search in BOOLEAN MODE via `MATCH/AGAINST` | MySQL native; zero extra dependencies; already indexed in migration 001; supports prefix/phrase queries | ✅ Implemented in Phase 4 — `GET /api/notes/search`; score `?` param must precede WHERE params in MySQL2 array |
| Multer v2 disk storage for attachments | Simple file storage at `uploads/`; MIME whitelist for security; 10MB transport-layer limit | ✅ Implemented in Phase 5 — `multer.diskStorage`; whitelist: images, PDF, text/plain |
| Attachment ownership via `user_id` column | Avoids JOIN to notes table on every ownership check; denormalized for performance | ✅ Implemented in Phase 5 — migration 005 adds `user_id` + FK + composite index |
| Timestamp-based delta sync | Simple, stateless; avoids CRDTs; client sends `since` and gets updated notes back | ✅ Implemented in Phase 5 — `GET /api/sync/delta?since=`; last-write-wins by `updated_at` |
| DDL via `pool.query()` not `pool.execute()` | MySQL2 prepared statements don't support DDL (`ALTER TABLE`); `pool.query()` uses the text protocol instead | ✅ Fixed in Phase 5 — `migrate.js` updated; all previous migrations still pass |

---
*Last updated: 2026-03-04 after Phase 5 completion*
