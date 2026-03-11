# ThinkVault Architecture

> **Version:** v1.0 — 2026-03-04  
> **Phase:** 8 of 8 — Final

## Overview

ThinkVault is a personal knowledge management application with a Node.js/Express REST API backend and a Flutter mobile client. The system is designed for a **local development / project showcase** environment; all traffic runs over localhost.

---

## System Components

```
┌──────────────────────────────────────────────────┐
│              Flutter Mobile Client               │
│  Android / iOS — Dio HTTP client, Provider state │
└──────────────────┬───────────────────────────────┘
                   │ HTTP  (localhost:3000)
┌──────────────────▼───────────────────────────────┐
│         Node.js / Express REST API               │
│  Helmet • CORS • Rate-limiting • Sanitization    │
│  Maintenance-mode middleware                     │
│  JWT auth (Bearer tokens + JTI blocklist)        │
│  RBAC (user / admin roles)                       │
└──────────────────┬───────────────────────────────┘
                   │ mysql2 pool
┌──────────────────▼───────────────────────────────┐
│               MySQL 8 Database                   │
│  13 Tables — see schema below                    │
└──────────────────────────────────────────────────┘
```

---

## API Surface

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/health` | None | Liveness probe |
| POST | `/api/auth/register` | None | Create account |
| POST | `/api/auth/login` | None | Get JWT token |
| POST | `/api/auth/logout` | User | Revoke token (JTI blocklist) |
| POST | `/api/auth/otp/setup` | User | Get TOTP QR code |
| POST | `/api/auth/otp/verify` | User | Enable TOTP |
| POST | `/api/auth/otp/disable` | User | Disable TOTP |
| GET/POST | `/api/notes` | User | List / create notes |
| GET/PUT/DELETE | `/api/notes/:id` | User (owner) | Read / update / delete |
| GET | `/api/notes/search` | User | Full-text search |
| GET/POST | `/api/categories` | User | List / create categories |
| PUT/DELETE | `/api/categories/:id` | User (owner) | Update / delete |
| GET/POST | `/api/tags` | User | List / create tags |
| PUT/DELETE | `/api/tags/:id` | User (owner) | Update / delete |
| POST | `/api/attachments/upload` | User | Upload file (10 MB max) |
| GET | `/api/attachments/:id/download` | User (owner) | Download |
| DELETE | `/api/attachments/:id` | User (owner) | Delete |
| GET | `/api/sync/delta` | User | Delta sync since ISO timestamp |
| POST | `/api/feedback` | User | Submit feedback / bug report |
| GET | `/api/feedback` | Admin | List all feedback |
| GET | `/api/feedback/:id` | Admin | Get single entry |
| PATCH | `/api/feedback/:id/status` | Admin | Update status |
| GET | `/api/admin/health` | Admin | System health metrics |
| GET | `/api/admin/metrics` | Admin | Usage aggregates |
| GET | `/api/admin/users` | Admin | Paginated user list |
| GET/PUT | `/api/admin/config`, `/api/admin/config/:key` | Admin | Read / update app config |
| GET | `/api/admin/config/audit` | Admin | Config change log |

---

## Database Schema

| Table | Key Columns |
|-------|-------------|
| `users` | id, name, email (UNIQUE), password (argon2), role (user/admin), is_locked, otp_enabled, otp_secret |
| `login_attempts` | id, user_id, success, attempted_at |
| `token_blocklist` | jti (PK), expired_at |
| `categories` | id, user_id, name |
| `notes` | id, user_id, category_id, title, content (MEDIUMTEXT), priority, is_pinned, FULLTEXT(title,content) |
| `tags` | id, user_id, name |
| `note_tags` | note_id, tag_id (composite PK) |
| `attachments` | id, note_id, filename, mime_type, size_bytes, storage_path |
| `feedback` | id, user_id, type (feedback/bug), subject, body, status (open/in_progress/resolved/closed) |
| `app_config` | config_key (PK), config_value, description |
| `config_audit_log` | id, config_key, old_value, new_value, changed_by (FK→users) |

---

## Security Controls

| Control | Implementation |
|---------|---------------|
| Password hashing | Argon2id via `argon2` npm package |
| JWT tokens | HS256, 7-day expiry, `jti` UUID for revocation |
| Token revocation | `token_blocklist` table checked on every authenticated request |
| Account lockout | 5 failed attempts → 5-minute lock (`is_locked`, `locked_until`) |
| Optional 2FA | TOTP via `speakeasy`; QR code provisioned in-app |
| RBAC | `role` column; `authorize('admin')` middleware on all admin routes |
| Input validation | Zod schemas on all request bodies/queries |
| Input sanitization | Custom `sanitize` middleware strips `<script>`, `on*` attributes |
| Rate limiting | 100 req / 15 min per IP via `express-rate-limit` |
| Security headers | `helmet` middleware on all responses |
| File upload limits | 10 MB max, MIME whitelist (images, PDF, plain text) |
| Maintenance mode | `app_config` key read by middleware; non-admin users get 503 |
| SQL injection | Parameterised queries throughout (`pool.execute()` with `?` bindings) |

---

## Data Flow: Note Sync

```
Client                     API                       DB
  │                          │                         │
  │  GET /sync/delta?since=T │                         │
  │─────────────────────────►│                         │
  │                          │  SELECT … updated_at>T  │
  │                          │────────────────────────►│
  │                          │  rows                   │
  │                          │◄────────────────────────│
  │  {notes[], server_time}  │                         │
  │◄─────────────────────────│                         │
```
Last-write-wins; `server_time` is the authoritative timestamp for the next delta call.

---

## Migrations

| File | Description |
|------|-------------|
| `001_initial_schema.sql` | All core tables (users, notes, categories, tags, note_tags, attachments, feedback) |
| `002_token_blocklist.sql` | JWT revocation table |
| `003_notes_indexes.sql` | `is_pinned` column + updated_at index |
| `004_org_search_indexes.sql` | Full-text and organisation indexes |
| `005_attachments_columns.sql` | Attachment storage columns |
| `006_admin_config.sql` | `app_config` + `config_audit_log` tables |
| `007_feedback.sql` | Additional index on `feedback.type` |

---

## Running Locally

```bash
# 1. Backend
cd backend
cp .env.example .env      # fill in DB credentials
npm install
npm run dev               # starts on http://localhost:3000

# 2. Flutter (Android)
cd flutter_app
flutter pub get
flutter run               # connects to localhost:3000 via 10.0.2.2 on emulator
```

### Running Tests

```bash
cd backend
node test/auth.test.js
node test/notes.test.js
node test/search.test.js
node test/sync.test.js
node test/attachments.test.js
node test/admin.test.js
node test/feedback.test.js    # Phase 7
node test/e2e.test.js         # Phase 8 end-to-end
node test/security.test.js    # Phase 8 security
```
