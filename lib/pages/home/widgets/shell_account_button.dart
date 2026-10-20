import 'package:flutter/material.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/profile/profile_datasource.dart';
import 'package:flutter_template/pages/profile/profile_usecase.dart';

enum ShellAccountMenuAction { signIn, profile, signOut }

class ShellAccountButton extends StatelessWidget {
  final ProfileUseCase? provider;
  final VoidCallback onSignIn;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  const ShellAccountButton({
    super.key,
    required this.provider,
    required this.onSignIn,
    required this.onProfile,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (provider == null) return _buildButton(context, null);
    return ValueListenableBuilder<ShellAuthState>(
      valueListenable: provider!.state,
      builder: (context, state, _) => _buildButton(context, state),
    );
  }

  Widget _buildButton(BuildContext context, ShellAuthState? state) {
    final user = state?.status == ShellAuthStatus.authenticated ? state?.user : null;
    final loading = state?.status == ShellAuthStatus.restoring || state?.status == ShellAuthStatus.authenticating;
    final tooltip = loading
        ? context.l10n.checkingSession
        : state?.status == ShellAuthStatus.expired
        ? context.l10n.sessionExpired
        : user?.displayName ?? user?.email ?? context.l10n.guestNotSignedIn;
    return PopupMenuButton<ShellAccountMenuAction>(
      key: const ValueKey('account-menu-button'),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case ShellAccountMenuAction.signIn:
            onSignIn();
            break;
          case ShellAccountMenuAction.profile:
            onProfile();
            break;
          case ShellAccountMenuAction.signOut:
            onSignOut();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<ShellAccountMenuAction>(
          enabled: false,
          child: Row(
            children: [
              _avatar(context, user, loading, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loading
                      ? context.l10n.checkingSession
                      : user?.displayName ?? user?.email ?? context.l10n.guestNotSignedIn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (user == null && !loading) ...[
          PopupMenuItem(
            value: ShellAccountMenuAction.signIn,
            height: 44,
            child: _menuRow(Icons.login, context.l10n.signIn),
          ),
          PopupMenuItem(
            value: ShellAccountMenuAction.profile,
            height: 44,
            child: _menuRow(Icons.person_outline, context.l10n.profile),
          ),
        ] else if (user != null) ...[
          PopupMenuItem(
            value: ShellAccountMenuAction.profile,
            height: 44,
            child: _menuRow(Icons.person_outline, context.l10n.profile),
          ),
          PopupMenuItem(
            value: ShellAccountMenuAction.signOut,
            height: 44,
            child: _menuRow(Icons.logout, context.l10n.signOut),
          ),
        ],
      ],
      child: Semantics(
        button: true,
        label: context.l10n.account,
        value: tooltip,
        child: SizedBox.expand(child: _avatar(context, user, loading, size: 28)),
      ),
    );
  }
}

Widget _menuRow(IconData icon, String title) =>
    Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(title)]);

Widget _avatar(BuildContext context, ShellAuthUser? user, bool loading, {required double size}) {
  final colors = Theme.of(context).colorScheme;
  Widget fallback() {
    final name = user?.displayName?.trim() ?? '';
    final email = user?.email?.trim() ?? '';
    final label = name.isNotEmpty ? name : email;
    final initials = label.isEmpty
        ? null
        : label
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part.substring(0, 1).toUpperCase())
              .join();
    if (loading) return const Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2));
    return initials == null
        ? Icon(Icons.person_outline, size: size * 0.7, color: colors.onSurfaceVariant)
        : Text(initials, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onPrimary));
  }

  final avatarUrl = user?.avatarUrl;
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: colors.primary,
    child: avatarUrl == null || avatarUrl.isEmpty
        ? fallback()
        : ClipOval(
            child: Image.network(
              avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback(),
            ),
          ),
  );
}
