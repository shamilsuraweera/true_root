# Running the project

Assumes you finished [SETUP.md](SETUP.md). You need **two terminals**: one for the API, one for the app.

## 1. Start the API

```bash
cd backend/api
npm run start:dev        # watch mode, restarts on change; http://localhost:3000
```

Healthy output ends with `Nest application successfully started`. Check it:

```bash
curl http://127.0.0.1:3000/health
```

Other scripts:

| Command | Purpose |
|---|---|
| `npm run start` | Run once (no watch) |
| `npm run build` then `npm run start:prod` | Compile to `dist/` and run production build |
| `npm test` | Unit tests |
| `npm run test:e2e` | End-to-end tests |
| `npm run lint` | ESLint (auto-fixes) |
| `npm run format` | Prettier |

## 2. Start the app

From the repository root:

```bash
flutter pub get
flutter run                      # picks a connected device/emulator
flutter devices                  # list available targets
```

| Target | Command | Notes |
|---|---|---|
| Web (Chrome) | `flutter run -d chrome` | Needs Chrome installed |
| Web (any browser) | `flutter run -d web-server --web-port 8080` | Then open `http://localhost:8080` (Firefox, Edge, Safari...) |
| Android emulator/phone | `flutter run -d <device-id>` | Needs Android SDK |
| iOS simulator | `flutter run -d <device-id>` | macOS + Xcode |
| Desktop | `flutter run -d linux` / `macos` / `windows` | Uses `http://127.0.0.1:3000` |

While running: `r` hot reload, `R` hot restart, `q` quit.

## 3. See the mobile layout in a browser

There is one web build. The layout adapts to the window width:

| Width | Layout |
|---|---|
| under 700 px | **Mobile**: floating bottom navigation bar, stacked login |
| 700-1100 px | Tablet: compact side rail |
| 1100 px and up | **Desktop**: full sidebar with logo; two-column dashboard; split login (from 900 px) |

To preview mobile: open `http://localhost:8080`, press `F12`, then `Ctrl+Shift+M` (Chrome/Edge: device toolbar,
Firefox: Responsive Design Mode) and choose a phone such as iPhone 14 (390 px).

Mobile-only features (camera QR scanner, secure storage) behave differently in a browser.

## 4. Connecting a device to your API

The app picks a default API address per platform:

| Platform | Default API URL |
|---|---|
| Web, desktop | `http://127.0.0.1:3000` |
| Android emulator | `http://10.0.2.2:3000` |

For a **physical phone** (or a browser on another computer) use your computer's LAN IP:

1. Find it: `hostname -I` (Linux), `ipconfig getifaddr en0` (macOS), `ipconfig` (Windows).
2. Allow port 3000 (and 8080 for web) through the firewall (`sudo ufw allow 3000`).
3. For web on a phone: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`, open `http://<LAN-IP>:8080`.
4. In the app: login screen, tap the **gear icon**, enter `http://<LAN-IP>:3000` and save. The value is remembered.

The API listens on `0.0.0.0` and allows all origins in development, so no extra API configuration is needed.

## 5. Quality checks

```bash
flutter analyze          # static analysis
flutter test             # widget tests (login/register/shell at 3 sizes, light + dark)
cd backend/api && npm run lint && npm test
```

## 6. Maintenance tasks

```bash
# Regenerate the brand PNGs (app icon, web icons, favicon) from the code-drawn logo
flutter test tool/gen_icons_test.dart
# Then regenerate platform launcher icons and native splash:
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Upgrade packages
flutter pub upgrade --major-versions && flutter pub outdated
cd backend/api && npm outdated && npm audit
```

The logo is drawn in `lib/core/widgets/brand_logo.dart` (`BrandMarkPainter`). Edit it there and re-run
the generator to update every icon.

## 7. Reset the database (development only)

This **deletes all data**.

```bash
sudo -u postgres psql -c "DROP DATABASE true_root;" -c "CREATE DATABASE true_root OWNER true_root;"
# restart the API: it recreates the tables
```
