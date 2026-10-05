# Code signing policy

**Status (5 October 2026):** I have applied to the SignPath Foundation for free code signing
of the Windows app. **No release is signed by SignPath yet.** Until approval, the Windows
build is signed only with the maintainer's own certificate, so Windows SmartScreen shows
"Unknown publisher".

If the application is approved, signed releases will carry this attribution:

> Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org)

## Project

- Source (public): <https://github.com/mounsokdara/Khmer-Calendar>
- License: MIT
- Downloads: <https://github.com/mounsokdara/Khmer-Calendar/releases/latest>

## Roles

| Role | Person |
|---|---|
| Author, committer, reviewer, signing approver | Dara Sok Moun ([@mounsokdara](https://github.com/mounsokdara)), the sole maintainer |

The repository has no other collaborators with write access.

## What is signed

- The Windows app files built from this repository: `khmer_calendar.exe` and the DLLs of the
  app's plugins.
- Not signed by this process: Microsoft's Visual C++ runtime DLLs shipped in the zip (they
  already carry Microsoft's own signature and are never re-signed), and the Android, macOS
  and Linux builds, which use their own signing.

## How signing works

- Only the public GitHub Actions workflow in this repository
  ([`windows.yml`](../.github/workflows/windows.yml)) builds and submits files for signing.
  Nothing is signed from a personal computer.
- Every signing request is approved manually by the maintainer.
- Release builds are produced from the public source code; the workflow logs are public.

## Privacy

The app has no accounts, ads or analytics, and the maintainer receives no personal data
from it. The complete description, including the few outside services the app contacts, is
in the [Privacy Policy](../PRIVACY.md).

## Install and uninstall (Windows)

- **Install:** unzip `KhmerCalendar-windows.zip` anywhere and run `khmer_calendar.exe`.
  There is no installer and nothing is changed in the system on first run.
- **Start with Windows:** only if you turn this on inside the app. It adds the app to your
  Windows start-up list, and turning the setting off (or removing it in Windows Settings >
  Apps > Startup) takes it out again.
- **Uninstall:** delete the folder you unzipped. The app's saved settings live in your user
  profile's application data folder and can be deleted there as well.
