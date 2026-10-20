import 'package:flutter_template/pages/settings/settings_entity.dart';
import 'package:flutter_template/pages/settings/settings_repository.dart';

class SettingsUseCase {
  final SettingsRepository repository;

  const SettingsUseCase({required this.repository});

  Future<Settings> load() => repository.load();

  Future<void> save(Settings settings) => repository.save(settings);
}
