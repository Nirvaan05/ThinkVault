# Requirements: ThinkVault

**Defined:** 2026-02-27
**Core Value:** Users can reliably capture, organize, and instantly find their knowledge from any device in a secure system.

## v1 Requirements

### Authentication

- [ ] **AUTH-01**: User can register with unique email and password.
- [ ] **AUTH-02**: User can log in with valid credentials.
- [ ] **AUTH-03**: User can log out and invalidate the active session.
- [ ] **AUTH-04**: User account is temporarily locked after repeated failed login attempts.
- [ ] **AUTH-05**: User passwords are stored as secure hashes, never plaintext.
- [ ] **AUTH-06**: User can complete OTP-based verification when enabled.

### Notes and Content

- [ ] **NOTE-01**: User can create a note with title and body content.
- [ ] **NOTE-02**: User can edit an existing note they own.
- [ ] **NOTE-03**: User can delete a note they own.
- [ ] **NOTE-04**: User can view a list of their own notes.
- [ ] **NOTE-05**: User can attach image or document files to a note.
- [ ] **NOTE-06**: User can format note content with rich text controls.

### Organization

- [ ] **ORGN-01**: User can create and rename personal categories.
- [ ] **ORGN-02**: User can assign one category to a note.
- [ ] **ORGN-03**: User can create custom tags and assign multiple tags to a note.
- [ ] **ORGN-04**: User can sort note lists by date, priority, or relevance.

### Search and Retrieval

- [ ] **SRCH-01**: User can run full-text search across note title and content.
- [ ] **SRCH-02**: User can filter results by keyword, tag, category, date range, and media type.
- [ ] **SRCH-03**: Search results return only notes the current user is authorized to access.

### Sync and Platform Access

- [ ] **SYNC-01**: User can access the same account from Android, web, and desktop clients.
- [ ] **SYNC-02**: Note changes made on one device are available on other devices after sync.
- [ ] **SYNC-03**: Sync conflict behavior is deterministic and preserves the latest valid edit.

### Admin

- [ ] **ADMN-01**: Admin can authenticate and access protected admin routes.
- [ ] **ADMN-02**: Admin can view system health and usage metrics.
- [ ] **ADMN-03**: Admin can manage operational configuration required by the application.

### Feedback and Support

- [ ] **FDBK-01**: User can submit product feedback from within the application.
- [ ] **FDBK-02**: User can submit bug reports with reproducible details.
- [ ] **FDBK-03**: Submitted feedback entries are visible to admin for follow-up.

### Security and Protection

- [ ] **SECU-01**: All API communication uses HTTPS/TLS in deployment environments.
- [ ] **SECU-02**: API input is validated and sanitized to reduce SQL injection and XSS risk.
- [ ] **SECU-03**: Role-based access control prevents unauthorized access to protected resources.

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
| AUTH-01 | TBD | Pending |
| AUTH-02 | TBD | Pending |
| AUTH-03 | TBD | Pending |
| AUTH-04 | TBD | Pending |
| AUTH-05 | TBD | Pending |
| AUTH-06 | TBD | Pending |
| NOTE-01 | TBD | Pending |
| NOTE-02 | TBD | Pending |
| NOTE-03 | TBD | Pending |
| NOTE-04 | TBD | Pending |
| NOTE-05 | TBD | Pending |
| NOTE-06 | TBD | Pending |
| ORGN-01 | TBD | Pending |
| ORGN-02 | TBD | Pending |
| ORGN-03 | TBD | Pending |
| ORGN-04 | TBD | Pending |
| SRCH-01 | TBD | Pending |
| SRCH-02 | TBD | Pending |
| SRCH-03 | TBD | Pending |
| SYNC-01 | TBD | Pending |
| SYNC-02 | TBD | Pending |
| SYNC-03 | TBD | Pending |
| ADMN-01 | TBD | Pending |
| ADMN-02 | TBD | Pending |
| ADMN-03 | TBD | Pending |
| FDBK-01 | TBD | Pending |
| FDBK-02 | TBD | Pending |
| FDBK-03 | TBD | Pending |
| SECU-01 | TBD | Pending |
| SECU-02 | TBD | Pending |
| SECU-03 | TBD | Pending |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 0
- Unmapped: 31

---
*Requirements defined: 2026-02-27*
*Last updated: 2026-02-27 after initial definition*
