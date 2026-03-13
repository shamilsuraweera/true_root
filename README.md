# true_root

True Root is a Flutter + NestJS supply-chain tracker for batches, ownership requests,
QR scanning, and admin management.

## Quick Start

### Flutter (mobile/web)

```bash
flutter clean
flutter pub get
flutter run
```

### Flutter Web (admin panel)

```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port 8080
```

### Regenerate launcher icons

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Regenerate splash assets

```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

### Backend (NestJS API)

```bash
cd backend/api
npm install
npm run start:dev
```

### Database (Postgres)

```bash
# create DB/user
psql -U postgres -f sql/database_create.sql

# reset DB (dev)
psql -U postgres -f sql/reset_database.sql
```

## Project Structure

- `lib/` Flutter mobile app (dashboard, batches, requests, users, profile).
- `backend/api/` NestJS API (auth, batches, ownership requests, admin).
- `sql/` Database helper scripts (create/reset).

## Demo Flow

1. Register or log in.
2. Create a batch (product, quantity, stage).
3. View batch details and QR code.
4. Scan a QR to find a batch.
5. Request ownership from another user.
6. Approve or reject requests from the Requests tab.
7. Use the Admin panel (web) to manage users, products, stages, and audit batches.

## API Reference (Summary)

Base URL: `http://<host>:<port>`

Auth
- `POST /auth/login`
- `POST /auth/register`

Batches
- `GET /batches` (limit, offset, ownerId, includeInactive)
- `GET /batches/:id`
- `PATCH /batches/:id/quantity`
- `PATCH /batches/:id/status`
- `PATCH /batches/:id/stage`
- `PATCH /batches/:id/grade`
- `PATCH /batches/:id/disqualify`
- `PATCH /batches/:id/archive`
- `DELETE /batches/:id`
- `POST /batches/:id/split`
- `POST /batches/merge`
- `POST /batches/:id/transform`
- `GET /batches/:id/history`
- `GET /batches/:id/qr`
- `GET /batches/:id/lineage`

Ownership Requests
- `POST /ownership-requests`
- `GET /ownership-requests/inbox?ownerId=`
- `GET /ownership-requests/outbox?requesterId=`
- `PATCH /ownership-requests/:id/approve`
- `PATCH /ownership-requests/:id/reject`

Users
- `GET /users`
- `GET /users/:id`
- `POST /users`
- `PATCH /users/:id`
- `DELETE /users/:id`

Products
- `GET /products`
- `POST /products`
- `PATCH /products/:id`
- `DELETE /products/:id`

Stages
- `GET /stages`
- `POST /stages`
- `PATCH /stages/:id`
- `DELETE /stages/:id`

Admin
- `GET /admin/overview`

Batch Events
- `GET /batch-events/recent?limit=&ownerId=`
- `GET /batch-events/:batchId`
