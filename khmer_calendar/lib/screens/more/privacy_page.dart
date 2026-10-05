import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../home_screen.dart';
import '../../i18n.dart';
import '../../location.dart';
import '../../permissions.dart';
import '../../reminders.dart';
import '../../store.dart';
import '../../custom_components/slide_snackbar.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';
import '../../widgets/sheet_kit.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.store});
  final AppStore store;

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  @override
  void initState() {
    super.initState();
    keepOnlyGranted(widget.store).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: t(lang, 'privacyTitle'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              PageIntro(text: t(lang, 'privacyIntro'), icon: Icons.verified_user_outlined),
              SectionLabel(t(lang, 'permSectionAlerts')),
              SegmentedGroup(
                children: [
                  SegmentedSwitch(
                    icon: Icons.notifications,
                    title: t(lang, 'permNotify'),
                    subtitle: t(lang, 'permNotifySub'),
                    value: store.notifyOn,
                    onChanged: (v) async {
                      if (!v) {
                        store.setNotifyOn(false);
                        await cancelAllReminders();
                        await syncHomeWidget(store);
                        return;
                      }
                      final ok = await requestNotifications(store);
                      if (!ok && context.mounted) {
                        await promptIfDenied(store, context: context, kind: 'notify', allowed: notificationsAllowed);
                        store.setNotifyOn(await notificationsAllowed());
                      }
                      if (context.mounted) showPermSnack(context, lang, 'notify', store.notifyOn);
                    },
                  ),
                ],
              ),
              SectionLabel(t(lang, 'permSectionSystem')),
              SegmentedGroup(
                children: [
                  SegmentedSwitch(
                    icon: Icons.sync,
                    title: t(lang, 'permBackground'),
                    subtitle: t(lang, 'permBackgroundSub'),
                    value: store.backgroundOn,
                    onChanged: (v) async {
                      if (!v) {
                        await stopBackground(store);
                        return;
                      }
                      if (kIsWeb) {
                        if (context.mounted) {
                          SlideSnackBar.show(context, message: t(lang, 'webBgBlock'), behavior: SnackBarBehavior.floating);
                        }
                        return;
                      }
                      final ok = await requestBackground(store, context: context);
                      if (!ok && context.mounted) {
                        await promptIfDenied(store, context: context, kind: 'background', allowed: backgroundAllowed);
                        store.setBackgroundOn(await backgroundAllowed());
                      }
                      if (context.mounted) showPermSnack(context, lang, 'background', store.backgroundOn);
                    },
                  ),
                  SegmentedSwitch(
                    icon: Icons.rocket_launch,
                    title: t(lang, 'autoLaunch'),
                    subtitle: t(lang, 'autoLaunchSub'),
                    value: store.autoLaunchOn,
                    onChanged: (v) async {
                      if (!v) {
                        await stopAutoLaunch(store);
                        return;
                      }
                      if (kIsWeb) {
                        if (context.mounted) {
                          SlideSnackBar.show(context, message: t(lang, 'webBgBlock'), behavior: SnackBarBehavior.floating);
                        }
                        return;
                      }
                      final ok = await requestAutoLaunch(store, context: context);
                      if (!ok && context.mounted && defaultTargetPlatform != TargetPlatform.android) {
                        await promptIfDenied(store, context: context, kind: 'auto', allowed: autoLaunchAllowed);
                        store.setAutoLaunchOn(await autoLaunchAllowed());
                      }
                      if (context.mounted) showPermSnack(context, lang, 'auto', store.autoLaunchOn);
                    },
                  ),
                ],
              ),
              SectionLabel(t(lang, 'permSectionLocation')),
              SegmentedGroup(
                children: [
                  SegmentedSwitch(
                    icon: Icons.location_on,
                    title: t(lang, 'permLocation'),
                    subtitle: t(lang, 'permLocationSub'),
                    value: store.locationOn,
                    onChanged: (v) async {
                      if (!v) {
                        store.setLocationOn(false);
                        return;
                      }
                      final r = await requestLocationPerm(store);
                      if (!store.locationOn && context.mounted) {
                        await promptIfDenied(store, context: context, kind: 'location', allowed: locationAllowed);
                        store.setLocationOn(await locationAllowed());
                      }
                      if (context.mounted) showGpsSnack(context, store.lang, store.locationOn ? r : GpsResult.denied);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
