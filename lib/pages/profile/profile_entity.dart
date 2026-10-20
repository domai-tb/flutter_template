import 'package:flutter/foundation.dart';

@immutable
class ProfileEntity {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? accountId;
  final String? providerName;
  final Map<String, String> metadata;

  const ProfileEntity({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.accountId,
    this.providerName,
    this.metadata = const {},
  });
}

typedef ShellAuthUser = ProfileEntity;
