import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/shell_auth.dart';
import 'package:flutter_template/l10n/l10n_x.dart';

class ShellLoginPage extends StatefulWidget {
  final String appTitle;

  const ShellLoginPage({super.key, required this.appTitle});

  @override
  State<ShellLoginPage> createState() => _ShellLoginPageState();
}

class _ShellLoginPageState extends State<ShellLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(ShellAuthProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final result = await provider.signIn(email: _emailController.text.trim(), password: _passwordController.text);
      if (!mounted) return;
      if (result.succeeded && provider.state.value.status == ShellAuthStatus.authenticated) {
        Navigator.of(context).maybePop();
        return;
      }
      setState(() => _error = result.message ?? context.l10n.authenticationFailed);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.authenticationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAction(ShellAuthAction action, ShellAuthProvider provider) async {
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final result = await action.run();
      if (!mounted) return;
      if (result.succeeded && provider.state.value.status == ShellAuthStatus.authenticated) {
        Navigator.of(context).maybePop();
      } else {
        setState(() {
          _message = result.succeeded ? action.label : null;
          _error = result.succeeded ? null : (result.message ?? context.l10n.authenticationFailed);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.authenticationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppScope.of(context).services.authProvider;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.signIn), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: provider == null
                        ? _unavailable(context)
                        : ValueListenableBuilder<ShellAuthState>(
                            valueListenable: provider.state,
                            builder: (context, state, _) => _form(context, provider, state),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unavailable(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.lock_outline, size: 40),
      const SizedBox(height: 16),
      Text(widget.appTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(context.l10n.authenticationUnavailable, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      OutlinedButton(onPressed: Navigator.of(context).maybePop, child: Text(context.l10n.returnToApp)),
    ],
  );

  Widget _form(BuildContext context, ShellAuthProvider provider, ShellAuthState state) {
    final loading =
        _busy || state.status == ShellAuthStatus.restoring || state.status == ShellAuthStatus.authenticating;
    final identityActions = provider.identityProviderActions;
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.appTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(context.l10n.signInPrompt, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(labelText: context.l10n.emailOrUsername),
              validator: (value) => value == null || value.trim().isEmpty ? context.l10n.requiredField : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: loading ? null : (_) => _signIn(provider),
              decoration: InputDecoration(
                labelText: context.l10n.password,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? context.l10n.showPassword : context.l10n.hidePassword,
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? context.l10n.requiredField : null,
            ),
            if (_error != null || state.status == ShellAuthStatus.expired) ...[
              const SizedBox(height: 12),
              Text(
                _error ?? state.message ?? context.l10n.sessionExpired,
                key: const ValueKey('auth-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_message != null) ...[const SizedBox(height: 12), Text(_message!, textAlign: TextAlign.center)],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loading ? null : () => _signIn(provider),
              icon: loading
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(context.l10n.signIn),
            ),
            if (provider.forgotPasswordAction case final action?)
              TextButton(
                onPressed: loading ? null : () => _runAction(action, provider),
                child: Text(context.l10n.forgotPassword),
              ),
            if (provider.createAccountAction case final action?)
              TextButton(
                onPressed: loading ? null : () => _runAction(action, provider),
                child: Text(context.l10n.createAccount),
              ),
            for (final action in identityActions)
              OutlinedButton.icon(
                onPressed: loading ? null : () => _runAction(action, provider),
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
            TextButton(onPressed: Navigator.of(context).maybePop, child: Text(context.l10n.continueAsGuest)),
          ],
        ),
      ),
    );
  }
}
