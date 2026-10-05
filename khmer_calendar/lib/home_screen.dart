import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calendar/chhankitek.dart';
import 'calendar/observances.dart';
import 'dates.dart';
import 'i18n.dart';
import 'net.dart';
import 'notify/kinds.dart';
import 'store.dart';
import 'weather.dart';
import 'wx_cache.dart';

const _ch = MethodChannel('khmer.permissions');
var _bound = false;
Timer? _widgetDebounce;
String _displaySig = '';
String _notifySig = '';
Map<String, dynamic>? _displayPayload;

bool get canPinHomeWidget {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android;
}

String _widgetDisplaySig(AppStore store) =>
    '${store.lang}|${store.weekStartsOn}|${store.events.map((e) => '${e.id}:${e.date}:${e.endDate}').join(',')}|${todayIso()}';

String _widgetNotifySig(AppStore store) =>
    '${store.notifyOn}|${store.notifyDaily}|${store.notifySil}|${store.notifyPublic}|${store.notifyOthers}|${store.notifyTasks}|${store.events.map((e) => '${e.id}:${e.date}:${e.endDate}:${e.startTime}:${e.reminderDate}:${e.reminderTime}:${e.done}:${e.title}').join(',')}';

void bindHomeWidget(AppStore store) {
  if (_bound) return;
  _bound = true;
  store.addListener(() {
    final sig = '${_widgetDisplaySig(store)}|${_widgetNotifySig(store)}';
    if (sig == '$_displaySig|$_notifySig') return;
    _widgetDebounce?.cancel();
    _widgetDebounce = Timer(const Duration(milliseconds: 450), () {
      syncHomeWidget(store);
    });
  });
  syncHomeWidget(store);
  syncWeatherWidget(store);
  _ch.setMethodCallHandler((call) async {
    if (call.method == 'open') applyWidgetLaunch(store, call.arguments);
  });
  _ch.invokeMethod<dynamic>('getLaunch').then((raw) => applyWidgetLaunch(store, raw)).catchError((_) {});
}

void applyWidgetLaunch(AppStore store, Object? raw) {
  if (raw is! Map) return;
  final tab = raw['tab']?.toString() ?? '';
  final date = raw['date']?.toString() ?? '';
  if (tab.isEmpty && date.isEmpty) return;
  store.applyLaunch(tab: tab, date: date);
}

Future<void> syncHomeWidget(AppStore store) async {
  if (!canPinHomeWidget) return;
  final displaySig = _widgetDisplaySig(store);
  final notifySig = _widgetNotifySig(store);
  if (displaySig == _displaySig && notifySig == _notifySig) return;
  if (displaySig != _displaySig || _displayPayload == null) {
    _displayPayload = _buildWidgetDisplay(store);
    _displaySig = displaySig;
  }
  _notifySig = notifySig;
  try {
    await _ch.invokeMethod<void>('updateWidget', {
      ..._displayPayload!,
      'notifyOn': store.notifyOn,
      'notifyDaily': store.notifyDaily,
      'notifySil': store.notifySil,
      'notifyPublic': store.notifyPublic,
      'notifyOthers': store.notifyOthers,
      'notifyReligious': store.notifyOthers,
      'notifyTasks': store.notifyTasks,
      'notify_items': jsonEncode(notifyItemsOf(store)),
    });
  } catch (_) {}
}

Map<String, String> _dayNotifyFields(DateTime d, Lang lang, List<CalendarEvent> events) {
  final di = isoOf(d);
  final lu = lunarOf(d);
  final hs = observancesOn(di, events).where((e) => e.kind == Kind.holiday);
  return {
    'lunar': lang == Lang.en ? lunarLabel(di, lang) : lu.lunarDateText,
    'holiday': hs.isEmpty ? '' : obsTitle(hs.first, lang),
    'weekday': weekdaysFull(lang)[d.weekday % 7],
    'gregorian': lang == Lang.en ? gregorianLabel(d, lang) : lu.gregorianDateText,
    'be': lang == Lang.en ? 'B.E. ${lu.buddhistEraYear}' : 'ព.ស. ${lu.buddhistEraYearKhmer}',
    'moon': silPhaseLabel(lu, lang),
    'sil': lu.isSilDay ? '1' : '',
    'hkind': hs.isEmpty
        ? ''
        : (hs.first.holidayType == HolidayType.public
            ? 'public'
            : hs.first.holidayType == HolidayType.religious
                ? 'religious'
                : hs.first.holidayType == HolidayType.international
                    ? 'international'
                    : 'traditional'),
  };
}

Map<String, dynamic> _buildWidgetDisplay(AppStore store) {
  final now = DateTime.now();
  final iso = todayIso();
  final lunar = lunarOf(now);
  final lang = store.lang;
  final lunarText = lang == Lang.en ? lunarLabel(iso, lang) : lunar.lunarDateText;
  final hols = observancesOn(iso, store.events).where((e) => e.kind == Kind.holiday);
  final holiday = hols.isEmpty ? '' : obsTitle(hols.first, lang);
  final publicHols = upcomingHolidays(HolidayType.public);
  final otherHols = upcomingOtherHolidays();
  final silDays = upcomingSilDates();
  final dayIsos = <String>{};
  for (var i = 0; i < 90; i++) {
    dayIsos.add(isoOf(DateTime(now.year, now.month, now.day + i)));
  }
  for (final h in publicHols) {
    dayIsos.add(h['d']!);
  }
  for (final h in otherHols) {
    dayIsos.add(h['d']!);
  }
  dayIsos.addAll(silDays);
  final days = <String, Map<String, String>>{};
  for (final di in dayIsos) {
    days[di] = _dayNotifyFields(fromIso(di), lang, store.events);
  }
  final marks = <String, String>{};
  final names = <String, String>{};
  void flag(String day, String f) {
    final cur = marks[day] ?? '';
    if (!cur.contains(f)) marks[day] = '$cur$f';
  }

  for (var y = now.year - 5; y <= now.year + 5; y++) {
    List<Holiday> yearHols;
    try {
      yearHols = holidaysOfYear(y);
    } catch (_) {
      continue;
    }
    for (final h in yearHols) {
      if (h.type == HolidayType.public) {
        flag(h.date, 'p');
      } else {
        flag(h.date, 'h');
      }
      names.putIfAbsent(h.date, () => lang == Lang.en ? h.nameEn : h.nameKm);
    }
    for (final o in [...kanBenOf(y), ...senKantongOf(y)]) {
      flag(o.date, 'h');
      names.putIfAbsent(o.date, () => obsTitle(o, lang));
    }
    var d = DateTime(y, 1, 1);
    final last = DateTime(y, 12, 31);
    while (!d.isAfter(last)) {
      if (lunarOf(d).isSilDay) flag(isoOf(d), 's');
      d = addDays(d, 1);
    }
  }
  for (final e in store.events) {
    if (e.date.isEmpty) continue;
    flag(e.date, 't');
    names.putIfAbsent(e.date, () => e.title);
  }

  return {
    'iso': iso,
    'day': '${now.day}',
    'weekday': weekdaysFull(lang)[now.weekday % 7],
    'lunar': lunarText,
    'holiday': holiday,
    'title': t(lang, 'appName'),
    'days': jsonEncode(days),
    'marks': jsonEncode(marks),
    'names': jsonEncode(names),
    'lang': lang == Lang.en ? 'en' : 'km',
    'weekStartsOn': store.weekStartsOn,
    'sil_days': silDays.join(','),
    'public_hols': jsonEncode(publicHols),
    'religious_hols': jsonEncode(otherHols),
  };
}

Future<void> syncWeatherWidget(AppStore store) async {
  if (!canPinHomeWidget) return;
  if (store.weatherCities.isEmpty) return;
  if (NetStatus.isOffline) return;
  final cache = <String, WeatherSnap>{};
  for (final id in store.weatherCities) {
    final city = cityById(id);
    if (city == null) continue;
    try {
      cache[id] = await fetchWeather(city);
    } catch (_) {}
  }
  await pushWeatherList(store, cache);
}

String encodeHourly(WeatherSnap snap) {
  final now = DateTime.now();
  return snap.hourly
      .where((h) {
        final t = DateTime.tryParse(h.time);
        return t != null && !t.isBefore(now.subtract(const Duration(minutes: 40)));
      })
      .take(6)
      .map((h) {
        final t = DateTime.tryParse(h.time);
        final hh = (t?.hour ?? 0).toString().padLeft(2, '0');
        return '$hh|${h.temp}|${h.code}';
      })
      .join(';');
}

Future<void> pushWeatherList(
  AppStore store,
  Map<String, WeatherSnap> cache, {
  String? selectId,
}) async {
  if (!canPinHomeWidget) return;
  final rows = <Map<String, String>>[];
  var index = 0;
  for (var i = 0; i < store.weatherCities.length; i++) {
    final id = store.weatherCities[i];
    final city = cityById(id);
    if (city == null) continue;
    final snap = cache[id];
    if (selectId != null && id == selectId) index = rows.length;
    final meta = snap == null ? null : wmoOf(snap.code);
    rows.add({
      'id': id,
      'name': city.name,
      'nameEn': city.nameEn,
      'temp': snap == null ? '' : '${snap.temp}',
      'high': snap == null ? '' : '${snap.high}',
      'low': snap == null ? '' : '${snap.low}',
      'label': meta?.km ?? '',
      'labelEn': meta?.en ?? '',
      'code': '${snap?.code ?? 2}',
      'daily': snap == null
          ? ''
          : snap.daily.take(7).map((d) => '${d.date}|${d.high}|${d.low}|${d.code}').join(';'),
      'hourly': snap == null ? '' : encodeHourly(snap),
      'clouds': '${snap?.clouds ?? 0}',
      'icon': '',
      'photo': '',
    });
  }
  if (rows.isEmpty) return;
  Future<void> send() async {
    final first = rows[index.clamp(0, rows.length - 1)];
    await _ch.invokeMethod<void>('updateWidget', {
      'wx_list': jsonEncode(rows),
      'wx_index': index,
      'wx_city': first['name'],
      'wx_city_en': first['nameEn'],
      'wx_temp': first['temp'],
      'wx_high': first['high'],
      'wx_low': first['low'],
      'wx_label': first['label'],
      'wx_label_en': first['labelEn'],
      'lang': store.lang == Lang.en ? 'en' : 'km',
    });
  }

  try {
    await send();
  } catch (_) {}
  for (final row in rows) {
    final id = row['id'] ?? '';
    final city = cityById(id);
    final snap = cache[id];
    if (city == null) continue;
    if (snap != null) {
      row['icon'] = await cacheUrl(wmoIconUrl(snap.code), 'wx_icon_$id.png') ?? '';
    }
    final remote = await cityPhotoUrl(city);
    if (remote != null) {
      row['photo'] = await cacheUrl(remote, 'wx_photo_$id.jpg') ?? '';
    }
  }
  try {
    await send();
  } catch (_) {}
}

Future<bool> pinHomeWidget([String kind = 'today']) async {
  if (!canPinHomeWidget) return false;
  try {
    return await _ch.invokeMethod<bool>('pinWidget', {'kind': kind}) ?? false;
  } catch (_) {
    return false;
  }
}
