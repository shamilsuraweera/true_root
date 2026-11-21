# API reference

Base URL: `http://<host>:3000` (dev). All requests and responses are JSON.
Protected routes require `Authorization: Bearer <accessToken>`. Unknown/extra body fields are rejected (HTTP 400).

Roles: `admin`, `farmer`, `trader`, `exporter`. Routes marked **Admin** require the `admin` role.

## Status codes

| Code | Meaning |
|---|---|
| 200/201 | Success |
| 400 | Validation error (response lists the bad fields) |
| 401 | Missing/invalid token or wrong credentials |
| 403 | Authenticated but not allowed (for example not an admin) |
| 404 | Not found |
| 500 | Server error (for example duplicate email on register) |

## Auth

| Method | Path | Body |
|---|---|---|
| POST | `/auth/register` | `{ email, password, role, name? }` |
| POST | `/auth/login` | `{ email, password }` |

Both return `{ "accessToken": "...", "user": { "id": 1, "role": "admin" } }`. Tokens last `JWT_EXPIRES_IN` (default 7 days).

```bash
TOKEN=$(curl -s -X POST localhost:3000/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"admin@trueroot.com","password":"admin123"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["accessToken"])')
curl -H "Authorization: Bearer $TOKEN" localhost:3000/batches
```

## Health

| GET | `/health` | `{ status: "ok", service, timestamp }` (public) |
|---|---|---|

## Batches

| Method | Path | Notes / body |
|---|---|---|
| POST | `/batches` | `{ productId, quantity, ownerId?, grade?, stageId?, unit? }` |
| GET | `/batches` | Query: `limit`, `offset`, `ownerId`, `includeInactive` |
| GET | `/batches/:id` | |
| PATCH | `/batches/:id/quantity` | `{ quantity }` |
| PATCH | `/batches/:id/status` | `{ status }` |
| PATCH | `/batches/:id/stage` | `{ stageId }` (null clears) |
| PATCH | `/batches/:id/grade` | `{ grade }` |
| PATCH | `/batches/:id/disqualify` | `{ reason }` |
| PATCH | `/batches/:id/archive` | |
| DELETE | `/batches/:id` | |
| POST | `/batches/:id/split` | `{ items: [{ quantity, grade? }, ...] }` |
| POST | `/batches/merge` | `{ batchIds: [..], productId? , newProductName?, grade?, status?, stageId?, unit? }` |
| POST | `/batches/:id/transform` | `{ productId, quantity?, grade?, status?, stageId?, unit? }` |
| GET | `/batches/:id/history` | Event timeline |
| GET | `/batches/:id/qr` | QR payload string |
| GET | `/batches/:id/lineage` | Parents and children |

Batch fields: `id, productId, isItem, itemName, ownerId, batchCode, quantity, unit, status, grade, stageId, qrPayload, isDisqualified, createdAt, updatedAt`.

## Ownership requests

| Method | Path | Notes / body |
|---|---|---|
| POST | `/ownership-requests` | `{ batchId, requesterId, ownerId, quantity, note? }` |
| GET | `/ownership-requests/inbox?ownerId=&limit=` | Requests for your batches |
| GET | `/ownership-requests/outbox?requesterId=&limit=` | Requests you made |
| PATCH | `/ownership-requests/:id/approve` | Optional `{ note }`; transfers ownership |
| PATCH | `/ownership-requests/:id/reject` | Optional `{ note }` |

## Users

| Method | Path | Notes / body |
|---|---|---|
| GET | `/users` | |
| GET | `/users/:id` | |
| POST | `/users` | Create user |
| PATCH | `/users/:id` | `name, organization, location, accountType, members[]` ... |
| DELETE | `/users/:id` | |

## Products and stages

| Method | Path | Access | Body |
|---|---|---|---|
| GET | `/products`, `/products/owners/:ownerId` | any user | |
| POST | `/products` | **Admin** | `{ name }` |
| PATCH | `/products/:id` | **Admin** | `{ name }` |
| DELETE | `/products/:id` | **Admin** | |
| GET | `/stages` | any user | |
| POST | `/stages` | **Admin** | `{ name, sequence, active? }` |
| PATCH | `/stages/:id` | **Admin** | `{ name?, sequence?, active? }` |
| DELETE | `/stages/:id` | **Admin** | |

## Events and admin

| Method | Path | Notes |
|---|---|---|
| GET | `/batch-events/recent?limit=&ownerId=` | Latest events |
| GET | `/batch-events/:batchId` | Events of one batch |
| GET | `/admin/overview` | **Admin**: system totals |
