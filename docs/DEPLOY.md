# Deploy guide: Cloudflare Pages (built from source)

The website is the Flutter web build of `khmer_calendar/`. Cloudflare Pages builds it **on Cloudflare, from source, on every commit**.

- No GitHub Actions are used to deploy the site.
- No generated files are committed (there is no `website/` folder; `khmer_calendar/build/` is gitignored).
- No Node project at all: no `package.json`, lockfile or `tsconfig.json`, so Cloudflare skips `npm install`. The only Node use is one dependency-free script (`scripts/offline-worker.mjs`) that the build runs with the Node already on Cloudflare's build image.
- No Python and no `.env` files.

The **Release** workflow (`.github/workflows/release.yml`) is separate: it builds the Android / Windows / macOS / Linux installers and publishes the GitHub Release. It does not deploy the site.

---

## 1. How it works

```
git push main
   -> Cloudflare Pages clones the repo
   -> reads wrangler.toml (output dir)
   -> runs: bash tools/cf-build.sh
        1. installs Flutter (default 3.47.4) into ~/flutter
        2. flutter pub get
        3. flutter build web --release --no-web-resources-cdn --base-href /
        4. node scripts/offline-worker.mjs   (writes the offline service worker)
   -> publishes khmer_calendar/build/web
```

Files involved:

| File | Role |
|---|---|
| `tools/cf-build.sh` | The Cloudflare build command |
| `scripts/offline-worker.mjs` | Injects the precache list into `offline.js` / `flutter_service_worker.js` |
| `wrangler.toml` | `pages_build_output_dir = "./khmer_calendar/build/web"` |
| `khmer_calendar/web/_headers` | No-cache headers for entry files |
| `khmer_calendar/web/_redirects` | SPA fallback (`/* /index.html 200`) |

Every push to `main` is a production deploy. Other branches and pull requests get preview deployments at `<branch>.khmercalendar.pages.dev`.

---

## 2. One-time setup

1. Cloudflare dashboard > **Workers & Pages > Create > Pages > Connect to Git**.
2. Authorize the Cloudflare GitHub app and select `mounsokdara/Khmer-Calendar`.
3. Set the build configuration:

| Setting | Value |
|---|---|
| Project name | `khmercalendar` |
| Production branch | `main` |
| Framework preset | None |
| Build command | `bash tools/cf-build.sh` |
| Build output directory | `khmer_calendar/build/web` |
| Root directory | *(leave empty)* |

4. Add environment variables (**Settings > Variables and Secrets**, for both Production and Preview):

| Variable | Value | Purpose |
|---|---|---|
| `FLUTTER_VERSION` | *(optional)* e.g. `3.47.4` | Pin Flutter. Default is `3.47.4`, the same version the Release workflow uses |

5. Save and deploy.

Notes:

- Because `wrangler.toml` exists, Cloudflare reads the output directory from it. The build command is still taken from the dashboard.
- A Pages project created with **Direct Upload** cannot be switched to Git integration. If `khmercalendar` was created that way, create a new Git-connected project, move the custom domain over, then delete the old one.
- To change settings later: project > **Settings > Builds > Build configuration > Edit**, then retry the deployment.

---

## 3. Everyday workflow

1. Edit Dart / web / asset files under `khmer_calendar/`.
2. `git push origin main`.
3. Watch the build in **Workers & Pages > khmercalendar > Deployments**. A Flutter build from a cold start takes a few minutes (it installs Flutter each time).
4. Open https://khmercalendar.pages.dev.

Testing without touching production: push to any other branch and open its preview URL.

To roll back: either **Deployments > (previous good deployment) > Rollback to this deployment**, or `git revert <commit>` and push.

---

## 4. Build and test locally

```bash
cd khmer_calendar
flutter pub get
flutter build web --release --no-web-resources-cdn --base-href /
cd ..
node scripts/offline-worker.mjs khmer_calendar/build/web
npx wrangler@4 pages dev khmer_calendar/build/web      # http://localhost:8788
```

Or run the exact Cloudflare script (installs its own Flutter into `~/flutter` if missing):

```bash
bash tools/cf-build.sh
```

Live preview while developing: `cd khmer_calendar && flutter run -d chrome`.

---

## 5. Manual deploy (optional fallback)

Only needed if Git integration is down. Run after a local build (section 4):

```bash
export CLOUDFLARE_API_TOKEN=...      # never commit this
export CLOUDFLARE_ACCOUNT_ID=...
npx wrangler@4 pages deploy khmer_calendar/build/web --project-name=khmercalendar --branch=main
```

---

## 6. Custom domain

**Workers & Pages > khmercalendar > Custom domains > Set up a custom domain**. If the domain uses Cloudflare DNS, the records are created automatically.

---

## 7. Troubleshooting

| Symptom in the build log | Cause / fix |
|---|---|
| `bash: tools/cf-build.sh: No such file or directory` | Wrong repository or branch, or Root directory is set. Confirm the log shows `mounsokdara/Khmer-Calendar` on `main` and Root directory is empty. |
| Output directory not found / empty deploy | `wrangler.toml` must say `./khmer_calendar/build/web` and the build must have finished. Check the lines above the error. |
| `git clone ... --branch 3.47.4` fails | The tag does not exist or GitHub was unreachable. Check the tag exists, or set `FLUTTER_VERSION` to a valid tag (e.g. a newer release) and retry. |
| `pub get` / dependency errors | Dart SDK constraint in `khmer_calendar/pubspec.yaml` (`sdk: ^3.13.3`) must be satisfied by the pinned Flutter version. Bump `FLUTTER_VERSION` or relax the constraint. |
| Warning that Flutter is run as root | Expected on Cloudflare; the script sets `CI=true` and continues. |
| Old version still shows after deploy | The offline service worker caches the site. Hard refresh once; `offline.js`, `index.html` and `version.json` are served `no-cache`. Each build gets a fresh cache name. |
| Deep links 404 | `khmer_calendar/web/_redirects` must contain `/*    /index.html   200`. |
| Release workflow ran too | Expected: it triggers on every non-markdown push to `main` and republishes the installers. It is independent of the site deploy. |

---

## 8. Rules for this repo

- Never commit `website/`, `dist/`, `flutter-web/`, `khmer_calendar/build/` or `release-files/` binaries.
- Never publish the old HTML/Vite app; the public site is the Flutter web app.
- Never commit tokens or signing keys. Signing keys stay in the private vault repo and GitHub secrets.
