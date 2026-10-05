import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../../weather.dart';
import '../../widgets/sheet_kit.dart';


Future<void> showAddCitySheet(
  BuildContext context, {
  required AppStore store,
  required VoidCallback onAdded,
}) async {
  final lang = store.lang;
  final q = TextEditingController();
  await showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return StatefulBuilder(
        builder: (ctx, setSt) {
          final query = q.text.toLowerCase();
          final list = cities.where((c) {
            if (store.weatherCities.contains(c.id)) return false;
            if (query.isEmpty) return true;
            return c.name.contains(q.text) || c.nameEn.toLowerCase().contains(query);
          }).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: LayoutBuilder(
              builder: (ctx, box) => SizedBox(
                height: box.maxHeight < 520 ? box.maxHeight : 520,
                child: Column(
                  children: [
                    SheetHeader(
                      icon: Icons.add_location_alt_outlined,
                      title: t(lang, 'addCity'),
                      subtitle: t(lang, 'sheetAddCitySub'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SearchBar(
                        controller: q,
                        hintText: t(lang, 'findCity'),
                        leading: const Icon(Icons.search),
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                        onChanged: (_) => setSt(() {}),
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_off_outlined, size: 40, color: cs.outline),
                                  const SizedBox(height: 8),
                                  Text(t(lang, 'sheetNoCity'), style: Theme.of(ctx).textTheme.titleMedium),
                                  Text(t(lang, 'sheetNoCitySub'), style: TextStyle(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                for (final c in list)
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                    leading: CircleAvatar(
                                      backgroundColor: cs.secondaryContainer,
                                      foregroundColor: cs.onSecondaryContainer,
                                      child: const Icon(Icons.location_city, size: 20),
                                    ),
                                    title: Text(lang == Lang.en ? c.nameEn : c.name),
                                    subtitle: Text(lang == Lang.en ? c.name : c.nameEn),
                                    trailing: Icon(Icons.add_circle_outline, color: cs.primary),
                                    onTap: () {
                                      store.addWeatherCity(c.id);
                                      Navigator.pop(ctx);
                                      onAdded();
                                    },
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
