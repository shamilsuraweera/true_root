# Deployment

True Root has three deployable parts: **PostgreSQL**, the **NestJS API**, and the **Flutter app**
(web build, Android, iOS). Deploy them in that order.

```
 Browser / phone ──HTTPS──▶ reverse proxy (nginx / platform) ──▶ NestJS API ──▶ PostgreSQL
        ▲
        └── static Flutter web files (nginx / CDN / static host)
```

## Before you go live - checklist

- [ ] `NODE_ENV=production` and a strong random `JWT_SECRET` (the API refuses to start without it).
- [ ] Strong database password; database not exposed to the public internet.
- [ ] HTTPS everywhere (Android blocks plain `http://` API calls in release builds by default).
- [ ] `CORS_ORIGINS` set to your web app's exact origin(s). In production an empty value allows **no** browser origin.
- [ ] **Do not use demo accounts** (`admin123` etc.) - create a real admin and remove demo users.
- [ ] Database backups scheduled.
- [ ] Decide how to handle schema changes (see *Known production caveats*).
- [ ] Android: real application ID and release signing key (see below).

## 1. Database (PostgreSQL 14+)

Use a managed service (AWS RDS, Google Cloud SQL, Azure, Supabase, Neon, DigitalOcean) or your own server.

```sql
CREATE ROLE true_root LOGIN PASSWORD '<strong-password>';
CREATE DATABASE true_root OWNER true_root;
```

Managed databases usually require SSL: set `DB_SSL=true`.

Backups (self-hosted): `pg_dump -Fc -U true_root true_root > backup-$(date +%F).dump`, run nightly via cron
and copy off the machine. Restore with `pg_restore -d true_root backup.dump`.

## 2. API

### Environment

```bash
NODE_ENV=production
PORT=3000
DB_HOST=...  DB_PORT=5432  DB_USER=true_root  DB_PASS=...  DB_NAME=true_root  DB_SSL=true
JWT_SECRET=<output of: openssl rand -base64 48>
JWT_EXPIRES_IN=7d
CORS_ORIGINS=https://app.example.com
```

### Option A - VPS with systemd + nginx (simple, cheap)

```bash
# on the server (Ubuntu), as a deploy user
sudo apt install -y nginx git
# install Node 22 (see SETUP.md)
git clone https://github.com/shamilsuraweera/true_root.git && cd true_root && git checkout main
cd backend/api && npm ci && npm run build
```

`/etc/systemd/system/trueroot-api.service`:

```ini
[Unit]
Description=True Root API
After=network.target postgresql.service

[Service]
WorkingDirectory=/home/deploy/true_root/backend/api
EnvironmentFile=/etc/trueroot-api.env        # holds the variables above, chmod 600
ExecStart=/usr/bin/node dist/main
Restart=always
User=deploy

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl enable --now trueroot-api
sudo journalctl -u trueroot-api -f          # logs
```

nginx (`/etc/nginx/sites-available/trueroot-api`), then enable it and get a certificate with
`sudo certbot --nginx -d api.example.com`:

```nginx
server {
  server_name api.example.com;
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

Update: `git pull && cd backend/api && npm ci && npm run build && sudo systemctl restart trueroot-api`.

### Option B - Docker

The repo does not ship a Dockerfile yet. A working starting point (save as `backend/api/Dockerfile`):

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
EXPOSE 3000
CMD ["node", "dist/main"]
```

```bash
docker build -t trueroot-api backend/api
docker run -d --name trueroot-api -p 3000:3000 --env-file api.env --restart unless-stopped trueroot-api
```

### Option C - Platform as a service (Render, Railway, Fly.io, Heroku-style)

- Root directory: `backend/api`; Node 22.
- Build command: `npm ci && npm run build`; start command: `node dist/main`.
- Add the environment variables above and attach a managed Postgres (set `DB_SSL=true`).
- The platform supplies HTTPS and `PORT`.

## 3. Flutter web

```bash
flutter build web --release        # output: build/web
```

Host `build/web` on any static host: nginx, Netlify, Vercel, Firebase Hosting, GitHub Pages, S3 + CloudFront.

nginx example (single-page app fallback):

```nginx
server {
  server_name app.example.com;
  root /var/www/trueroot-web;
  location / { try_files $uri $uri/ /index.html; }
}
```

Add the site's origin (`https://app.example.com`) to the API's `CORS_ORIGINS`.

### Pointing the web app at your API

The app's default API address is `http://127.0.0.1:3000` for web. For a deployed site, every user (or you,
once per browser) must set the real API URL on the login screen: **gear icon -> server URL
`https://api.example.com`**. It is stored in the browser.

> **Known limitation:** there is no build-time setting (`--dart-define`) for the API URL yet. If you want
> the deployed web app to work without that step, change `_defaultUrl()` in
> `lib/core/api/api_config.dart` to your production URL (or read it from `String.fromEnvironment`) and rebuild.

## 4. Android

### One-time: identity and signing

1. **Application ID:** currently `com.example.trueroot` (`android/app/build.gradle.kts`). Change `namespace`
   and `applicationId` to your own (for example `com.yourcompany.trueroot`) before publishing - it cannot change later.
2. **Create a signing key** (keep it and the passwords safe and backed up; losing it blocks updates):

   ```bash
   keytool -genkey -v -keystore ~/trueroot-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias trueroot
   ```

3. Create `android/key.properties` (never commit it):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=trueroot
   storeFile=/home/you/trueroot-release.jks
   ```

4. In `android/app/build.gradle.kts`, load `key.properties` and replace the release
   `signingConfig = signingConfigs.getByName("debug")` with a `release` signing config
   ([Flutter guide](https://docs.flutter.dev/deployment/android#sign-the-app)). Today release builds are
   signed with the **debug key**, which Google Play rejects.

### Build

```bash
flutter build apk --release          # installable file: build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # for Google Play: build/app/outputs/bundle/release/app-release.aab
```

Release builds only talk to **HTTPS** APIs unless you add a network security config. Use HTTPS in production.
Set the API URL on first launch (login screen, gear icon).

Increase `version:` in `pubspec.yaml` (`1.0.1+2`; the number after `+` is the build number) for every upload.

### Distribute

Google Play Console -> create app -> upload the `.aab` -> internal testing -> production. Or share the APK directly.

## 5. iOS (macOS only)

1. Apple Developer account; set a unique Bundle Identifier and your Team in Xcode (`ios/Runner.xcworkspace`).
2. `flutter build ipa --release`
3. Upload with Xcode Organizer or `xcrun altool` / Transporter, then release through TestFlight and App Store Connect.
4. The camera permission text for the QR scanner is already set in `ios/Runner/Info.plist`.

## 6. Updating a live system

1. Merge to `main` (CI is not configured; run `flutter analyze && flutter test` and `npm test` first).
2. Back up the database.
3. Deploy the API, then the web build, then publish mobile builds.
4. API changes must stay backward compatible with the mobile app versions still installed.

## Known production caveats

- **Automatic schema sync.** `synchronize` is on by default (it alters tables on start), which can drop or alter
  columns unexpectedly in production. In production set `DB_SYNCHRONIZE=false` and use migrations
  (`npm run migration:run`, or `DB_MIGRATIONS_RUN=true`), and back up before each deploy.
  See [DATABASE.md](DATABASE.md). Do not run `npm run seed` in production (public demo passwords).
- **No rate limiting or audit of failed logins** on `/auth/login` - put the API behind a proxy/WAF with rate limits.
- **Open registration.** `POST /auth/register` lets anyone create an account with any role, **including admin**.
  Before going public, restrict registration (for example disallow the `admin` role in `RegisterDto`/`AuthService`).
- **No CI/CD.** Add a pipeline (GitHub Actions) running `flutter analyze`, `flutter test`, `npm run lint`, `npm test`.
- **Fonts** are fetched from Google Fonts at runtime; bundle them (`pubspec.yaml` fonts) for offline-first or
  privacy-sensitive deployments.
