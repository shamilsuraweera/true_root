# Troubleshooting

## API

| Symptom | Cause / fix |
|---|---|
| `password authentication failed for user "true_root"` | The DB user is missing or has another password. Create it (SETUP.md step 3) or start with `DB_PASS='...'`. |
| `ECONNREFUSED 127.0.0.1:5432` | PostgreSQL is not running: `sudo systemctl start postgresql` (Linux) / `brew services start postgresql@16` (macOS). |
| `database "true_root" does not exist` | `sudo -u postgres createdb -O true_root true_root` |
| `JWT_SECRET is required in production` | Set `JWT_SECRET` when `NODE_ENV=production`. |
| `Not allowed by CORS` (browser console) | Add the web app's origin to `CORS_ORIGINS` (production), including `https://` and no trailing slash. |
| `Must use import to load ES Module` / syntax errors on start | Node is too old. Use Node **22.12 or newer** (`node -v`). |
| Register returns 500 | Email already registered (duplicate). Use another email or log in. |
| `Seed SQL file not found` | `sql/seed_data.sql` is not in the repo. Create data via the Admin console instead. |
| Port 3000 busy | `PORT=3001 npm run start:dev`, then set the app's server URL to match. |
| `npm audit` shows moderate `glob`/`minimatch` | Dev-tooling only (Jest). Not in production dependencies (`npm audit --omit=dev` is clean). |

## App

| Symptom | Cause / fix |
|---|---|
| `No supported devices found matching 'chrome'` | Chrome is not installed. Use `flutter run -d web-server --web-port 8080` and open the URL in any browser. |
| `flutter: command not found` | Add Flutter to PATH: `export PATH="$HOME/development/flutter/bin:$PATH"`. |
| Login says network error / nothing loads | API not running or wrong address. Tap the gear icon on the login screen and set the URL: web/desktop `http://127.0.0.1:3000`, Android emulator `http://10.0.2.2:3000`, phone `http://<PC-LAN-IP>:3000`. |
| Phone cannot reach the API | Same Wi-Fi? Firewall open for 3000 (`sudo ufw allow 3000`)? Using the PC's LAN IP, not `localhost`? |
| Deployed web app calls `127.0.0.1` | Set the server URL on the login screen, or change the default in `lib/core/api/api_config.dart` (DEPLOYMENT.md, section 3). |
| Android release build cannot reach `http://` API | Cleartext HTTP is blocked on release. Use HTTPS. |
| Camera scanner does nothing | Grant camera permission. In browsers it needs HTTPS or `localhost`. |
| Text looks different offline / first launch | Fonts download from Google Fonts at runtime; they fall back to the system font until fetched. |
| `Gradle` / `SDK location not found` | Install the Android SDK, run `flutter doctor --android-licenses`, set `ANDROID_HOME`. |
| `CocoaPods not installed` (iOS) | `sudo gem install cocoapods`, then `cd ios && pod install`. |
| Stale build or odd analyzer errors | `flutter clean && flutter pub get`. |
| Page shows old UI after update (web) | Hard refresh (`Ctrl+Shift+R`) or clear the service-worker cache. |

## Still stuck?

Collect the exact error, the output of `flutter doctor -v`, `node -v`, and the API logs
(`journalctl -u trueroot-api -n 100` in production), then open an issue in the repository.
