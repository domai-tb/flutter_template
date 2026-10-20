import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsDataSource {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesSettingsDataSource implements SettingsDataSource {
  static const String _prefsKey = 'app_settings_json_v1';

  final SharedPreferences _preferences;

  const SharedPreferencesSettingsDataSource(this._preferences);

  static Future<SharedPreferencesSettingsDataSource> create() async =>
      SharedPreferencesSettingsDataSource(await SharedPreferences.getInstance());

  @override
  Future<String?> read() async => _preferences.getString(_prefsKey);

  @override
  Future<void> write(String value) async {
    await _preferences.setString(_prefsKey, value);
  }
}
