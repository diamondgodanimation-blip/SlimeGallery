# SlimeVault — phone-first setup

SlimeVault is a public media library with administrator-only uploads and editing.
The frontend is a single static HTML file. Supabase stores the media and metadata.

## What you need

- A GitHub account and a Supabase account.
- A browser on your Android phone.
- The files in this folder.

## Part A — Create the Supabase backend

1. Open https://supabase.com and create a free project.
2. Save your database password somewhere safe. Wait for the project to finish provisioning.
3. In the project dashboard, open **SQL Editor** → **New query**.
4. Open `setup.sql` from this project, copy all its contents, paste into SQL Editor, and press **Run**.
5. Open **Project Settings** → **API** (sometimes shown as API Keys).
6. Copy the **Project URL** and the **publishable key** (or legacy `anon` public key). Never copy or use the `service_role` / secret key in the website.
7. Open `index.html` in your code editor. Find these lines near the bottom:
   `const SUPABASE_URL = "PASTE_YOUR_PROJECT_URL_HERE";`
   `const SUPABASE_ANON_KEY = "PASTE_YOUR_PUBLISHABLE_OR_ANON_KEY_HERE";`
   Replace the quoted placeholders with your Project URL and publishable/anon key.
8. Save `index.html`.

## Part B — Create your administrator account

1. Open your deployed SlimeVault URL (or test the HTML through a local preview that supports internet access).
2. Tap **Sign in**. The sign-in page appears, but the first admin account must be created in Supabase.
3. In Supabase Dashboard, open **Authentication** → **Users** → **Add user** → **Create new user**.
4. Enter your email and a strong password. Confirm the user if the dashboard offers that option.
5. Copy the user's UUID from the Users table.
6. Go to **SQL Editor** and run this statement, replacing the UUID:
   `insert into public.vault_admins (user_id) values ('YOUR-USER-UUID-HERE');`
7. Return to SlimeVault and sign in using that email and password. You should now see Upload assets and Folder buttons.

Do not put your password, service-role key, or database password in `index.html` or GitHub.

## Part C — Publish with GitHub Pages (Android)

1. Open https://github.com and sign in.
2. Tap **+** → **New repository**.
3. Name it `slimevault`, select **Public**, and create the repository.
4. Open the new repository → **Add file** → **Upload files**.
5. Upload `index.html` (you can also upload `setup.sql` and this guide, but they are not needed by the live app).
6. Commit the files to the `main` branch.
7. Open repository **Settings** → **Pages**.
8. Under **Build and deployment**, choose **Deploy from a branch**.
9. Select branch `main`, folder `/ (root)`, then **Save**.
10. Wait a few minutes. GitHub will show your site address, usually:
    `https://YOUR-GITHUB-USERNAME.github.io/slimevault/`

Open that address on your phone. In Chrome, use menu → **Add to Home screen** to make it feel like an app.

## Using SlimeVault

- Public visitors can browse, search, preview and copy public asset URLs.
- Sign in as the vault admin to upload, create folders, edit details, favorite, and delete.
- Upload images, video and audio. The free Supabase plan has a 50 MB per-file cap. Keep uploads below that.
- Search checks title, description, tags and media type.
- Copy URL gives you the direct public file URL. You can paste it into tools that accept direct media URLs.

## Important limitations

- Supabase free storage currently includes 1 GB and 5 GB cached egress; usage beyond free allowances may require a paid plan. Check current pricing before scaling.
- Free Supabase projects can pause after a week of inactivity. Therefore this is not a guaranteed 24/7 service.
- GitHub Pages has a soft bandwidth limit and is intended for static sites, not a commercial SaaS.
- Public bucket files are public to anyone who obtains their URL. Do not upload private or sensitive media.
- The browser may preview supported formats, but an editor may still require downloading/importing the media.
- This starter version uses ordinary browser uploads. Keep each file under 50 MB; very large uploads may fail on unstable mobile connections.
- Use media you own, created yourself, or have permission to reuse. A public URL does not grant copyright permission.

## Troubleshooting

**"Invalid API key"** — Check that the Project URL and publishable/anon key were copied correctly. Do not use a secret/service-role key.

**"Could not load assets"** — Re-run `setup.sql`, and confirm the project is active.

**You can browse but cannot upload** — Confirm you created a Supabase Auth user, inserted its UUID into `public.vault_admins`, and signed in with that user.

**Upload denied / row-level security error** — Confirm the admin UUID is correct and that the SQL setup ran successfully.

**File too large** — Compress or trim the media to less than 50 MB.

**Supabase project paused** — Open the Supabase dashboard and restore/resume the project if the free-plan controls offer that option.

## Security notes

- The publishable/anon key is designed to be used in browser apps. The SQL policies are what protect write operations.
- Never expose a Supabase service-role/secret key in frontend code or a public repository.
- Anyone can read public metadata and media URLs by design. Only an administrator can change records or upload/delete bucket objects.
