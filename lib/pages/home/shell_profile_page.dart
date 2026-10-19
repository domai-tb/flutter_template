import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/shell_auth.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';

/// Displays the profile view inside the mobile account route.
class ShellProfilePage extends StatelessWidget {
  final String appTitle;
  final VoidCallback onSignIn;

  const ShellProfilePage({super.key, required this.appTitle, required this.onSignIn});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.profile)),
    body: ShellProfileView(appTitle: appTitle, onSignIn: onSignIn, showHeader: false),
  );
}

/// Renders compact guest and authenticated account details in a shell workspace.
class ShellProfileView extends StatelessWidget {
  final String appTitle;
  final VoidCallback onSignIn;
  final bool showHeader;

  const ShellProfileView({super.key, required this.appTitle, required this.onSignIn, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context).services.authProvider;
    final metrics = AppTheme.metrics(
      context,
      phone: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
    );
    final tokens = Theme.of(context).extension<AppShellTokens>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.activityRowHeight / 2,
              AppShellSpacing.lg,
              AppShellSpacing.lg,
              AppShellSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.profile, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppShellSpacing.xs),
                Text(appTitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        if (showHeader)
          Divider(height: tokens?.borderWidth ?? 1, color: tokens?.border ?? Theme.of(context).dividerColor),
        Expanded(
          child: provider == null
              ? _GuestContent(onSignIn: onSignIn)
              : ValueListenableBuilder<ShellAuthState>(
                  valueListenable: provider.state,
                  builder: (context, state, _) => switch (state.status) {
                    ShellAuthStatus.restoring || ShellAuthStatus.authenticating => const _LoadingContent(),
                    ShellAuthStatus.authenticated when state.user != null => _AuthenticatedContent(
                      user: state.user!,
                      provider: provider,
                    ),
                    ShellAuthStatus.expired => _GuestContent(onSignIn: onSignIn, message: state.message),
                    ShellAuthStatus.signedOut || ShellAuthStatus.authenticated => _GuestContent(onSignIn: onSignIn),
                  },
                ),
        ),
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.all(AppShellSpacing.xl),
      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}

class _GuestContent extends StatelessWidget {
  final VoidCallback onSignIn;
  final String? message;

  const _GuestContent({required this.onSignIn, this.message});

  @override
  Widget build(BuildContext context) {
    final metrics = AppTheme.metrics(
      context,
      phone: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppShellSpacing.xl,
        AppShellSpacing.lg,
        AppShellSpacing.xl,
        AppShellSpacing.xl,
      ),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: metrics.profileAvatarSize / 2,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.person_outline, size: 20),
            ),
            const SizedBox(width: AppShellSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.guestNotSignedIn, style: Theme.of(context).textTheme.labelLarge),
                Text(context.l10n.account, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppShellSpacing.lg),
        Text(message ?? context.l10n.profileGuestMessage, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppShellSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onSignIn,
            icon: const Icon(Icons.login),
            label: Text(context.l10n.signIn),
          ),
        ),
      ],
    );
  }
}

class _AuthenticatedContent extends StatelessWidget {
  final ShellAuthUser user;
  final ShellAuthProvider provider;

  const _AuthenticatedContent({required this.user, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = AppTheme.metrics(
      context,
      phone: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
    );
    final name = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : user.email ?? user.id;
    final fields = <(String, String)>[
      if (user.email case final email?) (context.l10n.emailOrUsername, email),
      (context.l10n.userIdentifier, user.id),
      if (user.accountId case final accountId?) (context.l10n.accountIdentifier, accountId),
      if (user.providerName case final providerName?) (context.l10n.authenticationProvider, providerName),
      for (final entry in user.metadata.entries) (entry.key, entry.value),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppShellSpacing.xl,
        AppShellSpacing.lg,
        AppShellSpacing.xl,
        AppShellSpacing.xl,
      ),
      children: [
        Row(
          children: [
            _ProfileAvatar(user: user, size: metrics.profileAvatarSize),
            const SizedBox(width: AppShellSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  if (user.providerName case final providerName?) Text(providerName, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppShellSpacing.lg),
        for (final (label, value) in fields) ...[
          _ProfileDetailRow(label: label, value: value),
          Divider(height: 1, color: theme.dividerColor),
        ],
        const SizedBox(height: AppShellSpacing.md),
        Wrap(
          spacing: AppShellSpacing.sm,
          runSpacing: AppShellSpacing.sm,
          children: [
            if (provider.editProfileAction case final action?)
              OutlinedButton.icon(
                onPressed: () => _runAction(context, action),
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
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
        ),
      ],
    );
  }

  Future<void> _runAction(BuildContext context, ShellAuthAction action) async {
    try {
      final result = await action.run();
      if (context.mounted && !result.succeeded) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message ?? context.l10n.authenticationFailed)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.authenticationFailed)));
      }
    }
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final metrics = AppTheme.metrics(
      context,
      phone: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppShellSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final labelWidth = compact ? null : metrics.settingsMaxWidth / 3;
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppShellSpacing.xs),
                    SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
                    ),
                    Expanded(child: SelectableText(value, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ShellAuthUser user;
  final double size;

  const _ProfileAvatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final label = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : user.email ?? '';
    final initials = label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: user.avatarUrl == null
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            )
          : ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(initials.isEmpty ? '?' : initials),
              ),
            ),
    );
  }
}
