# Privacy Policy

**Khmer Calendar** · Effective 5 October 2026

Khmer Calendar is a free, open-source Khmer lunar calendar for Android, Windows, macOS,
Linux and the web, made by Dara Sok Moun ("I", "me"). This policy explains what the app
does with your information. The short version: **I do not run any server for this app, I do
not have accounts, ads or analytics, and I do not collect or sell your personal data.**

## 1. What stays on your device

The app stores the following only on your own device (in the app's local storage, or in your
browser's local storage for the web version):

- Your settings: language, theme and colors, week start, calendar view, notification choices.
- Your own events, tasks and reminders (title, date, time) and the reminder times you set.
- The list of cities you chose for the weather screen.
- A custom sound file you pick for the date wheel (it is used on your device and is never uploaded).

None of this is sent to me or to anyone else. Uninstalling the app, or clearing the app's
data (or the site data in your browser), removes it. On Android, the system's own backup
feature may include app data if you have device backup turned on; that is controlled by
your device and Google account settings, not by this app.

## 2. Permissions the app asks for

| Permission (Android) | Why |
|---|---|
| Internet | Weather, city photos and the "check for updates" button (see section 3). |
| Approximate location | Only when you tap "use my location", to find the nearest city on the app's built-in list. See below. |
| Notifications | Reminders, holidays and the daily notice you turn on. |
| Run at start-up | Re-schedules your reminders after the phone restarts. |
| Exact alarms | Shows reminders at the exact time you set. |
| Vibrate / keep awake | Vibration with notifications and sound. |

**Location.** Your location is read only after you grant permission and ask for it. It is
used on your device to pick the closest city from a list built into the app. The app saves
only that city's name, **not your coordinates**, and your coordinates are **not sent
anywhere**. The Android app requests approximate (coarse) location only, never precise
location. You can turn the permission off at any time in your system settings.

On Windows, "start with Windows" is off unless you turn it on; when on, the app adds
itself to your Windows start-up list, which you can remove in Windows Settings.

## 3. Network requests

The app contacts the services below. Like any internet request, they can see your IP
address and basic technical details such as the app's user agent. I do not receive any of
this; it goes straight from your device to the service.

| Service | When | What is sent |
|---|---|---|
| **Open-Meteo** (api.open-meteo.com) | Weather screen and weather widget | The latitude and longitude of a city **from the app's built-in list** that you added (not your own location). |
| **Wikimedia Commons and Wikipedia** | Showing a photo for a city | The city's name and its built-in coordinates, as a search. |
| **OpenWeather** (openweathermap.org) | Weather icons | A request for an icon image (no personal data). |
| **GitHub** (api.github.com) | Only when you tap the update check in About | A request for the latest release number of this project. |

Their own privacy policies apply to what they do with requests:
[Open-Meteo](https://open-meteo.com/en/terms),
[Wikimedia](https://foundation.wikimedia.org/wiki/Policy:Privacy_policy),
[OpenWeather](https://openweather.co.uk/privacy-policy),
[GitHub](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).

## 4. What the app does not do

- No accounts, sign-in or profiles.
- No advertising, no ad or tracking identifiers.
- No analytics, usage tracking or crash-reporting services.
- No sale or sharing of personal data.
- No push-notification server: reminders are scheduled on your device.

## 5. Web version and downloads

- **Website** (khmercalendar.pages.dev): hosted on Cloudflare Pages, which, like any host,
  may keep standard server logs (such as IP address and requested page). The web app saves
  your settings in your browser's local storage, and it may load Flutter engine files from
  Google's content delivery network.
- **Microsoft Store:** if you install from the Store, Microsoft collects its own store and
  diagnostic data under Microsoft's privacy statement. This app does not receive it.
- **GitHub Releases:** downloads are served by GitHub under GitHub's policies.

## 6. Children

The app is not directed at children and collects no personal information from anyone,
including children.

## 7. Your choices

Because the app keeps your data on your device, you control it directly: change or delete
items inside the app, turn permissions off in system settings, or uninstall the app.

## 8. Changes to this policy

If the app starts to do something that changes this policy (for example, adds a new
service), this page will be updated before the release, and the date above will change. The
history of every change is public in this repository.

## 9. Contact

Questions or concerns: open an issue at
<https://github.com/mounsokdara/Khmer-Calendar/issues>.
