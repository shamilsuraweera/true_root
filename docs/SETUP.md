# Setup on a new machine

Follow this guide on a fresh computer. It takes about 30-45 minutes (mostly downloads).
You need: **Git**, **Node.js 22.12+**, **PostgreSQL 14+**, **Flutter 3.50+** (which bundles Dart).
Android builds additionally need the **Android SDK**; iOS builds need a Mac with **Xcode**.

> Only want to run the web app? You do not need the Android SDK or Xcode.

## 1. Get the code

```bash
git clone https://github.com/shamilsuraweera/true_root.git
cd true_root
git checkout dev        # day-to-day branch; `main` is the released branch
```

## 2. Install prerequisites

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils zip libglu1-mesa postgresql postgresql-contrib

# Node 22 (via nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc && nvm install 22 && nvm use 22

# Flutter (stable)
mkdir -p ~/development && cd ~/development
git clone --depth 1 -b stable https://github.com/flutter/flutter.git
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### macOS

```bash
brew install git node@22 postgresql@16
brew services start postgresql@16
brew install --cask flutter           # or clone the stable branch as on Linux
```

### Windows (PowerShell)

```powershell
winget install Git.Git OpenJS.NodeJS PostgreSQL.PostgreSQL.16 Google.AndroidStudio
# Flutter: download the stable zip from https://docs.flutter.dev/get-started/install/windows
# extract to C:\src\flutter and add C:\src\flutter\bin to PATH
```

Check everything:

```bash
git --version && node -v && psql --version && flutter --version
flutter doctor
```

`flutter doctor` lists anything missing. For web-only work, ignore the Android/iOS lines.

## 3. Database

The API creates all tables itself on first start (TypeORM `synchronize`). You only need an empty
database and a user. The defaults below match what the API expects out of the box.

```bash
# Linux/macOS (run as the postgres superuser)
sudo -u postgres psql <<'SQL'
CREATE ROLE true_root LOGIN PASSWORD 'true_root';
CREATE DATABASE true_root OWNER true_root;
SQL
```

On Windows use *SQL Shell (psql)* or pgAdmin and run the same two statements.

Verify:

```bash
PGPASSWORD=true_root psql -h 127.0.0.1 -U true_root -d true_root -c 'select 1'
```

> **Use a strong password anywhere other than your own laptop.** See the environment table below.

## 4. Configure the API (environment variables)

All variables are optional in development; the defaults are shown.

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `3000` | HTTP port |
| `DB_HOST` | `127.0.0.1` | Postgres host |
| `DB_PORT` | `5432` | Postgres port |
| `DB_USER` | `true_root` | Postgres user |
| `DB_PASS` | `true_root` | Postgres password |
| `DB_NAME` | `true_root` | Database name |
| `DB_SSL` | `false` | Set `true` for managed databases that require SSL |
| `JWT_SECRET` | `dev-secret` (dev only) | **Required when `NODE_ENV=production`** - long random string |
| `JWT_EXPIRES_IN` | `7d` | Token lifetime (`3600` seconds, or `15m`, `7d`...) |
| `CORS_ORIGINS` | empty | Comma-separated allowed web origins. Empty = allow all in dev, none in production |
| `NODE_ENV` | unset | Set to `production` in production |

Set them inline for one run, or export them in your shell:

```bash
DB_PASS='my-password' npm run start:dev
```

## 5. Install dependencies

```bash
# API
cd backend/api && npm ci && cd ../..

# App
flutter pub get
```

## 6. Android (optional)

1. Install [Android Studio](https://developer.android.com/studio) and open it once so it installs the SDK.
2. `flutter doctor --android-licenses` and accept all.
3. Create an emulator (Device Manager) or enable *USB debugging* on a phone.
4. `flutter devices` should list it.

The Android emulator reaches your computer's API at `http://10.0.2.2:3000` (the app uses this by default).
A **physical phone** needs your computer's LAN IP; see *Connecting a device to your API* in
[RUNNING.md](RUNNING.md).

## 7. iOS (optional, macOS only)

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo gem install cocoapods
open ios/Runner.xcworkspace   # set your Team under Signing & Capabilities
```

## 8. Demo accounts

Create users by registering in the app or through the API. The login screen has quick-fill chips
for these demo accounts:

| Role | Email | Password |
|---|---|---|
| Admin | admin@trueroot.com | admin123 |
| Farmer | farmer@trueroot.com | farmer123 |
| Trader | trader@trueroot.com | trader123 |
| Exporter | exporter@trueroot.com | exporter123 |

Create them (API must be running):

```bash
for r in admin farmer trader exporter; do
  curl -s -X POST http://127.0.0.1:3000/auth/register \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"${r^} Demo\",\"email\":\"$r@trueroot.com\",\"password\":\"${r}123\",\"role\":\"$r\"}"; echo
done
```

A `500` response means the email already exists, so nothing is wrong.

> `npm run seed` (demo products, stages and batches) expects `sql/seed_data.sql`, which is **not
> currently in the repository**. Without it, create products and stages in the Admin console
> (see the [user guide](USER_GUIDE.md)).

> Demo accounts are for development only. **Never create them in production.**

## 9. Verify the installation

```bash
cd backend/api && npm run build && npm test     # expect: 7 tests passed
cd ../.. && flutter analyze && flutter test     # expect: no errors, 18 tests passed
```

Next: [RUNNING.md](RUNNING.md).
