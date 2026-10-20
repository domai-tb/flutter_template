import 'package:flutter/foundation.dart';

import 'package:flutter_template/pages/profile/profile_datasource.dart';
import 'package:flutter_template/pages/profile/profile_repository.dart';

class ProfileUseCase {
  final ProfileRepository repository;

  const ProfileUseCase({required this.repository});

  ValueListenable<ShellAuthState> get state => repository.state;

  Future<ShellAuthResult> signIn({required String email, required String password}) =>
      repository.signIn(email: email, password: password);

  Future<void> signOut() => repository.signOut();

  Future<void> restoreSession() => repository.restoreSession();

  ShellAuthAction? get forgotPasswordAction => repository.forgotPasswordAction;
  ShellAuthAction? get createAccountAction => repository.createAccountAction;
  ShellAuthAction? get editProfileAction => repository.editProfileAction;
  List<ShellAuthAction> get identityProviderActions => repository.identityProviderActions;
}
