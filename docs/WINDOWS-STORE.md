# Windows: Microsoft Store package (removes the "Unknown publisher" warning)

The zip on GitHub is signed with our own certificate, so Windows SmartScreen shows
"Unknown publisher". Apps installed from the Microsoft Store are re-signed by Microsoft and
show no warning. The Windows workflow builds the Store package (`.msix`) automatically once
the Store identity is configured.

## One-time setup (needs a person, cannot be automated)

1. Register for free at <https://storedeveloper.microsoft.com> ("Get started for free") with a
   personal Microsoft account. Individual accounts need an ID + selfie check.
2. In Partner Center create a new app and reserve the name **Khmer Calendar**.
3. Open **Product > Product identity** and copy three values:

   | Partner Center field | Repository variable |
   |---|---|
   | Package/Identity/Name (e.g. `12345Name.KhmerCalendar`) | `MSIX_IDENTITY_NAME` |
   | Package/Identity/Publisher (e.g. `CN=XXXXXXXX-XXXX-...`) | `MSIX_PUBLISHER` |
   | Package/Properties/PublisherDisplayName | `MSIX_PUBLISHER_DISPLAY_NAME` |

4. Save them in GitHub: **Settings > Secrets and variables > Actions > Variables** (not
   secrets - these values are public inside the package anyway).

## Every release

1. Push to `main`. The **Windows** job also uploads an artifact named **windows-msix**
   (`KhmerCalendar.msix`). It is unsigned on purpose; the Store signs it.
2. Download it and upload it in Partner Center: **Packages** in a new submission.
3. Fill in the Store listing (description, screenshots, age rating, privacy policy URL).
4. Submit for certification. After approval the Store gives users updates automatically.

## Notes

- Store version numbers must end in `.0`. The MSIX version is the app version with `.0`
  added (`1.0.3+4` becomes `1.0.3.0`). Raise the app version for every new submission.
- The `.msix` is not published in the GitHub release: an unsigned MSIX cannot be installed
  by double-clicking, so it would only confuse people.
- Inside the Store package the app runs with the Store's package rules. Check anything that
  writes outside the app's own folders, for example the "start with Windows" feature
  (native autostart), before submitting.
