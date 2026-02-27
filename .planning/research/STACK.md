# Stack Research

**Domain:** Secure cross-platform note and information management
**Researched:** 2026-02-27
**Confidence:** MEDIUM

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter | 3.x | Cross-platform UI for Android/Web/Desktop | Single codebase aligns with project constraint and delivery timeline |
| Dart | 3.x | App language/runtime | Native Flutter tooling and strong productivity for student-scale delivery |
| Node.js + Express | 20 LTS | REST API layer | Fast API development, rich ecosystem, easy deployment for final project scale |
| MySQL | 8.x | Relational data store | Matches structured entity model (users, notes, categories, tags) and integrity needs |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `dio` | 5.x | HTTP client in Flutter | API calls, interceptors, retry/timeout handling |
| `flutter_secure_storage` | 9.x | Secure token storage | Persist auth tokens safely on device |
| `provider` or `flutter_riverpod` | 6.x / 2.x | State management | Organize app state for notes, filters, auth session |
| `mysql2` | 3.x | Node MySQL driver | Safe parameterized queries and connection pooling |
| `argon2` or `bcrypt` | latest stable | Password hashing | Secure password storage with adaptive cost |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Postman | API validation | Keep request collections for demo/testing evidence |
| MySQL Workbench | Schema/query management | Good for ERD visualization and quick data checks |
| Git + GitHub | Version control | Required for milestone tracking and reproducibility |

## Installation

```bash
# Backend
npm init -y
npm install express cors helmet express-rate-limit mysql2 jsonwebtoken argon2 dotenv zod
npm install -D nodemon

# Flutter (run in app directory)
flutter pub add dio provider flutter_secure_storage intl
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| MySQL | PostgreSQL | Use if advanced full-text ranking and JSON querying become primary needs |
| Node + Express | FastAPI | Use if team is Python-first and wants typed Python backend |
| Provider/Riverpod | Bloc | Use Bloc if strict event-state architecture is required by evaluator rubric |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Over-splitting into microservices | Unnecessary complexity for college final project scale | Keep a modular monolith backend |
| Storing plaintext or weakly hashed passwords | High security risk | Use Argon2/Bcrypt with secure JWT/session practices |
| Unindexed search fields | Slow search and poor UX | Add MySQL indexes and bounded query filters |

## Stack Patterns by Variant

**If offline-first becomes mandatory later:**
- Add local storage sync queue (`sqflite`/`isar`)
- Because current scope prioritizes online multi-device sync with less complexity

**If attachments grow significantly:**
- Move file blobs to object storage and keep metadata in MySQL
- Because database bloat degrades backup/restore and query performance

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Flutter 3.x | Dart 3.x | Standard compatibility line |
| Express 4.x/5.x | Node 20 LTS | Prefer LTS runtime for stability |
| mysql2 3.x | MySQL 8.x | Supports prepared statements and pooling |

## Sources

- User project specification (provided in initialization conversation)
- Official Flutter docs (stack conventions)
- Official MySQL docs (schema/index/security patterns)
- Node/Express docs (REST API baseline patterns)

---
*Stack research for: secure note management app*
*Researched: 2026-02-27*
