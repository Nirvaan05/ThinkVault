# Requirements: ThinkVault

**Defined:** 2026-02-27
**Core Value:** Users can reliably capture, organize, and instantly find their knowledge from any device in a secure system.

## v1 Requirements

### Authentication

- [x] **AUTH-01**: User can register with unique email and password.
- [x] **AUTH-02**: User can log in with valid credentials.
- [x] **AUTH-03**: User can log out and invalidate the active session.
- [x] **AUTH-04**: User account is temporarily locked after repeated failed login attempts.
- [x] **AUTH-05**: User passwords are stored as secure hashes, never plaintext.
- [x] **AUTH-06**: User can complete OTP-based verification when enabled.

### Notes and Content

- [x] **NOTE-01**: User can create a note with title and body content.
- [x] **NOTE-02**: User can edit an existing note they own.
- [x] **NOTE-03**: User can delete a note they own.
- [x] **NOTE-04**: User can view a list of their own notes.
- [x] **NOTE-05**: User can attach image or document files to a note.
- [x] **NOTE-06**: User can format note content with rich text controls.

### Organization

- [x] **ORGN-01**: User can create and rename personal categories.
- [x] **ORGN-02**: User can assign one category to a note.
- [x] **ORGN-03**: User can create custom tags and assign multiple tags to a note.
- [x] **ORGN-04**: User can sort note lists by date, priority, or relevance.

### Search and Retrieval

- [x] **SRCH-01**: User can run full-text search across note title and content.
- [x] **SRCH-02**: User can filter results by keyword, tag, category, date range, and media type.
- [x] **SRCH-03**: Search results return only notes the current user is authorized to access.

### Sync and Platform Access

- [x] **SYNC-01**: User can access the same account from Android, web, and desktop clients.
- [x] **SYNC-02**: Note changes made on one device are available on other devices after sync.
- [x] **SYNC-03**: Sync conflict behavior is deterministic and preserves the latest valid edit.

### Admin

- [x] **ADMN-01**: Admin can authenticate and access protected admin routes.
- [x] **ADMN-02**: Admin can view system health and usage metrics.
- [x] **ADMN-03**: Admin can manage operational configuration required by the application.

### Feedback and Support

- [x] **FDBK-01**: User can submit product feedback from within the application.
- [x] **FDBK-02**: User can submit bug reports with reproducible details.
- [x] **FDBK-03**: Submitted feedback entries are visible to admin for follow-up.

### Security and Protection

- [x] **SECU-01**: All API communication uses HTTPS/TLS in deployment environments.
- [x] **SECU-02**: API input is validated and sanitized to reduce SQL injection and XSS risk.
- [x] **SECU-03**: Role-based access control prevents unauthorized access to protected resources.

## v2 Requirements

### Advanced Capabilities

- **COLL-01**: Multiple users can co-edit a note in real time.
- **AINT-01**: Users can auto-summarize or auto-generate notes using AI assistance.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Enterprise multi-tenant isolation and SSO | Beyond college final project scope |
| Complex microservices/event-driven decomposition | Avoid overengineering for current delivery |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | ✅ Done |
| AUTH-02 | Phase 2 | ✅ Done |
| AUTH-03 | Phase 2 | ✅ Done |
| AUTH-04 | Phase 2 | ✅ Done |
| AUTH-05 | Phase 1 | ✅ Done |
| AUTH-06 | Phase 2 | ✅ Done |
| NOTE-01 | Phase 3 | ✅ Done |
| NOTE-02 | Phase 3 | ✅ Done |
| NOTE-03 | Phase 3 | ✅ Done |
| NOTE-04 | Phase 3 | ✅ Done |
| NOTE-05 | Phase 5 | ✅ Done |
| NOTE-06 | Phase 3 | ✅ Done |
| ORGN-01 | Phase 4 | ✅ Done |
| ORGN-02 | Phase 4 | ✅ Done |
| ORGN-03 | Phase 4 | ✅ Done |
| ORGN-04 | Phase 4 | ✅ Done |
| SRCH-01 | Phase 4 | ✅ Done |
| SRCH-02 | Phase 4 | ✅ Done |
| SRCH-03 | Phase 4 | ✅ Done |
| SYNC-01 | Phase 5 | ✅ Done |
| SYNC-02 | Phase 5 | ✅ Done |
| SYNC-03 | Phase 5 | ✅ Done |
| ADMN-01 | Phase 6 | ✅ Done |
| ADMN-02 | Phase 6 | ✅ Done |
| ADMN-03 | Phase 6 | ✅ Done |
| FDBK-01 | Phase 7 | ✅ Done |
| FDBK-02 | Phase 7 | ✅ Done |
| FDBK-03 | Phase 7 | ✅ Done |
| SECU-01 | Phase 8 | ✅ Done (localhost) |
| SECU-02 | Phase 1 | ✅ Done |
| SECU-03 | Phase 2 | ✅ Done |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0

---
*Requirements defined: 2026-02-27*
*Last updated: 2026-03-04 after Phase 7 & 8 completion — all v1 requirements satisfied*

