import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../haptics.dart';
import '../../i18n.dart';
import '../../custom_components/slide_snackbar.dart';
import '../../sounds.dart';
import '../../store.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';

String soundsAndVibrationTitle(Lang lang) => lang == Lang.km ? 'សំឡេង និងរំញ័រ' : 'Sounds & Vibration';
String soundsAndVibrationSub(Lang lang) => lang == Lang.km ? 'សំឡេង និងរំញ័រពេលរំកិលកង់ជ្រើសរើស' : 'Sounds and vibration when scrolling the wheel picker';
String hapticsTitle(Lang lang) => lang == Lang.km ? 'រំញ័រ' : 'Haptics';
String hapticsModeLabel(Lang lang, HapticsMode mode) {
  switch (mode) {
    case HapticsMode.system:
      return lang == Lang.km ? 'ប្រព័ន្ធ' : 'System';
    case HapticsMode.on:
      return lang == Lang.km ? 'បើក' : 'On';
    case HapticsMode.off:
      return lang == Lang.km ? 'បិទ' : 'Off';
  }
}

Future<String> wheelSoundLabel(AppStore store) async {
  if (store.wheelSound == wheelSoundCustom && store.wheelSoundName != null && store.wheelSoundName!.isNotEmpty) {
    return store.wheelSoundName!;
  }
  final config = await WheelConfig.load();
  return config.soundLabel(store.wheelSound, khmer: store.lang == Lang.km);
}

Future<void> showWheelSoundDialog(BuildContext context, AppStore store) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => FutureBuilder<WheelConfig>(
      future: WheelConfig.load(),
      builder: (ctx, configSnapshot) {
        if (!configSnapshot.hasData) {
          return AlertDialog(
            title: Text(t(store.lang, 'wheelPickerSound')),
            content: const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final config = configSnapshot.data!;
        return WatchStore(
          store: store,
          builder: (ctx, s) {
            final lang = s.lang;
            final cs = Theme.of(ctx).colorScheme;

            void choose(String id) {
              s.setWheelSound(id);
              AppSounds.instance.playWheel();
            }

            Future<void> pickCustom() async {
              final r = await pickCustomSound();
              switch (r.result) {
                case CustomPickResult.picked:
                  s.setWheelSound(wheelSoundCustom, customName: r.name);
                  AppSounds.instance.playWheel();
                case CustomPickResult.cancelled:
                  break;
                case CustomPickResult.tooLarge:
                  if (context.mounted) SlideSnackBar.show(context, message: t(lang, 'soundTooBig'), behavior: SnackBarBehavior.floating);
                case CustomPickResult.failed:
                  if (context.mounted) SlideSnackBar.show(context, message: t(lang, 'soundFailed'), behavior: SnackBarBehavior.floating);
              }
            }

            Widget option(String id, String title, {String? subtitle, IconData? trailing, VoidCallback? onTap}) {
              final on = s.wheelSound == id;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: on ? cs.primary : null),
                title: Text(title),
                subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: trailing == null ? null : Icon(trailing),
                onTap: onTap ?? () => choose(id),
              );
            }

            final options = <Widget>[];
            for (final item in config.soundOptions) {
              final id = item['id']?.toString();
              if (id == null || id.isEmpty) continue;
              if (id == wheelSoundCustom) {
                options.add(option(
                  id,
                  config.soundLabel(id, khmer: lang == Lang.km),
                  subtitle: s.wheelSound == id ? (s.wheelSoundName ?? t(lang, 'soundCustomDefault')) : null,
                  trailing: Icons.folder_open,
                  onTap: pickCustom,
                ));
              } else {
                options.add(option(id, config.soundLabel(id, khmer: lang == Lang.km)));
              }
            }

            return AlertDialog(
              title: Text(t(lang, 'wheelPickerSound')),
              contentPadding: const EdgeInsets.only(top: 12),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options,
                ),
              ),
              actions: equalDialogActions([
                FilledButton(onPressed: () => Navigator.pop(ctx), style: dialogBtnStyle(), child: dlgLabel(t(lang, 'ok'))),
              ]),
            );
          },
        );
      },
    ),
  );
}

Future<void> showHapticsDialog(BuildContext context, AppStore store) async {
  final lang = store.lang;
  final values = kIsWeb ? const [HapticsMode.on, HapticsMode.off] : HapticsMode.values;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final mode = Haptics.instance.mode;
        return AlertDialog(
          title: Text(hapticsTitle(lang)),
          contentPadding: const EdgeInsets.only(top: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(mode == value ? Icons.radio_button_checked : Icons.radio_button_off, color: mode == value ? Theme.of(ctx).colorScheme.primary : null),
                  title: Text(hapticsModeLabel(lang, value)),
                  onTap: () async {
                    await Haptics.instance.setMode(value);
                    setState(() {});
                  },
                ),
            ],
          ),
          actions: equalDialogActions([
            FilledButton(onPressed: () => Navigator.pop(ctx), style: dialogBtnStyle(), child: dlgLabel(t(lang, 'ok'))),
          ]),
        );
      },
    ),
  );
}

class SoundsPage extends StatelessWidget {
  const SoundsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: soundsAndVibrationTitle(lang),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SegmentedGroup(
                children: [
                  FutureBuilder<String>(
                    future: wheelSoundLabel(store),
                    builder: (context, snapshot) => SegmentedTile(
                      leading: const Icon(Icons.swap_vert),
                      title: t(lang, 'wheelPickerSound'),
                      subtitle: snapshot.data ?? store.wheelSound,
                      onTap: () => showWheelSoundDialog(context, store),
                    ),
                  ),
                  SegmentedTile(leading: const Icon(Icons.vibration), title: hapticsTitle(lang), subtitle: hapticsModeLabel(lang, Haptics.instance.mode), onTap: () => showHapticsDialog(context, store)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
