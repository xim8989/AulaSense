import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de la cuenta de demostración actual.
class ProfileSettings extends ChangeNotifier {
  ProfileSettings._();
  static final instance = ProfileSettings._();
  SharedPreferences? _storage;
  String email = '';
  String name = 'Usuario de AulaSense';
  final Set<String> favorites = {};
  String? firstZone;
  bool temperatureAlerts = false;
  bool humidityAlerts = false;
  bool lightAlerts = false;
  double minTemperature = 18;
  double maxTemperature = 28;
  double minHumidity = 30;
  double maxHumidity = 60;
  double minLight = 300;
  double maxLight = 1000;

  static const zones = {
    'C': 'Zona Central (C)',
    'S1': 'Zona S1',
    'S2': 'Zona S2',
  };

  Future<void> initialize() async {
    _storage = await SharedPreferences.getInstance();
  }

  void signIn(String address) {
    email = address.trim();
    final key = 'profile.$email.';
    name = _storage?.getString('${key}name') ?? 'Usuario de AulaSense';
    favorites
      ..clear()
      ..addAll(_storage?.getStringList('${key}favorites') ?? []);
    firstZone = _storage?.getString('${key}firstZone');
    temperatureAlerts = _storage?.getBool('${key}temperatureAlerts') ?? false;
    humidityAlerts = _storage?.getBool('${key}humidityAlerts') ?? false;
    lightAlerts = _storage?.getBool('${key}lightAlerts') ?? false;
    minTemperature = _storage?.getDouble('${key}minTemperature') ?? 18;
    maxTemperature = _storage?.getDouble('${key}maxTemperature') ?? 28;
    minHumidity = _storage?.getDouble('${key}minHumidity') ?? 30;
    maxHumidity = _storage?.getDouble('${key}maxHumidity') ?? 60;
    minLight = _storage?.getDouble('${key}minLight') ?? 300;
    maxLight = _storage?.getDouble('${key}maxLight') ?? 1000;
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    final storage = _storage;
    if (storage == null) return;
    final key = 'profile.$email.';
    // Capturar los valores antes de esperar evita mezclar dos cuentas.
    final ranges = {
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'minLight': minLight,
      'maxLight': maxLight,
    };
    await Future.wait([
      storage.setString('${key}name', name),
      storage.setStringList('${key}favorites', favorites.toList()),
      firstZone == null
          ? storage.remove('${key}firstZone')
          : storage.setString('${key}firstZone', firstZone!),
      storage.setBool('${key}temperatureAlerts', temperatureAlerts),
      storage.setBool('${key}humidityAlerts', humidityAlerts),
      storage.setBool('${key}lightAlerts', lightAlerts),
      for (final entry in ranges.entries)
        storage.setDouble('$key${entry.key}', entry.value),
    ]);
  }

  void notifyRangeChanged() => notifyListeners();

  void signOut() {
    email = '';
    name = 'Usuario de AulaSense';
    favorites.clear();
    firstZone = null;
    temperatureAlerts = humidityAlerts = lightAlerts = false;
    notifyListeners();
  }
}
