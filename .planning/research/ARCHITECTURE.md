# Architecture Research

**Domain:** Secure cross-platform note management
**Researched:** 2026-02-27
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
+-------------------------- Client Layer ---------------------------+
| Flutter App (Android / Web / Desktop)                            |
| - Auth screens  - Notes UI  - Search UI  - Admin UI              |
+------------------------------+------------------------------------+
                               |
                               v
+--------------------------- API Layer -----------------------------+
| REST API (Node.js + Express)                                     |
| - Auth service  - Notes service  - Category/Tag service          |
| - Search service - Feedback service - Admin metrics service      |
+------------------------------+------------------------------------+
                               |
                               v
+-------------------------- Data Layer -----------------------------+
| MySQL: users, notes, categories, tags, note_tags, feedback       |
| plus audit/security event tables                                  |
+------------------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Auth Module | Identity, session/token issuance, lockout, OTP hooks | JWT/session + hashed passwords + failed-login tracking |
| Notes Module | Note CRUD and ownership rules | Service/repository pattern with validation |
| Search Module | Keyword + metadata filtering | Full-text index + SQL filters |
| Admin Module | Health/usage monitoring and config actions | Role-guarded endpoints + dashboard views |
| Feedback Module | User feedback and bug reports | Simple form endpoints + status tracking |

## Recommended Project Structure

```text
backend/
  src/
    config/
    middleware/
    modules/
      auth/
      notes/
      taxonomy/
      search/
      admin/
      feedback/
    db/
    routes/
    app.js

flutter_app/
  lib/
    core/
    features/
      auth/
      notes/
      search/
      admin/
      feedback/
    shared/
    main.dart
```

### Structure Rationale

- **Module boundaries** reduce coupling and help map directly to roadmap phases.
- **Feature-first Flutter structure** makes cross-platform screens and logic easier to evolve.

## Architectural Patterns

### Pattern 1: Modular Monolith

**What:** Single deployable backend with clear internal module boundaries.
**When to use:** College/final-project scale with moderate feature breadth.
**Trade-offs:** Faster delivery, simpler ops; less independent scaling than microservices.

### Pattern 2: Service + Repository Separation

**What:** Route handlers call services; services call data repositories.
**When to use:** Any CRUD-heavy app needing maintainable business rules.
**Trade-offs:** Slight boilerplate, major gains in testability and clarity.

### Pattern 3: Role-Based Authorization Gates

**What:** Central middleware enforces user/admin role checks.
**When to use:** Mixed user and admin capabilities.
**Trade-offs:** Must keep role logic consistent across all endpoints.

## Data Flow

### Request Flow

```text
User action -> Flutter UI -> REST endpoint -> Service -> MySQL
MySQL result -> Service transform -> API response -> UI state update
```

### State Management

```text
API response -> State notifier/provider -> Screen widgets
User input -> Action -> API -> Updated state -> Re-render
```

### Key Data Flows

1. **Create Note:** authenticated user submits note, service validates ownership and category/tag references, DB persists, UI refreshes list.
2. **Search Notes:** user query + filters routed to search service, indexed query returns scoped results, UI presents sorted output.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Single backend instance + indexed MySQL |
| 1k-20k users | Add connection pooling tuning and query optimization |
| 20k+ users | Read replicas/caching and attachment offload if needed |

### Scaling Priorities

1. **First bottleneck:** unindexed search/sort queries.
2. **Second bottleneck:** attachment storage strategy and large payload handling.

## Anti-Patterns

### Anti-Pattern 1: Feature Logic in Routes

**What people do:** put validation/business rules directly in route handlers.
**Why it's wrong:** brittle code and hard testing.
**Do this instead:** centralize business logic in services.

### Anti-Pattern 2: One Mega Notes Table Without Proper Relations

**What people do:** denormalize categories/tags into free-form text blobs.
**Why it's wrong:** weak filtering and inconsistent data.
**Do this instead:** normalized taxonomy tables and mapping relations.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Email provider (OTP/reset) | API call from auth module | Keep optional and bounded for project scope |
| File storage (if needed) | Upload endpoint + metadata table | Use local/managed storage based on deployment constraints |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Auth <-> Notes | middleware + user context | Ownership checks on every notes endpoint |
| Notes <-> Search | service call + indexed queries | Keep search query logic centralized |
| Admin <-> Metrics | read-only service endpoints | Avoid mixing admin and user flows |

## Sources

- User project architecture description
- Established modular monolith patterns for student-scale REST systems

---
*Architecture research for: secure cross-platform note management*
*Researched: 2026-02-27*
