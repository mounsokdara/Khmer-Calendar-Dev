import 'package:flutter/material.dart';

import '../calendar/observances.dart';
import '../dates.dart';
import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/holiday_info.dart';
import '../widgets/obs_row.dart';
import '../widgets/overlay_page.dart';
import '../widgets/segmented_list.dart';
import '../widgets/swipe_delete.dart';
import '../widgets/task_sheet.dart';
import '../widgets/wheel_picker.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) => _EventsBody(store: store),
    );
  }
}

class _EventsBody extends StatelessWidget {
  const _EventsBody({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final lang = store.lang;
    final year = fromIso(store.cursor).year;
    final pane = store.lastEventsPane;
    final hols = yearObservances(year, []).where((e) => e.kind == Kind.holiday).toList();
    final groups = <String, List<Observance>>{};
    for (final h in hols) {
      groups.putIfAbsent(h.date.substring(0, 7), () => []).add(h);
    }
    final today = todayIso();
    final current = store.events.where((e) => e.done != true && (e.date.isEmpty || e.date.compareTo(today) >= 0)).toList();
    final overdue = store.events.where((e) => e.done != true && e.date.isNotEmpty && e.date.compareTo(today) < 0).toList();
    final done = store.events.where((e) => e.done == true).toList();
    final wide = MediaQuery.sizeOf(context).width >= mediumBreak;
    final xl = MediaQuery.sizeOf(context).width >= xlBreak;

    final segmented = SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'holidays', label: Text(t(lang, 'holidaysTab'))),
        ButtonSegment(value: 'tasks', label: Text(t(lang, 'tasksTab'))),
      ],
      selected: {pane},
      onSelectionChanged: (s) => store.setLastEventsPane(s.first),
    );

    final yearOrAdd = pane == 'holidays'
        ? TextButton.icon(
            onPressed: () async {
              final pick = await showYearWheel(context, lang: lang, year: year);
              if (pick != null) {
                final cur = fromIso(store.cursor);
                store.setCursor(isoOf(DateTime(pick, cur.month, 1)));
              }
            },
            icon: const Icon(Icons.expand_more),
            label: Text('$year'),
          )
        : IconButton(
            tooltip: t(lang, 'addTask'),
            onPressed: () => showTaskSheet(context, store: store),
            icon: const Icon(Icons.add),
          );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: wide
              ? Row(
                  children: [
                    Text(t(lang, 'events'), style: Theme.of(context).textTheme.headlineSmall),
                    Expanded(child: Center(child: segmented)),
                    yearOrAdd,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(t(lang, 'events'), style: Theme.of(context).textTheme.headlineSmall)),
                        yearOrAdd,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(child: segmented),
                  ],
                ),
        ),
        Expanded(
          child: pane == 'holidays'
              ? (groups.isEmpty
                  ? Center(child: Text(t(lang, 'noHolidaysYear')))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        if (xl)
                          _holidayGrid(context, groups, 3)
                        else if (wide)
                          _holidayGrid(context, groups, 2)
                        else
                          for (final e in groups.entries) _holidayGroup(context, e.key, e.value),
                      ],
                    ))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _taskGroup(context, t(lang, 'overdue'), overdue, true),
                    _taskGroup(context, t(lang, 'currentTasks'), current, false),
                    _taskGroup(context, t(lang, 'completed'), done, false),
                    if (store.events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(t(lang, 'noTasks')),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _holidayGrid(BuildContext context, Map<String, List<Observance>> groups, int cols) {
    final entries = groups.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (var r = 0; r < (entries.length / cols).ceil(); r++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < cols; c++)
                  Expanded(
                    child: r * cols + c < entries.length
                        ? _holidayGroup(context, entries[r * cols + c].key, entries[r * cols + c].value)
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _holidayGroup(BuildContext context, String key, List<Observance> list) {
    final lang = store.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
          child: Text(
            formatMonthTitle(fromIso('$key-01'), lang),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        for (final item in list)
          ObsRow(
            item: item,
            lang: lang,
            showWeekday: true,
            padDay: true,
            onTap: () {
              store.goToDate(item.date);
              showHolidayInfo(context, store, item);
            },
          ),
      ],
    );
  }

  Widget _taskGroup(BuildContext context, String title, List<CalendarEvent> list, bool overdue) {
    if (list.isEmpty) return const SizedBox.shrink();
    final lang = store.lang;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title, color: overdue ? cs.error : cs.primary),
        for (final e in list)
          swipeToDelete(
            context: context,
            key: e.id,
            confirm: true,
            lang: lang,
            onDelete: () => store.deleteEvent(e.id),
            child: ListTile(
              leading: Checkbox(value: e.done ?? false, onChanged: (_) => store.toggleEventDone(e.id)),
              title: Text(e.title, style: TextStyle(decoration: e.done == true ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
              subtitle: Text(eventWhenLabel(e.date, e.startTime, e.allDay, lang)),
              onTap: () => showTaskSheet(context, store: store, editing: e),
            ),
          ),
      ],
    );
  }
}
