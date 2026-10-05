import 'package:flutter/material.dart';

import '../home_screen.dart';
import '../i18n.dart';
import '../location.dart';
import '../net.dart';
import '../store.dart';
import '../theme.dart';
import '../weather.dart';
import '../widgets/overlay_page.dart';
import '../widgets/swipe_delete.dart';
import 'weather/add_city_sheet.dart';
import 'weather/city_card.dart';
import 'weather/city_detail_sheet.dart';
import 'weather/weather_offline.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, required this.store});
  final AppStore store;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _cache = <String, WeatherSnap>{};
  final _err = <String, String>{};
  bool _loading = false;
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    NetStatus.online.addListener(_onStore);
    _refresh();
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    NetStatus.online.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (NetStatus.isOffline) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    for (final id in widget.store.weatherCities) {
      final city = cityById(id);
      if (city == null) continue;
      try {
        _cache[id] = await fetchWeather(city);
        _err.remove(id);
      } catch (_) {
        _err[id] = 'fail';
      }
    }
    await pushWeatherList(widget.store, _cache);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: widget.store,
      builder: (context, store) {
        final lang = store.lang;
        if (NetStatus.isOffline) {
          return WeatherOffline(
            lang: lang,
            onRetry: () {
              setState(() {});
              _refresh();
            },
          );
        }
        return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text(t(lang, 'weather'), style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
              IconButton(
                tooltip: t(lang, 'addCity'),
                onPressed: () => _addCity(context),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: t(lang, 'permLocation'),
                onPressed: _gpsBusy ? null : _nearMe,
                icon: _gpsBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: store.weatherCities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(t(lang, 'noCity'), textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= xlBreak
                          ? 3
                          : MediaQuery.sizeOf(context).width >= mediumBreak
                              ? 2
                              : 1,
                      mainAxisExtent: 168,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: store.weatherCities.length,
                    itemBuilder: (ctx, i) {
                      final id = store.weatherCities[i];
                      final city = cityById(id);
                      if (city == null) return const SizedBox.shrink();
                      final snap = _cache[id];
                      final err = _err[id];
                      return swipeToDelete(
                        context: context,
                        key: 'wx-$id',
                        lang: lang,
                        onDelete: () => store.removeWeatherCity(id),
                        child: CityCard(
                          city: city,
                          snap: snap,
                          error: err != null,
                          lang: lang,
                          onOpen: () {
                            pushWeatherList(widget.store, _cache, selectId: id);
                            _openCity(city, snap);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
        );
      },
    );
  }

  Future<void> _addCity(BuildContext context) =>
      showAddCitySheet(context, store: widget.store, onAdded: _refresh);

  Future<void> _nearMe() async {
    setState(() => _gpsBusy = true);
    final r = await requestNearbyCity(widget.store);
    if (!mounted) return;
    setState(() => _gpsBusy = false);
    if (!context.mounted) return;
    showGpsSnack(context, widget.store.lang, r);
    if (r == GpsResult.added || r == GpsResult.already) await _refresh();
  }

  Future<void> _openCity(City city, WeatherSnap? snap) =>
      showCityDetailSheet(context, lang: widget.store.lang, city: city, snap: snap);
}
