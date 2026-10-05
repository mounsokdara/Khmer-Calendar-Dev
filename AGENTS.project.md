# Khmer Calendar

Every app change:

1. Preview locally with `cd khmer_calendar && flutter run -d chrome`. There is no Node project (no `package.json`, no lockfile, no `tsconfig.json`), no Python and no `.env`.
2. Pushing to `main` makes Cloudflare Pages (Git-connected) build the website from source with `bash tools/cf-build.sh` (Flutter web, no GitHub Actions). Nothing generated is committed.
3. Pushing `main` also runs **Release**: it rebuilds the installers and publishes a GitHub Release.
4. Do not commit generated `website/`, `apk-spa/`, `dist/`, `flutter-web/`, `khmer_calendar/build/` or `release-files/` binaries.
5. If the user dislikes a change, revert that commit and push.
6. The public website must be the Flutter web app. Never publish the old HTML/Vite app.
