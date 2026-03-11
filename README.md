# ThinkVault

A full-stack personal knowledge management application for organizing notes, ideas, and digital knowledge — built with **Node.js/Express** and **Flutter**.

![License](https://img.shields.io/badge/license-MIT-blue)
![Node](https://img.shields.io/badge/node-%3E%3D18-green)
![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.7-blue)

---

## Features

- **Rich-text notes** — Quill-based editor with formatting, categories, tags, and priority levels
- **Full-text search** — Instant search across all note titles and content
- **File attachments** — Upload images, PDFs, and text files (up to 10 MB)
- **Organization** — Categories and tags for flexible note management
- **Two-factor authentication** — TOTP-based 2FA via Google Authenticator or similar apps
- **Delta sync** — Efficient synchronization using timestamp-based deltas
- **Admin dashboard** — User management, system health, app config, and feedback review
- **Feedback system** — In-app bug reports and feedback with admin status tracking
- **Security hardened** — Argon2id passwords, JWT with JTI blocklist, rate limiting, Helmet, CORS, input sanitization

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Android, iOS, Web, Desktop) |
| **State Management** | Provider |
| **HTTP Client** | Dio |
| **Rich Text** | flutter_quill |
| **Backend** | Node.js + Express 5 |
| **Database** | MySQL 8 |
| **Auth** | JWT + Argon2id + TOTP (speakeasy) |
| **Validation** | Zod |
| **File Uploads** | Multer |

---

## Project Structure

```
ThinkVault/
├── backend/                    # REST API server
│   ├── src/
│   │   ├── config/             # DB pool, env config
│   │   ├── middleware/         # Auth, rate-limit, maintenance mode
│   │   ├── modules/           # Feature modules (auth, notes, tags, etc.)
│   │   └── app.js             # Express app entry point
│   ├── test/                  # API tests
│   ├── .env.example           # Environment template
│   └── package.json
├── flutter_app/               # Mobile & web client
│   ├── lib/
│   │   ├── core/              # API client, config, drawer, theme, utils
│   │   └── features/          # Feature screens (auth, notes, settings, etc.)
│   ├── pubspec.yaml
│   └── analysis_options.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- **Node.js** ≥ 18
- **MySQL** 8.x
- **Flutter** ≥ 3.7
- **Git**

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/ThinkVault.git
cd ThinkVault
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your MySQL credentials and a strong JWT_SECRET

# Start the server (creates tables automatically on first run)
npm run dev
```

The API will start at `http://localhost:3000`. The database schema is auto-initialized on first startup.

### 3. Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Android emulator (update api_config.dart baseUrl to 10.0.2.2 first)
flutter run -d android

# Run on iOS simulator
flutter run -d ios
```

> **Note:** When targeting the Android emulator, change the base URL in `lib/core/api_config.dart` from `localhost` to `10.0.2.2` (the emulator's alias for the host machine).

---

## API Overview

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/auth/register` | POST | — | Create account |
| `/api/auth/login` | POST | — | Get JWT token |
| `/api/auth/logout` | POST | User | Revoke token |
| `/api/auth/otp/setup` | POST | User | TOTP setup (QR code) |
| `/api/auth/otp/verify` | POST | User | Enable TOTP |
| `/api/notes` | GET/POST | User | List / create notes |
| `/api/notes/:id` | GET/PATCH/DELETE | Owner | Read / update / delete |
| `/api/notes/search` | GET | User | Full-text search |
| `/api/categories` | GET/POST | User | List / create categories |
| `/api/tags` | GET/POST | User | List / create tags |
| `/api/attachments/upload` | POST | User | Upload file attachment |
| `/api/sync/delta` | GET | User | Delta sync |
| `/api/feedback` | POST / GET | User / Admin | Submit / list feedback |
| `/api/admin/health` | GET | Admin | System health metrics |
| `/api/admin/users` | GET | Admin | Paginated user list |
| `/api/admin/config` | GET/PUT | Admin | App configuration |

See [ARCHITECTURE.md](.planning/ARCHITECTURE.md) for the full API surface and database schema.

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure:

| Variable | Description | Default |
|---|---|---|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `DB_HOST` | MySQL host | `localhost` |
| `DB_PORT` | MySQL port | `3306` |
| `DB_USER` | MySQL username | `root` |
| `DB_PASS` | MySQL password | — |
| `DB_NAME` | Database name | `thinkvault` |
| `JWT_SECRET` | JWT signing secret | — |
| `JWT_EXPIRES_IN` | Token expiry | `7d` |
| `UPLOAD_DIR` | File upload directory | `./uploads` |

---

## Security

- **Password hashing:** Argon2id with salt
- **Authentication:** JWT Bearer tokens with JTI-based revocation
- **2FA:** TOTP via speakeasy (Google Authenticator compatible)
- **Rate limiting:** Per-IP request throttling on auth endpoints
- **Input validation:** Zod schema validation on all endpoints
- **HTTP hardening:** Helmet security headers + CORS
- **Account lockout:** Automatic lockout after repeated failed login attempts

---

## Running Tests

```bash
cd backend
npm test
```

---

## License

This project is licensed under the MIT License.
