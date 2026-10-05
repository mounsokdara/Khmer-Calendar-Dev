import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: t(lang, 'toolsTitle'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SegmentedGroup(
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.calculate),
                    title: t(lang, 'calcTitle'),
                    subtitle: t(lang, 'calcSub'),
                    onTap: () => context.push('/tools/datecalculator'),
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
