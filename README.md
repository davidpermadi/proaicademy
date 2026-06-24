# ProAIcademy

A bilingual (English / Bahasa Indonesia) **AI education platform** — courses, e-books,
consulting packages, cart & checkout, testimonials and FAQ. The front end is a client-side
React application rendered by a small in-browser runtime (`dc-runtime`). The backend is
**Supabase** (Postgres + Auth), providing real user authentication and an editable content
catalogue.

## Requirements

- [Node.js](https://nodejs.org/) 16 or newer (used only for the local static server).
- A modern browser and an internet connection (the app talks to Supabase).

No `npm install` is needed — the local server has zero dependencies and React/Babel/Supabase
are vendored in `vendor/`.

## Run it locally

```bash
npm start
# or:  node server.js
# custom port:  node server.js 8080
```

Then open <http://localhost:3000>. (It works out of the box with the committed defaults; no
`.env` needed for local dev.)

| URL | What it serves |
| --- | --- |
| `/` → `app.html` | **The full app** with Supabase auth + database integration. |
| `/index.html` | The original self-contained static bundle (no backend). |

---

## Environment variables

Configuration is **not hardcoded** — it comes from environment variables.

- **Browser (public) config** is read from `window.PROAI_ENV` in
  [`proai-env.js`](proai-env.js). That file is **generated from env vars** by
  `npm run build` ([scripts/generate-env.js](scripts/generate-env.js)). The committed copy
  holds local-dev defaults, so the app runs without a build; regenerate it for other
  environments.
- **Server-side secrets** are set on the Supabase project (Edge Function secrets), never in
  the browser.

Copy [`.env.example`](.env.example) → `.env` and adjust, then `npm run build`.

| Variable | Where | Public? | Purpose |
| --- | --- | --- | --- |
| `SUPABASE_URL` | frontend (`npm run build`) | ✅ | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | frontend (`npm run build`) | ✅ | Supabase anon/publishable key |
| `MIDTRANS_CLIENT_KEY` | frontend (`npm run build`) | ✅ | Midtrans Snap client key |
| `MIDTRANS_IS_PRODUCTION` | frontend **and** function secret | ✅ / — | `false` = sandbox, `true` = live |
| `PORT` | local server | — | Static server port (default 3000) |
| `MIDTRANS_SERVER_KEY` | **Edge Function secret only** | ❌ secret | Server key for Snap + webhook signature |

> `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_ANON_KEY` are injected into Edge
> Functions automatically — never set those yourself.

Set the Edge Function secret(s) — copy
[`supabase/functions/.env.example`](supabase/functions/.env.example) →
`supabase/functions/.env`, then:

```bash
supabase secrets set --env-file ./supabase/functions/.env
# or set them in Dashboard → Edge Functions → Secrets
```

---

## Backend (Supabase)

Project: **ProAIcademy** — `https://yiwgyovzohcwvqpwmesk.supabase.co`
Browser config is read from [`proai-env.js`](proai-env.js) (publishable key only — safe to
expose; Row Level Security protects the data). See *Environment variables* above.

### 1. Authentication

The login/register screen (`Log in` in the nav) supports:

- **Email + password** — register and log in. Works out of the box.
- **Google** and **Facebook** — via `signInWithOAuth`. **The social buttons only appear when
  the provider is actually enabled on the Supabase project.** The app checks
  `/auth/v1/settings` on load, so locally (providers not configured) you'll just see the
  email/password form; once you enable Google/Facebook in the dashboard the buttons appear
  automatically. This avoids the `"Unsupported provider: provider is not enabled"` error you
  get from clicking an unconfigured provider.

When a user signs up, a row is automatically created in `public.profiles` (via the
`on_auth_user_created` trigger), storing their name, email and avatar.

After login the nav button shows the user's name and acts as a **Log out** button. The
session is persisted in the browser and auto-refreshed.

> **Email confirmation is currently ON.** New email/password users receive a confirmation
> email and must confirm before they can log in. For frictionless local testing you can turn
> it off at **Authentication → Sign In / Providers → Email → "Confirm email"** in the
> Supabase dashboard.

#### Enabling Google / Facebook login

These need OAuth credentials that only you can create:

1. **Create OAuth apps**
   - Google: [Google Cloud Console](https://console.cloud.google.com/) → *APIs & Services →
     Credentials → OAuth client ID (Web application)*.
   - Facebook: [Meta for Developers](https://developers.facebook.com/) → *Create App →
     Facebook Login*.
2. **Set the redirect/callback URL** in each provider to:
   `https://yiwgyovzohcwvqpwmesk.supabase.co/auth/v1/callback`
3. **Enable the provider in Supabase**: Dashboard → *Authentication → Sign In / Providers →
   Google / Facebook* → paste the Client ID and Client Secret → save.
4. **Allow the local redirect**: Dashboard → *Authentication → URL Configuration* → add
   `http://localhost:3000` (and `http://localhost:3000/**`) to **Redirect URLs**, and set the
   **Site URL** as appropriate.

After OAuth, the user is redirected back to `http://localhost:3000` and `supabase-js`
completes the sign-in automatically.

### 2. Content database (editable catalogue)

All catalogue content lives in Postgres so prices and copy can be changed without touching
code. On load the app fetches from these tables and falls back to the data bundled in
`app.html` if the network/DB is unavailable.

| Table | Holds | Bilingual columns |
| --- | --- | --- |
| `courses` | Course catalogue (8 rows) | `title`, `description` (`{en,id}` JSON) |
| `ebooks` | E-book catalogue (8 rows) + file refs (`file_path`/`file_name`) | `title`, `description` |
| `consulting_packages` | Consulting tiers (3 rows) | `name`, `tagline`, `features` |
| `testimonials` | Homepage testimonials (5 rows) | `role`, `quote` |
| `faqs` | FAQ section (6 rows) | `question`, `answer` |
| `profiles` | One row per signed-up user | — |

**To edit content**, open the [Supabase Table Editor](https://supabase.com/dashboard/project/yiwgyovzohcwvqpwmesk/editor),
change a price / text / `is_published` flag, and reload the site — the change appears
immediately. Multilingual fields are JSON like `{"en": "...", "id": "..."}`.

**Security model (Row Level Security):**
- Anyone may **read** rows where `is_published = true` on the content tables.
- **Writing** content is *not* granted to the public — manage it via the dashboard or a
  service-role key (e.g. a future admin panel).
- `profiles`: each user can only read/update their **own** row.

### 3. E-book file storage (uploadable downloads)

The actual e-book files (PDF/EPUB/…) live in a **private Supabase Storage bucket**
`ebook-files`. The `ebooks` table references a file via `file_path` / `file_name` /
`file_size_bytes`. On the storefront, an e-book that has a file shows a **Download** button
instead of *Get it*; the file is served through a short-lived **signed URL**.

**Access rules:**
- **Free** e-books (`price = 0`) → anyone can download (direct signed URL).
- **Paid** e-books → **only after a completed payment**, served via the `download-ebook`
  function. Signed-in buyers are verified by their **entitlement**; **guest** buyers are
  verified by a secret **order receipt token**. Being merely logged in is not enough.
- **Uploading** files is admin-only (dashboard / service-role), never the public.

**To add a downloadable file to an e-book:**
1. Open [Storage → `ebook-files`](https://supabase.com/dashboard/project/yiwgyovzohcwvqpwmesk/storage/buckets/ebook-files)
   in the dashboard and **upload** the file (a per-e-book folder like `eb3/…` keeps things tidy).
2. In the [Table Editor](https://supabase.com/dashboard/project/yiwgyovzohcwvqpwmesk/editor),
   open the matching `ebooks` row and set:
   - `file_path` = the object path inside the bucket, e.g. `eb3/ai-career-roadmap-2026.pdf`
   - `file_name` = the filename the user should get, e.g. `AI-Career-Roadmap-2026.pdf`
3. Reload the site — that e-book now shows a working **Download** button.

> A sample file is already attached to **eb8 — "AI Foundations Cheat Sheet"** (free) at
> `eb8/ai-foundations-cheat-sheet.pdf` so you can see the flow end to end. Replace it with
> your real content.

### 4. Payments (Midtrans) — paid files are delivered only after payment

Paid products are sold through **Midtrans Snap**. A buyer can only download a paid e-book's
file **after** the payment succeeds. **Both signed-in users and guests (no account) can
buy and download.** The flow:

```
Checkout ──► create-payment (Edge Function)        ──► Midtrans Snap popup ──► buyer pays
            · recomputes prices from the DB              │
            · signed-in  → order tied to user_id         ▼
            · guest      → order + secret access_token   midtrans-webhook (Edge Function)
                                                         · verifies Midtrans signature
                                                         · marks the order `paid`
                                                         · grants entitlement (signed-in)
                                                                  │
                                                                  ▼
                              download-ebook (Edge Function, service role) issues a signed URL
                              after checking: entitlement (signed-in) OR receipt token (guest)
                                                                  │
                                                                  ▼
                                          Download button delivers the file
```

**Pieces involved:**
- Tables: `orders`, `order_items`, `entitlements`. `orders.user_id` is nullable; guest orders
  carry `guest_email` + a secret `access_token`. RLS lets a user read only their own rows; all
  writes happen server-side via the service role.
- Edge Functions (in [`supabase/functions/`](supabase/functions)):
  - `create-payment` (optional auth) — builds the Snap transaction for a user **or a guest**
    (guest must supply an email). **Prices are recomputed server-side**, so a tampered client
    price is ignored. Returns a guest `access_token` (the download receipt).
  - `midtrans-webhook` (no JWT; authenticated by Midtrans's `signature_key` =
    `sha512(order_id + status_code + gross_amount + server_key)`) — marks the order paid and
    grants entitlements for signed-in buyers.
  - `download-ebook` (no JWT) — returns a signed file URL only to an entitled user or a guest
    presenting the matching paid `order_id` + `access_token`. Guests keep this receipt in
    `localStorage` so their **Download** button keeps working in that browser.

**Setup (one-time):**
1. Get your keys from the [Midtrans dashboard](https://dashboard.midtrans.com/) →
   *Settings → Access Keys* (use **Sandbox** first): a **Server Key** and a **Client Key**.
2. Set the server key as an Edge Function secret (Dashboard → *Edge Functions → Secrets*, or
   CLI):
   ```bash
   supabase secrets set MIDTRANS_SERVER_KEY=YOUR_SERVER_KEY MIDTRANS_IS_PRODUCTION=false
   ```
3. Put the **Client Key** in [`proai-config.js`](proai-config.js) →
   `window.PROAI_MIDTRANS.clientKey` (set `production: true` for live).
4. In the Midtrans dashboard → *Settings → Configuration*, set the **Payment Notification
   URL** to:
   `https://yiwgyovzohcwvqpwmesk.supabase.co/functions/v1/midtrans-webhook`

Until a Client Key is configured, the checkout button reports that Midtrans isn't set up yet
(no broken redirect). Everything else — orders, the webhook, and the entitlement gating —
is already deployed and working.

> **Verified end to end:** (1) signed-in buyer — logged-in but unpaid → blocked; after
> entitlement → file delivered (HTTP 200). (2) guest buyer — created an order with no account,
> webhook marked it paid, then `download-ebook` returned the file with the correct receipt
> token (HTTP 200) while a wrong token was rejected. The **Download** button works for guests
> straight from the e-books page.

### Re-creating the backend from scratch

The schema and seed data are version-controlled under [`supabase/`](supabase/):

```
supabase/
├─ migrations/
│  ├─ 0001_create_content_and_profiles_schema.sql
│  └─ 0002_harden_security_definer_functions.sql
└─ seed.sql
```

Apply them with the [Supabase CLI](https://supabase.com/docs/guides/local-development)
(`supabase db push` then run `seed.sql`), or paste each file into the dashboard SQL editor in
order.

---

## Deployment & hosting

The site is fully static (HTML + JS, no build framework). Two parts deploy independently.

**1. Frontend (static hosting).** Build command generates `proai-env.js` from the host's env
vars; publish the project folder. Configs are included:

- **Netlify** — [`netlify.toml`](netlify.toml): build `npm run build`, publish `.`, root
  rewritten to `app.html`.
- **Vercel** — [`vercel.json`](vercel.json): build `npm run build`, output `.`, `/` rewritten
  to `app.html`.
- **Any static host / your own Node server** — run `npm run build`, then serve the folder
  (`npm start` runs the bundled zero-dependency server on `$PORT`). The entry is `app.html`;
  if the host always serves `index.html` at `/`, add a rewrite `/` → `/app.html` (the old
  `index.html` is the legacy no-backend bundle).

On the hosting dashboard, set `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
`MIDTRANS_CLIENT_KEY`, `MIDTRANS_IS_PRODUCTION` as build env vars.

### Deploy to Hostinger via a GitHub repo

Hostinger **shared hosting** serves static files and does **not** run a build step, so the
public config travels in the committed [`proai-env.js`](proai-env.js) (already filled with the
Supabase values). [`.htaccess`](.htaccess) makes the root serve `app.html`, forces HTTPS, and
hides source files.

1. **Set your public config before pushing.** Either edit [`proai-env.js`](proai-env.js)
   directly (add your `MIDTRANS_CLIENT_KEY`, set `MIDTRANS_IS_PRODUCTION`), or run
   `npm run build` locally with a `.env` and commit the regenerated file.
2. **Push to GitHub:**
   ```bash
   git init && git add . && git commit -m "ProAIcademy site"
   git branch -M main
   git remote add origin https://github.com/<you>/<repo>.git
   git push -u origin main
   ```
   (`.env` and other secrets are kept out by [`.gitignore`](.gitignore).)
3. **Connect it in Hostinger** → hPanel → *Website → Git*: add the repository, set branch
   `main` and the install path to **`public_html`**, then **Deploy**. (Enable *Auto Deploy* /
   add the webhook so each push redeploys.)
4. **Enable SSL** in hPanel (*Security → SSL*) for your domain so the forced-HTTPS rule works.
5. Do the **Backend** steps below (Supabase Auth URL + Midtrans webhook + server-key secret)
   using your Hostinger domain.

> Prefer a **Hostinger VPS**? Run it as a Node app instead: `npm ci` (none needed),
> `npm run build`, then `npm start` (honours `$PORT`) behind Nginx — no `.htaccess` required.

**2. Backend (Supabase).** The database, storage, and Edge Functions already live in the
project. To reproduce / update from the CLI:

```bash
supabase link --project-ref yiwgyovzohcwvqpwmesk
supabase db push                                   # migrations
supabase functions deploy create-payment midtrans-webhook download-ebook
supabase secrets set --env-file ./supabase/functions/.env   # MIDTRANS_SERVER_KEY, ...
```

Then point Midtrans → *Settings → Configuration → Payment Notification URL* at
`https://yiwgyovzohcwvqpwmesk.supabase.co/functions/v1/midtrans-webhook`, and add your
deployed site URL to **Supabase → Authentication → URL Configuration** (Site URL + Redirect
URLs) so OAuth / email links return to the right place.

---

## Project layout

```
ProAIcademy/
├─ app.html                 # Main app entry (Supabase auth + DB) — served at /
├─ proai-env.js             # PUBLIC runtime config (window.PROAI_ENV) — generated by npm run build
├─ proai-config.js          # Reads PROAI_ENV; creates the Supabase client + Midtrans setup
├─ scripts/generate-env.js  # Writes proai-env.js from env vars / .env
├─ .env.example             # Frontend + server env vars (copy to .env)
├─ ProAIcademy.dc.html      # Original source document (CDN runtime, no backend)
├─ support.js               # dc-runtime (loads React/Babel from CDN)
├─ support.local.js         # dc-runtime patched to load React/Babel from ./vendor (offline)
├─ index.html               # Original self-contained bundle (no backend)
├─ vendor/                  # React, ReactDOM, Babel, supabase-js (vendored)
├─ supabase/                # SQL migrations, seed data, and Edge Functions
│  ├─ migrations/           # 0001 schema · 0002 hardening · 0003 storage · 0004 payments · 0005 guest orders
│  ├─ functions/            # create-payment, midtrans-webhook, download-ebook (+ .env.example)
│  └─ seed.sql
├─ server.js                # Zero-dependency Node static server (uses $PORT)
├─ .htaccess                # Hostinger/Apache: root → app.html, HTTPS, hide source
├─ netlify.toml · vercel.json  # Static hosting configs
├─ package.json             # scripts: build (gen env), start, dev
└─ .claude/launch.json      # Dev-server config for preview tooling
```

## How the front end loads data

`app.html` loads `vendor/supabase.js`, then `proai-env.js` (public config), then
`proai-config.js` (which reads `window.PROAI_ENV` and creates `window.proaiSupabase`) before
the runtime mounts. In `componentDidMount` the component:

1. `loadContent()` — fetches the five content tables and replaces the in-memory
   `COURSES` / `EBOOKS` / `CONSULT` / `TESTI` / `FAQ` arrays, then re-renders.
2. `initAuth()` — restores any existing session and subscribes to auth state changes.

If Supabase is unreachable, the bundled fallback data keeps the site fully functional.
