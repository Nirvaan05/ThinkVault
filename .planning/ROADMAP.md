# Roadmap: ThinkVault

## Overview

This roadmap takes ThinkVault from architecture foundation to secure, cross-platform, feature-complete delivery for a college final project. Phase order follows hard dependencies: authentication before user data, notes before search, and integration hardening after all feature modules are in place.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation and Data Security Baseline** - Set up project architecture, schema, and secure validation baseline
- [x] **Phase 2: Authentication and Access Control** - Implement complete auth flow with lockout and optional OTP
- [x] **Phase 3: Core Notes Lifecycle** - Deliver note CRUD and rich text editing
- [x] **Phase 4: Organization and Search** - Add categories, tags, sorting, and full retrieval
- [x] **Phase 5: Attachments and Cross-Device Sync** - Support files and deterministic multi-device sync
- [x] **Phase 6: Admin Operations Module** - Build admin login, metrics, and configuration controls
- [x] **Phase 7: Feedback and Support Module** - Add user feedback and bug reporting pipelines
- [x] **Phase 8: Deployment Hardening and Final Validation** - Complete local deployment baseline and end-to-end quality checks

## Phase Details

### Phase 1: Foundation and Data Security Baseline
**Goal**: Establish backend/client skeleton, relational schema, and secure request-validation baseline.
**Depends on**: Nothing (first phase)
**Requirements**: [AUTH-01, AUTH-05, SECU-02]
**Success Criteria** (what must be TRUE):
  1. User registration endpoint persists accounts with hashed passwords only.
  2. Input validation/sanitization is enforced for auth and note payload DTOs.
  3. MySQL schema for users/notes/categories/tags is created and migration-ready.
  4. Flutter app can call backend health and auth bootstrap endpoints.
**Plans**: 4 plans

Plans:
- [x] 01-01: Initialize Flutter and backend workspaces with shared environment config
- [x] 01-02: Implement MySQL schema and repository scaffolding
- [x] 01-03: Implement registration flow with secure password hashing
- [x] 01-04: Add centralized request validation/sanitization middleware

### Phase 2: Authentication and Access Control
**Goal**: Complete secure authentication workflows and role-protected access patterns.
**Depends on**: Phase 1
**Requirements**: [AUTH-02, AUTH-03, AUTH-04, AUTH-06, SECU-03]
**Success Criteria** (what must be TRUE):
  1. User can log in, receive a valid session/token, and log out.
  2. Failed login threshold triggers temporary account lockout behavior.
  3. OTP verification flow works when enabled by configuration.
  4. User/admin role checks prevent unauthorized endpoint access.
**Plans**: 4 plans

Plans:
- [x] 02-01: Build login/logout token lifecycle and session persistence
- [x] 02-02: Implement failed-login tracking and lockout policy
- [x] 02-03: Integrate optional OTP verification flow
- [x] 02-04: Enforce RBAC guards for user/admin route groups

### Phase 3: Core Notes Lifecycle
**Goal**: Deliver complete note creation, editing, deletion, and listing with rich text support.
**Depends on**: Phase 2
**Requirements**: [NOTE-01, NOTE-02, NOTE-03, NOTE-04, NOTE-06]
**Success Criteria** (what must be TRUE):
  1. Authenticated user can create, edit, and delete only their own notes.
  2. Note listing returns only owned notes with stable pagination/sorting defaults.
  3. Rich text content is stored and rendered consistently across clients.
  4. Negative tests confirm cross-user note access is blocked.
**Plans**: 4 plans

Plans:
- [x] 03-01: Implement note CRUD API endpoints with ownership checks
- [x] 03-02: Build Flutter notes list/detail/editor screens
- [x] 03-03: Add rich text editing and safe content rendering path
- [x] 03-04: Add CRUD and authorization test coverage

### Phase 4: Organization and Search
**Goal**: Make notes discoverable through categories, tags, sorting, and full-text search.
**Depends on**: Phase 3
**Requirements**: [ORGN-01, ORGN-02, ORGN-03, ORGN-04, SRCH-01, SRCH-02, SRCH-03]
**Success Criteria** (what must be TRUE):
  1. User can create categories and tags, then assign them to notes.
  2. User can sort notes by date, priority, and relevance.
  3. Full-text search and metadata filters return accurate user-scoped results.
  4. Search and filter performance remains responsive on seeded dataset.
**Plans**: 4 plans

Plans:
- [x] 04-01: Implement categories/tags schema and APIs
- [x] 04-02: Add taxonomy assignment UX in note workflows
- [x] 04-03: Implement full-text search and combined filter queries
- [x] 04-04: Validate search accuracy and performance with test data

### Phase 5: Attachments and Cross-Device Sync
**Goal**: Support note attachments and stable synchronization across platform clients.
**Depends on**: Phase 4
**Requirements**: [NOTE-05, SYNC-01, SYNC-02, SYNC-03]
**Success Criteria** (what must be TRUE):
  1. User can upload valid attachments and link them to notes.
  2. Account data is available across Android, web, and desktop clients.
  3. Edits from one device appear on other devices after sync.
  4. Sync conflict handling is deterministic and documented.
**Plans**: 4 plans

Plans:
- [x] 05-01: Implement attachment storage strategy with validation limits
- [x] 05-02: Build attachment upload/view UX in Flutter clients
- [x] 05-03: Implement sync refresh strategy and conflict resolution rules
- [x] 05-04: Validate cross-platform sync scenarios through integration tests

### Phase 6: Admin Operations Module
**Goal**: Deliver admin visibility and control functions.
**Depends on**: Phase 2
**Requirements**: [ADMN-01, ADMN-02, ADMN-03]
**Success Criteria** (what must be TRUE):
  1. Admin can authenticate and access protected admin interface/routes.
  2. Admin dashboard exposes health and usage metrics relevant to operations.
  3. Admin can update allowed system configuration values safely.
**Plans**: 3 plans

Plans:
- [x] 06-01: Implement admin auth guard and route namespace
- [x] 06-02: Build metrics collection and dashboard endpoints/UI
- [x] 06-03: Implement configuration management actions with auditability

### Phase 7: Feedback and Support Module
**Goal**: Add user feedback loop and admin-visible support intake.
**Depends on**: Phase 3
**Requirements**: [FDBK-01, FDBK-02, FDBK-03]
**Success Criteria** (what must be TRUE):
  1. Users can submit feedback and bug reports with required fields.
  2. Admin can view and track submitted entries.
  3. Feedback records preserve timestamps and submission metadata.
**Plans**: 3 plans

Plans:
- [x] 07-01: Implement feedback/bug report data model and APIs
- [x] 07-02: Build user-facing feedback submission flows
- [x] 07-03: Build admin feedback review interface and filters

### Phase 8: Deployment Hardening and Final Validation
**Goal**: Complete secure deployment baseline and pass end-to-end verification.
**Depends on**: Phase 5
**Requirements**: [SECU-01]
**Success Criteria** (what must be TRUE):
  1. Application is deployed/configured to use HTTPS/TLS for all client-API communication.
  2. End-to-end test suite passes for authentication, notes, search, sync, admin, and feedback.
  3. Security checklist (SQLi/XSS/authorization/lockout paths) is validated and documented.
  4. Submission artifacts (test evidence and architecture docs) align with implemented system.
**Plans**: 4 plans

Plans:
- [x] 08-01: Environment hardening (.env.example, maintenanceMode middleware)
- [x] 08-02: Execute integrated functional and regression test suites (e2e.test.js)
- [x] 08-03: Execute security-focused validation and fix findings (security.test.js)
- [x] 08-04: Finalize documentation and demo readiness package (ARCHITECTURE.md)

## Progress

**Execution Order:**
Phases execute in numeric order: 2 -> 2.1 -> 2.2 -> 3 -> 3.1 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Data Security Baseline | 4/4 | ✅ Done | 2026-02-28 |
| 2. Authentication and Access Control | 4/4 | ✅ Done | 2026-02-28 |
| 3. Core Notes Lifecycle | 4/4 | ✅ Done | 2026-02-28 |
| 4. Organization and Search | 4/4 | ✅ Done | 2026-02-28 |
| 5. Attachments and Cross-Device Sync | 4/4 | ✅ Done | 2026-03-04 |
| 6. Admin Operations Module | 3/3 | ✅ Done | 2026-03-04 |
| 7. Feedback and Support Module | 3/3 | ✅ Done | 2026-03-04 |
| 8. Deployment Hardening and Final Validation | 4/4 | ✅ Done | 2026-03-04 |
