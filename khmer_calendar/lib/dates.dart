import 'calendar/chhankitek.dart';
import 'i18n.dart';

const calendarStartYear = 1;
const calendarEndYear = 9999;

int monthIndexOf(DateTime d) => (d.year - calendarStartYear) * 12 + (d.month - 1);

int monthCount() => (calendarEndYear - calendarStartYear + 1) * 12;

DateTime monthFromIndex(int i) => DateTime(calendarStartYear, 1 + i, 1);

int dayIndexOf(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(calendarStartYear, 1, 1)).inDays;

int dayCount() => DateTime.utc(calendarEndYear, 12, 31).difference(DateTime.utc(calendarStartYear, 1, 1)).inDays + 1;

DateTime dayFromIndex(int i) => DateTime(calendarStartYear, 1, 1 + i);

String isoOf(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime fromIso(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return DateTime(p[0], p.length > 1 ? p[1] : 1, p.length > 2 ? p[2] : 1);
}

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

List<DateTime> monthGrid(DateTime month, int weekStartsOn) {
  final first = startOfMonth(month);
  final firstDow = first.weekday % 7;
  final offset = (firstDow - weekStartsOn + 7) % 7;
  final start = addDays(first, -offset);
  return List.generate(42, (i) => addDays(start, i));
}

String todayIso() => isoOf(DateTime.now());

String formatTime12(String hhmm) {
  if (hhmm.isEmpty) return '';
  final p = hhmm.split(':').map(int.tryParse).toList();
  final h = p[0] ?? 0;
  final m = p.length > 1 ? (p[1] ?? 0) : 0;
  final am = h < 12;
  return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
}

String formatMonthTitle(DateTime d, Lang lang) {
  final name = monthsOf(lang)[d.month - 1];
  final y = d.year;
  return lang == Lang.en ? '$name $y' : '$name ${khmerNum(y)}';
}

String eventWhenLabel(String date, String? startTime, bool? allDay, Lang lang) {
  if (date.isEmpty) return '';
  final d = fromIso(date);
  final today = fromIso(todayIso());
  final diff = d.difference(today).inDays;
  final months = monthsOf(lang);
  final wdays = weekdaysFull(lang);
  final label = diff == 0
      ? t(lang, 'today')
      : (diff > 0 && diff < 7)
          ? wdays[d.weekday % 7]
          : '${d.day} ${months[d.month - 1]}';
  if (allDay == true || startTime == null || startTime.isEmpty) return label;
  return '$label, ${formatTime12(startTime)}';
}

String newId() {
  final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final r = (DateTime.now().microsecondsSinceEpoch % 100000).toRadixString(36);
  return 'evt-$now-$r';
}
