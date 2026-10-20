import 'package:flutter/foundation.dart';

import 'package:flutter_template/pages/profile/profile_datasource.dart';

class ProfileRepository {
  final ProfileDataSource dataSource;

  const ProfileRepository({required this.dataSource});

  ValueListenable<ShellAuthState> get state => dataSource.state;

  Future<ShellAuthResult> signIn({required String email, required String password}) =>
      dataSource.signIn(email: email, password: password);

  Future<void> signOut() => dataSource.signOut();

  Future<void> restoreSession() => dataSource.restoreSession();

  ShellAuthAction? get forgotPasswordAction => dataSource.forgotPasswordAction;
  ShellAuthAction? get createAccountAction => dataSource.createAccountAction;
  ShellAuthAction? get editProfileAction => dataSource.editProfileAction;
  List<ShellAuthAction> get identityProviderActions => dataSource.identityProviderActions;
}
