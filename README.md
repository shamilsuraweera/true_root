# True Root

<p align="center"><img src="assets/icon/app_icon.png" alt="True Root logo" width="96"></p>

**True Root** is an agricultural supply-chain traceability platform. Every lot of produce gets a
digital identity (batch) with a QR code, a full tamper-evident history, and an auditable chain of
ownership from the farm, through traders, to the exporter.

- **App** - Flutter (Android, iOS, web, desktop) with Riverpod, one responsive UI for phone, tablet and desktop.
- **API** - NestJS 12 + TypeORM + PostgreSQL, JWT authentication.

## Features

| Area | What you can do |
|---|---|
| Batches | Create, edit, grade, change stage/status, archive, disqualify, delete |
| Lineage | Split, merge and transform batches, with full parent/child lineage |
| QR | Every batch has a QR code; scan it to open the batch instantly |
| Ownership | Request a purchase/transfer, approve or reject, automatic ownership change |
| History | Immutable event timeline for each batch |
| Users | Farmer, Trader, Exporter and Admin roles; company accounts with members |
| Admin console | Manage users, products, stages and audit batches (web and mobile) |
| UX | Light/dark theme (follows the system), offline cache for key lists, responsive layout |

## Documentation

| Guide | For |
|---|---|
| [docs/SETUP.md](docs/SETUP.md) | Setting up a **new machine** from scratch (Linux, macOS, Windows) |
| [docs/RUNNING.md](docs/RUNNING.md) | Running the API and app (web, mobile, phone-in-browser), tests, lint |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Production deployment: API, database, web, Android, iOS |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | How to use the app (all roles) |
| [docs/API.md](docs/API.md) | REST API reference |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code layout, design system, data model |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common errors and fixes |

## 60-second quick start (dev machine already set up)

```bash
# 1. API (terminal 1)
cd backend/api && npm install && npm run start:dev

# 2. App (terminal 2, from the repo root)
flutter pub get
flutter run -d web-server --web-port 8080     # open http://localhost:8080
```

First time on a machine? Follow [docs/SETUP.md](docs/SETUP.md) (database, Flutter, Node).

## Repository layout

```
lib/                 Flutter app (features/, core/ theme + widgets, state/)
backend/api/         NestJS REST API
assets/              Logo and icons (assets/icon)
web/                 Web shell (index.html, manifest, icons, splash)
android/ ios/ ...    Platform projects
tool/                Maintenance scripts (icon generator)
test/                Flutter widget tests
docs/                This documentation
```

## Tech stack

Flutter 3.50 / Dart 3.14 | Riverpod 3 | NestJS 12 | TypeORM 1 | PostgreSQL 14+ | Node 22.12+ | TypeScript 6

## License

Private / unlicensed. All rights reserved by the project owner.
