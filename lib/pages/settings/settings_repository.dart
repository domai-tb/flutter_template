import 'dart:convert';

import 'package:flutter_template/pages/settings/settings_datasource.dart';
import 'package:flutter_template/pages/settings/settings_entity.dart';

class SettingsRepository {
  final SettingsDataSource dataSource;

  const SettingsRepository({required this.dataSource});

  Future<Settings> load() async {
    final raw = await dataSource.read();
    if (raw == null || raw.trim().isEmpty) return const Settings();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Settings.fromJson(Map<String, dynamic>.from(decoded)) : const Settings();
    } catch (_) {
      return const Settings();
    }
  }

  Future<void> save(Settings settings) => dataSource.write(jsonEncode(settings.toJson()));
}
