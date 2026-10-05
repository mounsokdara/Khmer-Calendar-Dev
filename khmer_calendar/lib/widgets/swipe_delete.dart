import 'package:flutter/material.dart';

import '../i18n.dart';
import 'dialog_actions.dart';

Widget swipeToDelete({
  required BuildContext context,
  required String key,
  required Widget child,
  required VoidCallback onDelete,
  bool confirm = false,
  Lang lang = Lang.km,
}) {
  final radius = BorderRadius.circular(16);
  return ClipRRect(
    borderRadius: radius,
    child: Dismissible(
      key: ValueKey(key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: confirm
          ? (_) async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t(lang, 'confirmDelete')),
                  actions: equalDialogActions([
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: dialogBtnStyle(),
                      child: dlgLabel(t(lang, 'dontDelete')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: dialogBtnStyle(
                        background: Theme.of(ctx).colorScheme.error,
                        foreground: Theme.of(ctx).colorScheme.onError,
                      ),
                      child: dlgLabel(t(lang, 'delete')),
                    ),
                  ]),
                ),
              );
              return ok ?? false;
            }
          : null,
      onDismissed: (_) => onDelete(),
      child: child,
    ),
  );
}
