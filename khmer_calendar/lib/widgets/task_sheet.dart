import 'package:flutter/material.dart';

import '../dates.dart';
import '../i18n.dart';
import '../store.dart';
import 'dialog_actions.dart';

Future<void> showTaskSheet(
  BuildContext context, {
  required AppStore store,
  CalendarEvent? editing,
  String? date,
}) async {
  final lang = store.lang;
  final title = TextEditingController(text: editing != null ? [editing.title, if ((editing.notes ?? '').isNotEmpty) editing.notes].join('\n') : '');
  var day = editing?.date ?? date ?? store.selected;
  var allDay = editing?.allDay ?? true;
  var start = editing?.startTime ?? '09:00';
  var reminderDate = editing?.reminderDate ?? '';
  var reminderTime = editing?.reminderTime ?? '';
  final done = editing?.done ?? false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 8),
        child: StatefulBuilder(
          builder: (ctx, setSt) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(editing == null ? t(lang, 'createTask') : t(lang, 'task'), style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: t(lang, 'titlePlaceholder')),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t(lang, 'today')),
                    subtitle: Text(day),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fromIso(day),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSt(() => day = isoOf(picked));
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t(lang, 'allDay')),
                    value: allDay,
                    onChanged: (v) => setSt(() => allDay = v),
                  ),
                  if (!allDay)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t(lang, 'time')),
                      subtitle: Text(formatTime12(start)),
                      onTap: () async {
                        final tod = TimeOfDay(
                          hour: int.tryParse(start.split(':').first) ?? 9,
                          minute: int.tryParse(start.split(':').last) ?? 0,
                        );
                        final picked = await showTimePicker(context: ctx, initialTime: tod);
                        if (picked != null) {
                          setSt(() => start =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                        }
                      },
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t(lang, 'addReminder')),
                    subtitle: reminderDate.isEmpty ? null : Text('$reminderDate ${reminderTime.isEmpty ? '' : formatTime12(reminderTime)}'),
                    trailing: reminderDate.isEmpty ? null : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setSt(() {
                        reminderDate = '';
                        reminderTime = '';
                      }),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fromIso(reminderDate.isEmpty ? day : reminderDate),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked == null) return;
                      if (!ctx.mounted) return;
                      final tm = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                      if (!ctx.mounted) return;
                      setSt(() {
                        reminderDate = isoOf(picked);
                        if (tm != null) {
                          reminderTime =
                              '${tm.hour.toString().padLeft(2, '0')}:${tm.minute.toString().padLeft(2, '0')}';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final raw = title.text.replaceAll('\r\n', '\n').trim();
                      if (raw.isEmpty) return;
                      final n = raw.indexOf('\n');
                      final ttl = n == -1 ? raw : raw.substring(0, n).trim();
                      final notes = n == -1 ? '' : raw.substring(n + 1);
                      final ev = CalendarEvent(
                        id: editing?.id ?? newId(),
                        title: ttl,
                        notes: notes.isEmpty ? null : notes,
                        date: day,
                        allDay: allDay,
                        startTime: allDay ? null : start,
                        reminderDate: reminderDate,
                        reminderTime: reminderTime,
                        done: done,
                      );
                      if (editing == null) {
                        store.addEvent(ev);
                      } else {
                        store.updateEvent(ev);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(t(lang, 'save')),
                  ),
                  if (editing != null)
                    TextButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (d) => AlertDialog(
                            title: Text(t(lang, 'confirmDelete')),
                            actions: equalDialogActions([
                              OutlinedButton(
                                onPressed: () => Navigator.pop(d, false),
                                style: dialogBtnStyle(),
                                child: dlgLabel(t(lang, 'dontDelete')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(d, true),
                                style: dialogBtnStyle(
                                  background: Theme.of(d).colorScheme.error,
                                  foreground: Theme.of(d).colorScheme.onError,
                                ),
                                child: dlgLabel(t(lang, 'delete')),
                              ),
                            ]),
                          ),
                        );
                        if (ok == true) {
                          store.deleteEvent(editing.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: Text(t(lang, 'delete')),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
