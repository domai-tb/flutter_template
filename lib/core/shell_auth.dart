import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ShellAuthStatus { restoring, signedOut, authenticating, authenticated, expired }

@immutable
class ShellAuthUser {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? accountId;
  final String? providerName;
  final Map<String, String> metadata;

  const ShellAuthUser({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.accountId,
    this.providerName,
    this.metadata = const {},
  });
}

@immutable
class ShellAuthState {
  final ShellAuthStatus status;
  final ShellAuthUser? user;

  /// Provider-supplied user-safe status text; never include credentials or tokens.
  final String? message;

  const ShellAuthState({required this.status, this.user, this.message});
}

@immutable
class ShellAuthResult {
  final bool succeeded;

  /// Provider-supplied user-safe text; never include credentials or tokens.
  final String? message;

  const ShellAuthResult.success() : succeeded = true, message = null;
  const ShellAuthResult.failure(this.message) : succeeded = false;
}

class ShellAuthAction {
  final String id;
  final String label;
  final IconData icon;
  final Future<ShellAuthResult> Function() run;

  const ShellAuthAction({required this.id, required this.label, required this.icon, required this.run});
}

/// Provider-neutral authentication contract for consuming applications.
///
/// Providers own credentials, tokens, secure storage, and session expiration.
abstract class ShellAuthProvider {
  ValueListenable<ShellAuthState> get state;

  Future<ShellAuthResult> signIn({required String email, required String password});
  Future<void> signOut();

  Future<void> restoreSession() async {}

  ShellAuthAction? get forgotPasswordAction => null;
  ShellAuthAction? get createAccountAction => null;
  ShellAuthAction? get editProfileAction => null;
  List<ShellAuthAction> get identityProviderActions => const [];
}
