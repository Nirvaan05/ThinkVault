# Pitfalls Research

**Domain:** Secure note management
**Researched:** 2026-02-27
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Weak Ownership Enforcement

**What goes wrong:** Users can view or edit notes that do not belong to them.

**Why it happens:** Missing user-scoped queries and incomplete auth middleware use.

**How to avoid:** Enforce ownership checks in service layer for every note/category/tag operation.

**Warning signs:** API tests pass for happy path only; no negative tests for cross-user access.

**Phase to address:** Phase 2 (Authentication) and Phase 3 (Core Notes CRUD).

---

### Pitfall 2: Slow Search Under Real Data

**What goes wrong:** Search becomes laggy, undermining core value.

**Why it happens:** No full-text/index strategy and overly broad SQL queries.

**How to avoid:** Add indexes early, bound query fields, and validate filter combinations.

**Warning signs:** Increasing query time with sample seed data; table scans in query plans.

**Phase to address:** Phase 4 (Organization and Search).

---

### Pitfall 3: Security Features Implemented Superficially

**What goes wrong:** Lockout/OTP/input validation exists but is bypassable or inconsistent.

**Why it happens:** Security added late and not tested via adversarial test cases.

**How to avoid:** Define explicit auth/security test cases and enforce middleware and validation at all API boundaries.

**Warning signs:** Inconsistent validation messages, missing rate-limit hits, or no SQLi/XSS test coverage.

**Phase to address:** Phase 2 and Phase 7 (Hardening and Test Completion).

---

### Pitfall 4: Attachment Handling Causes Data/Storage Issues

**What goes wrong:** Large uploads break API or bloat database.

**Why it happens:** No file type/size limits or unclear storage strategy.

**How to avoid:** Validate MIME/size, cap uploads, and separate file metadata from note content.

**Warning signs:** Upload-related API failures and rapidly growing DB size.

**Phase to address:** Phase 5 (Attachments and Cross-Platform Sync).

---

### Pitfall 5: Overengineering for Team Collaboration

**What goes wrong:** Project stalls trying to build enterprise-grade collaboration too early.

**Why it happens:** Scope pressure and feature creep beyond final-project constraints.

**How to avoid:** Keep single-user editing semantics in v1 and defer complex collaboration.

**Warning signs:** Frequent architecture changes and unfinished core flows.

**Phase to address:** Phase 1 (Foundation and Scope Guardrails).

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded config secrets | Fast setup | Security exposure and deployment pain | Never |
| Skipping DTO/schema validation | Less boilerplate | Runtime bugs and injection risks | Never |
| No migration/versioning discipline | Fast initial coding | Breaks reproducibility and demo stability | Only for throwaway prototypes, not this project |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Flutter <-> API auth | Token stored insecurely | Use secure storage and token refresh strategy |
| MySQL queries | String-concatenated SQL | Always use parameterized queries |
| OTP/email provider | Blocking app flow on external failures | Implement retries/timeouts and clear fallback messaging |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Missing DB indexes | Slow search/list screens | Index frequently queried fields | With moderate note volume |
| Over-fetching note payloads | High latency and UI jank | Paginate and trim fields | As note/attachment count increases |
| Heavy synchronous file processing | API timeout on uploads | Asynchronous processing and limits | With large files or lower-end devices |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Passwords hashed with weak algorithms | Credential compromise | Argon2/Bcrypt with strong parameters |
| Missing input sanitization | SQLi/XSS vulnerabilities | Schema validation + output encoding/sanitization |
| Missing role guards on admin endpoints | Unauthorized admin actions | RBAC middleware and dedicated route namespaces |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Deep nested note organization | Users cannot find notes quickly | Keep category/tag model simple and searchable |
| Ambiguous search filters | Users distrust results | Show active filters clearly and allow quick reset |
| Inconsistent cross-device behavior | Perceived unreliability | Define sync expectations and conflict behavior clearly |

## "Looks Done But Isn't" Checklist

- [ ] **Authentication:** lockout and session expiry paths tested, not only success login.
- [ ] **Search:** keyword + filter combinations tested with realistic dataset.
- [ ] **Attachments:** validation of file size/type and failure responses verified.
- [ ] **Admin module:** role restrictions and audit visibility validated.
- [ ] **Feedback module:** submissions stored and retrievable for review.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Ownership bug in notes | HIGH | Hotfix ownership query guards, backfill audit checks, retest negative scenarios |
| Search latency spike | MEDIUM | Add indexes, optimize SQL, add pagination |
| Security validation gap | HIGH | Patch middleware/validation, run targeted security regression suite |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Weak ownership enforcement | Phase 2-3 | Negative auth/authorization tests pass |
| Slow search under real data | Phase 4 | Query performance within target under seeded data |
| Superficial security implementation | Phase 7 | Security test suite + checklist complete |
| Attachment handling issues | Phase 5 | Upload limits and error handling verified |
| Overengineering collaboration | Phase 1 | Scope remains aligned to approved v1 modules |

## Sources

- User project scope and threat model
- Common failure modes in CRUD/search-centric web applications

---
*Pitfalls research for: secure note management*
*Researched: 2026-02-27*
