import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calendar/chhankitek.dart';
import '../calendar/observances.dart';
import '../custom_components/scroll_picker.dart';
import '../dates.dart';
import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/animal.dart';
import '../widgets/carousel_slider.dart';
import '../widgets/holiday_info.dart';
import '../widgets/overlay_page.dart';
import '../widgets/sil_mark.dart';
import '../widgets/swipe_delete.dart';
import '../widgets/task_sheet.dart';

Future<void> showWheelDatePicker(BuildContext context, AppStore store) async {
  final lang = store.lang;
  final initial = fromIso(store.selected);
  final months = monthsOf(lang);
  final years = [for (var y = calendarStartYear; y <= calendarEndYear; y++) '$y'];

  final picked = await showScrollPickerDialog(
    context,
    title: Text(lang == Lang.km ? 'ជ្រើសរើសកាលបរិច្ឆេទ' : 'Select date'),
    initialIndices: [
      initial.day - 1,
      initial.month - 1,
      initial.year.clamp(calendarStartYear, calendarEndYear) - calendarStartYear,
    ],
    columnsBuilder: (selected) {
      final maxDay = daysInMonth(DateTime(calendarStartYear + selected[2], selected[1] + 1, 1));
      return [
        ScrollPickerColumnSpec(
          labels: [for (var d = 1; d <= maxDay; d++) '$d'],
          flex: 2,
          matcher: ScrollPickerMatchers.number,
          keyboardType: TextInputType.number,
        ),
        ScrollPickerColumnSpec(
          labels: months,
          flex: 3,
          matcher: (q, _) => monthIndexFromQuery(q),
          maxTypedLength: 24,
        ),
        ScrollPickerColumnSpec(
          labels: years,
          flex: 2,
          matcher: ScrollPickerMatchers.number,
          keyboardType: TextInputType.number,
        ),
      ];
    },
    confirmLabel: lang == Lang.km ? 'រួចរាល់' : 'Done',
    cancelLabel: lang == Lang.km ? 'បោះបង់' : 'Cancel',
    width: 360,
  );
  if (picked == null) return;
  store.goToDate(isoOf(DateTime(calendarStartYear + picked[2], picked[1] + 1, picked[0] + 1)));
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.store});
  final AppStore store;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  String? _toast;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: widget.store,
      builder: (context, store) {
        final lang = store.lang;
        final selected = fromIso(store.selected);
        final today = todayIso();
        final isToday = store.selected == today;
        final L = lunarOf(selected);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      if (!isToday)
                        IconButton(
                          tooltip: t(lang, 'today'),
                          onPressed: () => store.goToDate(today),
                          icon: const Icon(Icons.today),
                        ),
                      if (L.isSilDay)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SilMark(size: 22),
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: lang == Lang.km ? 'ជ្រើសរើសកាលបរិច្ឆេទ' : 'Select date',
                        onPressed: () => showWheelDatePicker(context, store),
                        icon: const Icon(Icons.calendar_month),
                      ),
                      IconButton(
                        tooltip: t(lang, 'addTask'),
                        onPressed: () => showTaskSheet(context, store: store, date: store.selected),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CarouselSlider(
                    index: dayIndexOf(selected),
                    itemCount: dayCount(),
                    itemBuilder: (context, i) => _DayPanel(
                      day: dayFromIndex(i),
                      store: store,
                      onCopy: _copy,
                    ),
                    onIndexChanged: (i) => store.goToDate(isoOf(dayFromIndex(i))),
                  ),
                ),
                if (_toast != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Chip(label: Text(_toast!)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _toast = t(widget.store.lang, 'copied'));
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _toast = null);
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.store, required this.onCopy});
  final DateTime day;
  final AppStore store;
  final Future<void> Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    final lang = store.lang;
    final iso = isoOf(day);
    final lunar = lunarOf(day);
    final pair = animalPair(lunar);
    final items = observancesOn(iso, store.events);
    final hols = items.where((e) => e.kind == Kind.holiday).toList();
    final tasks = store.events.where((e) => e.date == iso).toList();
    final wdays = weekdaysFull(lang);
    final cs = Theme.of(context).colorScheme;
    final lunarText = lang == Lang.en ? lunarLabel(iso, lang) : lunar.lunarDateText;

    final infoChildren = <Widget>[
      Text(
        '${day.day} ${wdays[day.weekday % 7]}',
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lunarText, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onCopy(lunar.fullText),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(t(lang, 'copy')),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _animalCol(pair[0], lang),
              Text('X', style: TextStyle(color: cs.outline, fontWeight: FontWeight.w700)),
              _animalCol(pair[1], lang),
            ],
          ),
        ),
      ),
      for (final h in hols) ...[
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: (h.holidayType == HolidayType.public ? publicHolidayFill : otherHolidayFill).withValues(alpha: 0.22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showHolidayInfo(context, store, h),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                obsTitle(h, lang),
                style: TextStyle(
                  color: h.holidayType == HolidayType.public ? publicHolidayFill : otherHolidayFill,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ];

    final taskChildren = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: Text(
          lang == Lang.en ? 'Events & Tasks' : 'ព្រឹត្តិការណ៍ និងកិច្ចការ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (tasks.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Text(
            lang == Lang.en ? 'No events or tasks for this day.' : 'គ្មានព្រឹត្តិការណ៍ ឬកិច្ចការសម្រាប់ថ្ងៃនេះទេ។',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )
      else
        for (final e in tasks)
          swipeToDelete(
            context: context,
            key: 'day-${e.id}',
            confirm: true,
            lang: lang,
            onDelete: () => store.deleteEvent(e.id),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Checkbox(
                value: e.done ?? false,
                onChanged: (_) => store.toggleEventDone(e.id),
              ),
              title: Text(
                e.title,
                style: TextStyle(
                  decoration: e.done == true ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => showTaskSheet(context, store: store, editing: e),
            ),
          ),
    ];

    final taskPanel = Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: taskChildren,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 24),
                  children: infoChildren,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 24),
                  children: [taskPanel],
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ...infoChildren,
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...taskChildren,
            ],
          ],
        );
      },
    );
  }

  Widget _animalCol(String a, Lang lang) {
    return Column(
      children: [
        AnimalArt(animal: a, size: 48),
        const SizedBox(height: 6),
        Text(animalLabel(a, lang)),
      ],
    );
  }
}
