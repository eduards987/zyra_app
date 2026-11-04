# Zyra

Mobile app for small businesses to charge customers via **Pix, debit or credit card**, with a real-time sales dashboard and transaction history.

Built with **Flutter** and **Supabase** (Auth, Postgres, Realtime and Edge Functions).

## Features

- Email/password authentication (Supabase Auth)
- Create a charge, compare the estimated fee of each payment method and open a secure checkout
- Daily revenue dashboard updated in real time
- Transaction history with payment status (pending, paid, failed, canceled)

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter / Dart |
| Backend | Supabase (Postgres, Auth, Realtime, Edge Functions) |
| Payments | Checkout link opened in a WebView |

## Security

- **Row Level Security** on every table: users can only read and create their own records (`supabase/migrations`).
- Transactions are created as `pending`; only the server (payment webhook) can mark them as `paid`.
- User profile row is created by a database trigger, not by the client.
- No keys in the source code: Supabase settings are injected at build time from `env.json` (git-ignored).
- WebView only navigates over HTTPS and validates the exact success domain.
- Android: release builds signed with a private keystore (`key.properties`, git-ignored), app backups disabled.

## Getting started

1. Install Flutter (Dart SDK 3.10+).
2. Copy `env.example.json` to `env.json` and fill in your Supabase URL and anon key.
3. Apply the database migration in `supabase/migrations` (Supabase SQL Editor or `supabase db push`).
4. Run:

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Release build:

```bash
flutter build appbundle --release --dart-define-from-file=env.json
```

## Project structure

```
lib/
  core/        config, models, logging
  features/    auth, home, charge, simulation (checkout), history
  services/    Supabase data access
  ui/          shared components
supabase/
  migrations/  database schema and RLS policies
  functions/   Edge Functions
```

## Project status

Prototype. The app, database security (RLS) and charge flow are implemented.
Payment confirmation via the provider's webhook (marking charges as `paid`)
is the next step and runs server-side.