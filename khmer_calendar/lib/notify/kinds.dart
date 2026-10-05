import 'package:flutter/foundation.dart';

import '../calendar/chhankitek.dart';
import '../calendar/observances.dart';
import '../dates.dart';
import '../i18n.dart';
import '../store.dart';

class ReminderShot {
  const ReminderShot(this.key, this.title, this.body, this.when, {this.channel = 'tasks', this.bodyOf});
  final String key;
  final String title;
  final String body;
  final DateTime when;
  final String channel;
  final String Function()? bodyOf;

  String resolveBody() => bodyOf == null ? body : bodyOf!();
}

abstract class ReminderKind {
  const ReminderKind();
  bool enabled(AppStore store);
  bool get nativeAndroid => false;
  List<ReminderShot> collect(AppStore store, DateTime now);
}

const reminderKinds = <ReminderKind>[
  DailyReminder(),
  SilReminder(),
  PublicHolidayReminder(),
  OtherHolidayReminder(),
  TaskReminder(),
];

String silPhaseLabel(LunarDay info, Lang lang) {
  if (lang == Lang.en) {
    final wax = info.moonStatus == 'កើត' ? 'waxing' : 'waning';
    return '${info.moonDay} $wax';
  }
  return '${info.moonDayKhmer}${info.moonStatus}';
}

String calendarDetail(DateTime day, Lang lang) {
  final info = lunarOf(day);
  final lunar = lang == Lang.en ? lunarLabel(isoOf(day), lang) : info.lunarDateText;
  final greg = lang == Lang.en ? gregorianLabel(day, lang) : info.gregorianDateText;
  return '$lunar\n$greg';
}

String dayNotifyBody(DateTime day, AppStore store) {
  final lang = store.lang;
  final iso = isoOf(day);
  final info = lunarOf(day);
  final lines = <String>[calendarDetail(day, lang)];
  if (info.isSilDay && store.notifySil) {
    lines.add('${t(lang, 'silDay')} (${silPhaseLabel(info, lang)})');
  }
  for (final h in holidaysOn(iso)) {
    final name = lang == Lang.en ? h.nameEn : h.nameKm;
    lines.add('${holidayTypeLabel(h.type, lang)}: $name');
  }
  final tasks = store.events.where((e) => e.date == iso && e.done != true).toList();
  if (tasks.isNotEmpty) {
    lines.add('${t(lang, 'tasks')}: ${tasks.map((e) => e.title).join(', ')}');
  }
  return lines.join('\n');
}

class DailyReminder extends ReminderKind {
  const DailyReminder();

  @override
  bool enabled(AppStore store) => store.notifyDaily;

  @override
  bool get nativeAndroid => true;

  @override
  List<ReminderShot> collect(AppStore store, DateTime now) {
    var when = DateTime(now.year, now.month, now.day, 7);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    final lang = store.lang;
    return [
      ReminderShot(
        'daily-${isoOf(when)}',
        t(lang, 'notifyTodayTitle'),
        dayNotifyBody(when, store),
        when,
        channel: 'daily',
      ),
    ];
  }
}

class SilReminder extends ReminderKind {
  const SilReminder();

  @override
  bool enabled(AppStore store) => store.notifySil;

  @override
  bool get nativeAndroid => true;

  @override
  List<ReminderShot> collect(AppStore store, DateTime now) {
    final lang = store.lang;
    final out = <ReminderShot>[];
    for (final iso in upcomingSilDates()) {
      final d = fromIso(iso);
      final when = DateTime(d.year, d.month, d.day, 7);
      if (!when.isAfter(now)) continue;
      out.add(
        ReminderShot(
          'sil-$iso',
          t(lang, 'silDay'),
          '',
          when,
          channel: 'sil',
          bodyOf: () {
            final info = lunarOf(d);
            final phase = silPhaseLabel(info, lang);
            return '${t(lang, 'silDay')} ($phase)\n${calendarDetail(d, lang)}';
          },
        ),
      );
    }
    return out;
  }
}

List<ReminderShot> _holidayShotsFrom(
  AppStore store,
  DateTime now,
  List<Map<String, String>> items,
  String channel,
) {
  final lang = store.lang;
  final out = <ReminderShot>[];
  for (final h in items) {
    final day = fromIso(h['d']!);
    final when = DateTime(day.year, day.month, day.day, 8);
    if (!when.isAfter(now)) continue;
    final name = lang == Lang.en ? h['en']! : h['km']!;
    final type = switch (h['type']) {
      'public' => HolidayType.public,
      'international' => HolidayType.international,
      'traditional' => HolidayType.traditional,
      _ => HolidayType.religious,
    };
    out.add(
      ReminderShot(
        'hol-${h['type']}-${h['d']}-${h['km']}',
        name,
        '',
        when,
        channel: channel,
        bodyOf: () => '${holidayTypeLabel(type, lang)}\n${calendarDetail(day, lang)}',
      ),
    );
  }
  return out;
}

class PublicHolidayReminder extends ReminderKind {
  const PublicHolidayReminder();

  @override
  bool enabled(AppStore store) => store.notifyPublic;

  @override
  bool get nativeAndroid => true;

  @override
  List<ReminderShot> collect(AppStore store, DateTime now) =>
      _holidayShotsFrom(store, now, upcomingHolidays(HolidayType.public), 'public');
}

class OtherHolidayReminder extends ReminderKind {
  const OtherHolidayReminder();

  @override
  bool enabled(AppStore store) => store.notifyOthers;

  @override
  bool get nativeAndroid => true;

  @override
  List<ReminderShot> collect(AppStore store, DateTime now) =>
      _holidayShotsFrom(store, now, upcomingOtherHolidays(), 'others');
}

class TaskReminder extends ReminderKind {
  const TaskReminder();

  @override
  bool enabled(AppStore store) => store.notifyTasks;

  @override
  bool get nativeAndroid => true;

  @override
  List<ReminderShot> collect(AppStore store, DateTime now) {
    final lang = store.lang;
    final out = <ReminderShot>[];
    for (final e in store.events) {
      if (e.done == true) continue;
      final reminder = (e.reminderDate ?? '').trim();
      if (reminder.isNotEmpty) {
        final shot = _taskShot(store, lang, e, fromIso(reminder), e.reminderTime, now);
        if (shot != null) out.add(shot);
        continue;
      }
      if (e.date.isEmpty) continue;
      final start = fromIso(e.date);
      var end = fromIso(e.endDate ?? e.date);
      if (end.isBefore(start)) end = start;
      for (var d = start; !d.isAfter(end); d = addDays(d, 1)) {
        final shot = _taskShot(store, lang, e, d, e.allDay == true ? null : e.startTime, now);
        if (shot != null) out.add(shot);
      }
    }
    return out;
  }
}

ReminderShot? _taskShot(
  AppStore store,
  Lang lang,
  CalendarEvent e,
  DateTime day,
  String? clock,
  DateTime now,
) {
  var hour = 8;
  var minute = 0;
  final tm = clock ?? '';
  if (tm.contains(':')) {
    final p = tm.split(':');
    hour = int.tryParse(p[0]) ?? 8;
    minute = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
  }
  final when = DateTime(day.year, day.month, day.day, hour, minute);
  if (!when.isAfter(now)) return null;
  final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  final notes = (e.notes ?? '').trim();
  return ReminderShot(
    'task-${e.id}-${isoOf(day)}-$time',
    e.title,
    notes,
    when,
    channel: 'tasks',
    bodyOf: () {
      final lines = <String>[t(lang, 'notifyTaskKind'), calendarDetail(day, lang), time];
      if (notes.isNotEmpty) lines.add(notes);
      return lines.join('\n');
    },
  );
}

bool get androidNativeAlarms => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

int notifyEndYear([DateTime? now]) {
  final n = now ?? DateTime.now();
  return n.year + 1;
}

String _horizonKey() => '${isoOf(DateTime.now())}|${notifyEndYear()}';

String? _silKey;
List<String>? _silCache;
String? _otherKey;
List<Map<String, String>>? _otherCache;
final _typeCache = <String, List<Map<String, String>>>{};

void warmNotifyLists() {
  Future<void>.delayed(const Duration(milliseconds: 300), () {
    upcomingSilDates();
    upcomingHolidays(HolidayType.public);
    upcomingOtherHolidays();
  });
}

List<String> upcomingSilDates({int? throughYear}) {
  final now = DateTime.now();
  final endYear = throughYear ?? notifyEndYear(now);
  final key = '${isoOf(DateTime(now.year, now.month, now.day))}|$endYear';
  if (_silCache != null && _silKey == key) return _silCache!;
  final last = DateTime(endYear, 12, 31);
  final out = <String>[];
  var d = DateTime(now.year, now.month, now.day);
  while (!d.isAfter(last)) {
    if (lunarOf(d).isSilDay) out.add(isoOf(d));
    d = addDays(d, 1);
  }
  _silKey = key;
  _silCache = out;
  return out;
}

List<Map<String, String>> upcomingHolidays(HolidayType type) {
  final key = '${_horizonKey()}|${type.name}';
  final hit = _typeCache[key];
  if (hit != null) return hit;
  final out = _upcomingHolidayMaps((h) => h.type == type);
  _typeCache[key] = out;
  return out;
}

List<Map<String, String>> upcomingOtherHolidays() {
  final key = _horizonKey();
  if (_otherCache != null && _otherKey == key) return _otherCache!;
  final out = _upcomingHolidayMaps(
    (h) =>
        h.type == HolidayType.religious ||
        h.type == HolidayType.traditional ||
        h.type == HolidayType.international,
  );
  final now = DateTime.now();
  final today = isoOf(DateTime(now.year, now.month, now.day));
  final seen = {for (final h in out) '${h['d']}-${h['km']}'};
  void addObs(Observance o) {
    if (o.date.compareTo(today) < 0) return;
    final k = '${o.date}-${o.title}';
    if (!seen.add(k)) return;
    out.add({'d': o.date, 'km': o.title, 'en': o.titleEn, 'type': 'traditional'});
  }
  for (var y = now.year; y <= notifyEndYear(now); y++) {
    kanBenOf(y).forEach(addObs);
    senKantongOf(y).forEach(addObs);
  }
  out.sort((a, b) => a['d']!.compareTo(b['d']!));
  _otherKey = key;
  _otherCache = out;
  return out;
}

List<Map<String, String>> _upcomingHolidayMaps(bool Function(Holiday h) keep) {
  final now = DateTime.now();
  final today = isoOf(DateTime(now.year, now.month, now.day));
  final out = <Map<String, String>>[];
  final seen = <String>{};
  for (var y = now.year; y <= notifyEndYear(now); y++) {
    List<Holiday> list;
    try {
      list = holidaysOfYear(y);
    } catch (_) {
      continue;
    }
    for (final h in list) {
      if (!keep(h)) continue;
      if (h.date.compareTo(today) < 0) continue;
      final key = '${h.date}-${h.nameKm}';
      if (!seen.add(key)) continue;
      out.add({'d': h.date, 'km': h.nameKm, 'en': h.nameEn, 'type': h.type.name});
    }
  }
  return out;
}

List<Map<String, dynamic>> notifyItemsOf(AppStore store) {
  if (!store.notifyOn) return [];
  final now = DateTime.now();
  final out = <Map<String, dynamic>>[];
  for (final kind in reminderKinds) {
    if (kind is DailyReminder) continue;
    if (!kind.enabled(store)) continue;
    for (final shot in kind.collect(store, now)) {
      final row = <String, dynamic>{
        'd': isoOf(DateTime(shot.when.year, shot.when.month, shot.when.day)),
        'h': shot.when.hour,
        'm': shot.when.minute,
        'ch': shot.channel,
        'title': shot.title,
      };
      if (shot.body.isNotEmpty) row['notes'] = shot.body;
      out.add(row);
    }
  }
  return out;
}

