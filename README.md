# Engineering Workshop Reports — setup guide

Standalone web app for **Condition**, **Work-In-Progress** and **Completion** reports
(Hydraulic Engineering SARL). It runs in any modern browser and installs as an app on
phones and PCs. It has no server-side code: your web server only serves these files,
and jobs + photos live in your own **Supabase** project.

```
index.html              the app
config.js               ← the only file you edit (Supabase URL + key)
manifest.webmanifest    lets phones/PCs install it as an app
sw.js                   offline cache for the app files
_headers                security headers (Netlify / Cloudflare Pages read it automatically)
icons/                  app icons
layout_793d.jpg         fixed liner layout, Dump Body 793D
layout_777.jpg          fixed liner layout, Dump Body 777
vendor/                 bundled libraries (Supabase client, JSZip, jsPDF) — no CDN needed
supabase/setup.sql      database + photo storage setup, run once
```

---

## 1. Create the Supabase project (about 10 minutes)

1. Go to **https://supabase.com** → sign up with a company email → **New project**.
   Name it e.g. `engineering-workshop-reports`, set a strong database password
   (keep it safe), and pick the region closest to the workshop.
2. When the project is ready: **SQL Editor → New query** → paste the whole of
   `supabase/setup.sql` → **Run**. It creates the `jobs` table, the access rules
   (only signed-in staff), live sync, and a private `photos` bucket.
3. **Stop strangers signing up:** **Authentication → Sign In / Providers** →
   turn **off** "Allow new users to sign up". (Email provider stays enabled.)
4. **Create staff accounts:** **Authentication → Users → Add user → Create new user**
   → email + password → tick **Auto Confirm User**. Repeat for each person.
   Remove a user here when someone leaves.
5. **Copy the connection values:** **Project Settings → API** (on newer dashboards,
   **Project Settings → API Keys**):
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public** key (newer dashboards call it the **publishable** key)

   Do **not** use the `service_role` / secret key. It must never go in a web page.

## 2. Fill in `config.js`

```js
window.EWR_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."          // the anon / publishable key
};
```

The anon key is meant to be public; the data is protected by the sign-in plus the
rules from `setup.sql`. Until `config.js` is filled in, the app shows
"Not connected to a database yet".

## 3. Host the folder

Copy the whole folder to any static web server: IIS, nginx, Apache, an intranet
server, or a static host.

- **HTTPS is required.** Installing as an app and the offline cache only work over
  `https://` (or `http://localhost` for testing).
- **Phones must be able to reach the address.** Use a public HTTPS address, or the
  company Wi-Fi/VPN if the server is internal-only.
- **IIS only:** add a MIME type for `.webmanifest` → `application/manifest+json`
  (IIS Manager → site → MIME Types → Add). Everything else uses standard types.
- No PHP, Node or database is needed on your server.

## 4. Install on devices

| Device | How |
|---|---|
| **PC – Chrome / Edge** | Open the address → click **📲 Install app** at the bottom of the job list, or the install icon in the address bar |
| **Android – Chrome** | Open the address → menu ⋮ → **Install app** / **Add to Home screen** |
| **iPhone / iPad – Safari** | Open the address → **Share** → **Add to Home Screen** |

Everyone signs in with the account created in step 1.4. Downloads (Word/PDF) save
to the device's Downloads folder; on iPhone they open in the share sheet.

## 5. Updating the app later

Replace the files on the server (keep your `config.js`). Users get the new version
the next time they open the app while online; nothing to reinstall. If a change
ever seems stuck, change `const CACHE = "ewr-v1"` in `sw.js` to `"ewr-v2"`.

## 6. Backups and limits

- **⬇ Backup** (bottom of the job list) downloads every job's data as a `.json`
  file. Photos stay in Supabase Storage (**Storage → photos**). Take a backup regularly.
- Supabase's **free plan** includes roughly 500 MB of database and 1 GB of file
  storage (about 3,000 report photos at the app's compression). Free projects are
  **paused after a week with no activity**; resume them from the dashboard. Daily
  automatic backups need a paid plan. Check current limits at supabase.com/pricing.
- Usage: Supabase dashboard → **Reports / Usage**.

## 7. How the data is organised (for IT)

- `public.jobs`: one row per job. `id` (text), `data` (jsonb: header, category,
  Condition report, WIP photos/status), `updated_at`, `updated_by` (the user's id).
- Storage bucket `photos` (private): one JPEG per photo, named by a random id that
  the job JSON references. Photos are resized to at most 1800 px before upload.
- Row-level security: any signed-in user can read and edit all jobs. There are no
  per-user restrictions.

---

## 8. Put it on the internet (HTTPS), so it opens from any Wi-Fi

The website files contain **no data and no secrets**: jobs and photos live in
Supabase behind staff sign-in. So the files can sit on a public address. What
protects the data is the staff passwords and the settings in steps 2–3 below.

### Step 1: publish the folder (pick one)

**A. Netlify (easiest, free, HTTPS automatic)**
1. Fill in `config.js` first (section 2).
2. Go to **https://app.netlify.com/drop**, sign up with a company email.
3. Drag the whole `engineering-workshop-reports` folder onto the page.
4. You get an address like `https://something.netlify.app`. Rename it under
   **Site configuration → Change site name**, e.g. `he-workshop-reports`.
5. Updates: **Deploys → drag the new folder** onto the same site.
6. Own domain (optional): **Domain management → Add a domain**, e.g.
   `reports.yourcompany.com`. Netlify issues the HTTPS certificate itself.

**B. Cloudflare Pages (free, HTTPS automatic):** dash.cloudflare.com →
Workers & Pages → Create → Pages → **Upload assets** → upload the folder.

**C. Company server:** IT publishes the folder on a public HTTPS address
(valid certificate, e.g. Let's Encrypt) and redirects `http://` to `https://`.

### Step 2: lock sign-in down in Supabase
1. **Authentication → Sign In / Providers → Email:** "Allow new users to sign
   up" = **OFF**. Only accounts you create can sign in.
2. **Authentication → Sign In / Providers → Email → Password requirements**
   (on some dashboards: Authentication → Policies / Settings): minimum length
   **10**, require **letters and digits**. The app enforces the same rule when
   someone changes their password.
3. **Authentication → URL Configuration → Site URL:** your app's https address.

### Step 3: accounts and passwords
- **One account per person.** Never share a login. You then see who changed
  what (each job records the last editor).
- Create accounts with a temporary password; each person changes it at first
  sign-in with **🔑 Change password** (bottom of the job list).
- **Someone leaves:** Supabase → **Authentication → Users** → find them →
  **Delete user** the same day. They are locked out immediately.
- **Forgotten password:** an admin opens the user in Supabase →
  **Reset password** (sends an email) or deletes and re-creates the account.

### Step 4: security headers (company server only)
Netlify/Cloudflare apply `_headers` automatically. On IIS/nginx/Apache, add the
same headers listed in `_headers` (at minimum `Strict-Transport-Security`,
`X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`).

### Check it works
Open the address on a phone **using mobile data (Wi-Fi off)**: you should see
the sign-in page with a padlock in the address bar, and nothing else until you
sign in.
