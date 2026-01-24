# true_root

True Root is a Flutter app with a NestJS backend for batch tracking and ownership workflows.

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
