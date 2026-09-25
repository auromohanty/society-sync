# SocietySync

B2B SaaS for Indian RWAs and cooperative housing societies: society accounting (maintenance billing, late fees, treasurer tools) and lightweight gate/visitor management.

This repository **is** the `society-sync/` app layout at the repo root (not a nested `society-sync/` folder).

## Stack

- **Mobile:** React Native / Expo (TypeScript)
- **Backend:** Supabase (Postgres, Auth, RLS, Realtime, Edge Functions)
- **Payments (later):** Razorpay / Cashfree → RWA bank details on `societies.rwa_bank_details`

## Project layout

```
├── supabase/
│   ├── migrations/          # SQL schema + RLS
│   ├── functions/             # Edge Function stubs
│   └── config.toml            # Local Supabase CLI config
├── src/
│   ├── components/
│   ├── context/               # Auth + Active Society stubs
│   ├── hooks/
│   ├── navigation/            # React Navigation (not expo-router)
│   ├── screens/
│   │   ├── admin/
│   │   ├── resident/
│   │   └── security/
│   ├── types/
│   └── utils/                 # Supabase client
├── App.tsx
└── .env.example
```

## Prerequisites

- Node.js 20+
- [Expo CLI](https://docs.expo.dev/get-started/installation/) via `npx expo`
- [Supabase CLI](https://supabase.com/docs/guides/cli) for local database and functions

## Environment variables

Copy `.env.example` to `.env` and set:

| Variable | Purpose |
|----------|---------|
| `EXPO_PUBLIC_SUPABASE_URL` | Supabase API URL (local: `http://127.0.0.1:54321`) |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key (`supabase status`) |

Edge Functions use `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` automatically when deployed; set secrets with `supabase secrets set`.

## Local Supabase

```bash
# From repo root
supabase start
supabase db reset          # applies migrations in supabase/migrations/
supabase status            # copy API URL and anon key into .env
```

Serve Edge Functions locally:

```bash
supabase functions serve generate-monthly-bills apply-late-fees razorpay-webhook
```

### Scheduled jobs (documented; wire in dashboard or pg_cron)

| Function | Suggested schedule | Purpose |
|----------|-------------------|---------|
| `generate-monthly-bills` | 1st of month, 00:05 IST | Create `maintenance_bills` per unit |
| `apply-late-fees` | Daily 02:00 IST | Apply late fees on overdue bills |
| `razorpay-webhook` | HTTP webhook | Payment capture → bill status |

## Run the Expo app

```bash
npm install
cp .env.example .env
# fill EXPO_PUBLIC_* from supabase status
npx expo start
```

Use the Expo Go app or an emulator. Role-based placeholder screens load after auth (admin treasurer, resident home, security gate).

## Navigation choice

**React Navigation (native stack)** with screens under `src/screens/` — not `expo-router` — to match the spec folder layout and keep admin/resident/security trees explicit.

## Product spec

See project context in the SocietySync Cursor project store: `docs/project-context.md`.

## License

Private — SocietySync.
