import '../dates.dart';
import '../i18n.dart';
import '../store.dart';
import 'chhankitek.dart';

enum Kind { holiday, sil, event }

class Observance {
  const Observance({
    required this.id,
    required this.date,
    required this.title,
    required this.titleEn,
    this.subtitle,
    this.subtitleEn,
    required this.kind,
    this.holidayType,
    this.eventId,
  });

  final String id;
  final String date;
  final String title;
  final String titleEn;
  final String? subtitle;
  final String? subtitleEn;
  final Kind kind;
  final HolidayType? holidayType;
  final String? eventId;
}

final _kanCache = <int, List<Observance>>{};
final _ktCache = <int, List<Observance>>{};

List<DateTime> _eachDay(DateTime start, DateTime end) {
  final out = <DateTime>[];
  var d = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!d.isAfter(last)) {
    out.add(d);
    d = addDays(d, 1);
  }
  return out;
}

DateTime? _pchumBenDate(int year) {
  final list = holidaysOfYear(year);
  final h = list.cast<Holiday?>().firstWhere(
        (x) => x!.nameKm == 'ភ្ជុំបិណ្ឌ' && x.type == HolidayType.religious,
        orElse: () => list.cast<Holiday?>().firstWhere(
              (x) => x!.nameEn == 'Pchum Ben' && x.type == HolidayType.religious,
              orElse: () => null,
            ),
      );
  return h == null ? null : fromIso(h.date);
}

List<Observance> kanBenOf(int year) {
  final hit = _kanCache[year];
  if (hit != null) return hit;
  final pb = _pchumBenDate(year);
  if (pb == null) {
    _kanCache[year] = [];
    return [];
  }
  final list = <Observance>[];
  for (var i = 1; i <= 14; i += 1) {
    final iso = isoOf(addDays(pb, -(15 - i)));
    list.add(Observance(
      id: 'kanben-$iso',
      date: iso,
      title: 'បិណ្ឌ ${khmerNum(i)}',
      titleEn: 'Kan Ben $i',
      subtitle: 'ពិធីបុណ្យភ្ជុំបិណ្ឌ',
      subtitleEn: 'Pchum Ben',
      kind: Kind.holiday,
      holidayType: HolidayType.traditional,
    ));
  }
  _kanCache[year] = list;
  return list;
}

List<Observance> senKantongOf(int year) {
  final hit = _ktCache[year];
  if (hit != null) return hit;
  final list = <Observance>[];
  for (final d in _eachDay(DateTime(year, 8, 1), DateTime(year, 11, 30))) {
    final iso = isoOf(d);
    final L = lunarOf(d);
    if (L.khmerMonth == 'ភទ្របទ' && L.moonDay == 14 && L.moonStatus == 'កើត') {
      list.add(Observance(
        id: 'kantong-$iso',
        date: iso,
        title: 'សែនកន្ទោងទឹក',
        titleEn: 'Sen Kantong',
        subtitle: 'ពិធីបុណ្យភ្ជុំបិណ្ឌ',
        subtitleEn: 'Pchum Ben',
        kind: Kind.holiday,
        holidayType: HolidayType.traditional,
      ));
    }
  }
  _ktCache[year] = list;
  return list;
}

List<Observance> _eventObservances(List<CalendarEvent> events) {
  final out = <Observance>[];
  for (final n in events) {
    if (n.date.isEmpty) {
      out.add(Observance(
        id: 'evt-${n.id}',
        date: '',
        title: n.title,
        titleEn: n.title,
        subtitle: n.startTime != null && n.allDay != true ? n.startTime : '',
        subtitleEn: n.startTime != null && n.allDay != true ? n.startTime : '',
        kind: Kind.event,
        eventId: n.id,
      ));
      continue;
    }
    final start = fromIso(n.date);
    var end = fromIso(n.endDate ?? n.date);
    if (end.isBefore(start)) end = start;
    final sub = n.allDay == true
        ? t(Lang.km, 'allDay')
        : (n.startTime != null ? '${n.startTime}${n.endTime != null ? '-${n.endTime}' : ''}' : '');
    final subEn = n.allDay == true
        ? t(Lang.en, 'allDay')
        : (n.startTime != null ? '${n.startTime}${n.endTime != null ? '-${n.endTime}' : ''}' : '');
    for (final d in _eachDay(start, end)) {
      final iso = isoOf(d);
      out.add(Observance(
        id: 'evt-${n.id}-$iso',
        date: iso,
        title: n.title,
        titleEn: n.title,
        subtitle: sub,
        subtitleEn: subEn,
        kind: Kind.event,
        eventId: n.id,
      ));
    }
  }
  return out;
}

int _kindRank(Kind k) => k == Kind.holiday ? 0 : k == Kind.sil ? 1 : 2;

String holidayTypeLabel(HolidayType type, Lang lang) {
  if (type == HolidayType.public) return t(lang, 'holidayPublic');
  if (type == HolidayType.religious) return t(lang, 'holidayReligious');
  if (type == HolidayType.international) return t(lang, 'holidayInternational');
  return t(lang, 'holidayTraditional');
}

List<Observance> rangeObservances(DateTime start, DateTime end, List<CalendarEvent> events) {
  final days = _eachDay(start, end);
  final years = days.map((d) => d.year).toSet();
  final extra = <String, List<Observance>>{};
  for (final y in years) {
    for (final o in [...kanBenOf(y), ...senKantongOf(y)]) {
      extra.putIfAbsent(o.date, () => []).add(o);
    }
  }
  final out = <Observance>[];
  final seen = <String>{};
  for (final d in days) {
    final iso = isoOf(d);
    final info = dayInfo(iso);
    final hols = (info.holidays != null && info.holidays!.isNotEmpty) ? info.holidays! : holidaysOn(iso);
    for (final h in hols) {
      final id = 'hol-$iso-${h.nameKm}';
      if (seen.contains(id)) continue;
      seen.add(id);
      out.add(Observance(
        id: id,
        date: iso,
        title: h.nameKm,
        titleEn: h.nameEn.isEmpty ? h.nameKm : h.nameEn,
        subtitle: holidayTypeLabel(h.type, Lang.km),
        subtitleEn: holidayTypeLabel(h.type, Lang.en),
        kind: Kind.holiday,
        holidayType: h.type,
      ));
    }
    out.addAll(extra[iso] ?? const []);
    if (info.isSilDay) {
      final wax = info.moonStatus == 'កើត' ? 'waxing' : 'waning';
      out.add(Observance(
        id: 'sil-$iso',
        date: iso,
        title: 'ថ្ងៃសីល',
        titleEn: 'Silas day',
        subtitle: '${info.moonDayKhmer}${info.moonStatus} ខែ${info.khmerMonth}',
        subtitleEn: '${info.moonDay} $wax ${monthEn[info.khmerMonth] ?? info.khmerMonth}',
        kind: Kind.sil,
      ));
    }
  }
  final startIso = isoOf(start);
  final endIso = isoOf(end);
  out.addAll(_eventObservances(events).where((e) => e.date.isNotEmpty && e.date.compareTo(startIso) >= 0 && e.date.compareTo(endIso) <= 0));
  out.sort((a, b) {
    final d = a.date.compareTo(b.date);
    if (d != 0) return d;
    final k = _kindRank(a.kind) - _kindRank(b.kind);
    if (k != 0) return k;
    return a.title.compareTo(b.title);
  });
  return out;
}

List<Observance> yearObservances(int year, [List<CalendarEvent> events = const []]) =>
    rangeObservances(DateTime(year, 1, 1), DateTime(year, 12, 31), events);

List<Observance> monthObservances(DateTime month, List<CalendarEvent> events) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  return rangeObservances(start, end, events);
}

List<Observance> observancesOn(String iso, List<CalendarEvent> events) {
  final d = fromIso(iso);
  return rangeObservances(d, d, events);
}

String obsTitle(Observance o, Lang lang) => lang == Lang.en && o.titleEn.isNotEmpty ? o.titleEn : o.title;

String obsSub(Observance o, Lang lang) {
  final en = o.subtitleEn ?? '';
  final km = o.subtitle ?? '';
  if (lang == Lang.en && en.isNotEmpty) return en;
  return km;
}

String gregorianLabel(DateTime d, Lang lang) {
  final months = monthsOf(lang);
  return lang == Lang.en
      ? '${d.day} ${months[d.month - 1]} ${d.year}'
      : 'ថ្ងៃទី${d.day} ខែ${months[d.month - 1]} ឆ្នាំ${d.year}';
}

String lunarLabel(String iso, Lang lang) {
  final n = lunarOf(fromIso(iso));
  const wdayEn = {
    'អាទិត្យ': 'Sunday',
    'ចន្ទ': 'Monday',
    'អង្គារ': 'Tuesday',
    'ពុធ': 'Wednesday',
    'ព្រហស្បតិ៍': 'Thursday',
    'សុក្រ': 'Friday',
    'សៅរ៍': 'Saturday',
  };
  final wax = n.moonStatus == 'កើត' ? 'waxing' : 'waning';
  return lang == Lang.en
      ? '${wdayEn[n.dayOfWeek] ?? n.dayOfWeek} ${n.moonDay} $wax ${monthEn[n.khmerMonth] ?? n.khmerMonth} · B.E. ${n.buddhistEraYear}'
      : 'ថ្ងៃ${n.dayOfWeek} ${n.moonDayKhmer}${n.moonStatus} ខែ${n.khmerMonth} ព.ស. ${n.buddhistEraYearKhmer}';
}

String colorKind(Observance o) {
  if (o.kind == Kind.sil) return 'sil';
  if (o.kind == Kind.event) return 'event';
  if (o.holidayType == HolidayType.public) return 'sunday';
  return 'holiday';
}

bool isPublicHoliday(String iso) => holidaysOn(iso).any((h) => h.type == HolidayType.public);

bool isObservanceHoliday(String iso) {
  if (holidaysOn(iso).any(
    (h) =>
        h.type == HolidayType.religious ||
        h.type == HolidayType.traditional ||
        h.type == HolidayType.international,
  )) {
    return true;
  }
  final y = fromIso(iso).year;
  return kanBenOf(y).any((o) => o.date == iso) || senKantongOf(y).any((o) => o.date == iso);
}

String dayTone(String iso, bool inMonth) {
  if (!inMonth) return 'muted';
  final d = fromIso(iso);
  if (isPublicHoliday(iso)) return 'sunday';
  if (isObservanceHoliday(iso)) return 'holiday';
  if (d.weekday % 7 == 0) return 'sunday';
  return 'default';
}

bool hasDayMark(String iso, List<CalendarEvent> events) => events.any((e) => e.date == iso);
