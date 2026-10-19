import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/shell_auth.dart';
import 'package:flutter_template/l10n/l10n_x.dart';

class ShellProfilePage extends StatelessWidget {
  final String appTitle;
  final VoidCallback onSignIn;

  const ShellProfilePage({super.key, required this.appTitle, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context).services.authProvider;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: provider == null
          ? _guest(context)
          : ValueListenableBuilder<ShellAuthState>(
              valueListenable: provider.state,
              builder: (context, state, _) => switch (state.status) {
                ShellAuthStatus.restoring ||
                ShellAuthStatus.authenticating => const Center(child: CircularProgressIndicator()),
                ShellAuthStatus.authenticated when state.user != null => _profile(context, provider, state.user!),
                _ => _guest(context),
              },
            ),
    );
  }

  Widget _guest(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 48),
          const SizedBox(height: 12),
          Text(appTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(context.l10n.guestNotSignedIn, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(context.l10n.profileGuestMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onSignIn, child: Text(context.l10n.signIn)),
        ],
      ),
    ),
  );

  Widget _profile(BuildContext context, ShellAuthProvider provider, ShellAuthUser user) {
    final name = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : user.email ?? user.id;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              _ProfileAvatar(user: user),
              const SizedBox(height: 12),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              if (user.email case final email?) Text(email),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (user.accountId case final accountId?) _detail(context, context.l10n.accountIdentifier, accountId),
        _detail(context, context.l10n.userIdentifier, user.id),
        if (user.providerName case final providerName?)
          _detail(context, context.l10n.authenticationProvider, providerName),
        for (final entry in user.metadata.entries) _detail(context, entry.key, entry.value),
        if (provider.editProfileAction case final action?) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await action.run();
              if (context.mounted && !result.succeeded) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result.message ?? context.l10n.authenticationFailed)));
              }
            },
            icon: Icon(action.icon),
            label: Text(action.label),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await provider.signOut();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signOutFailed)));
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: Text(context.l10n.signOut),
        ),
      ],
    );
  }

  Widget _detail(BuildContext context, String label, String value) =>
      ListTile(title: Text(label), subtitle: SelectableText(value));
}

class _ProfileAvatar extends StatelessWidget {
  final ShellAuthUser user;

  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final label = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : user.email ?? '';
    final initials = label.isEmpty
        ? null
        : label
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part.substring(0, 1).toUpperCase())
              .join();
    return CircleAvatar(
      radius: 36,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: user.avatarUrl == null
          ? Text(
              initials ?? '?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            )
          : ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(initials ?? '?'),
              ),
            ),
    );
  }
}
