# Settings, authentication, and persisted state

Read only the section relevant to the feature. Paths are relative to the application repository root; inspect current contracts before implementing an adapter.

## Settings

The existing path is `SettingsPage` → `SettingsController` → `SettingsUseCase` → `SettingsRepository` → `SettingsDataSource`, all under `lib/pages/settings/`.

- Read the controller through `AppScope.of(context).settings`. Apply changes with `controller.update(controller.settings.copyWith(...))`; do not construct defaults that discard unrelated preferences.
- `SettingsController` is shared app state. The Settings page's selected section, focus, scroll position, and other presentation state remain local to each Settings tab.
- `SharedPreferencesSettingsDataSource` owns the storage plugin and the `app_settings_json_v1` key. UI and shell integrations should not write this JSON directly.
- When adding a preference, cover its constructor default, `copyWith`, `fromJson`, `toJson`, and validation. Inspect the current schema/migration behavior before changing it. Accept older saved values with safe defaults and preserve unrelated keys held in `extraSettings`.
- Keep serialized legacy names such as `inspectorWidth` and `inspectorOpen` compatible even though the UI calls the area the right sidebar. Renaming UI text does not authorize a storage migration or reset.
- Store application data through its owning feature's repository/datasource. Settings are preferences and shell restoration metadata, not a general application database or credential store.

## Authentication and profile

`lib/pages/profile/profile_datasource.dart` defines `ProfileDataSource`; `ShellAuthProvider` is its alias. The compatibility export `lib/core/shell_auth.dart` does not own a separate authentication implementation.

Implement a provider adapter in the owning feature and supply it to `init(authProvider: provider)` in `lib/core/injection.dart` before constructing `AppScope` and running the app. Existing wiring creates `ProfileRepository` and `ProfileUseCase`, exposes the use case through `AppServices.profile`, and attempts session restoration.

The adapter must provide:

- `state`: a `ValueListenable<ShellAuthState>` reflecting restoration, signed-out, authenticating, authenticated, and expired states as appropriate.
- `signIn({required String email, required String password})` returning `ShellAuthResult`, and `signOut()`.
- `restoreSession()` when sessions can be restored. Optional actions expose password recovery, account creation, profile editing, or identity providers through `ShellAuthAction`.

The provider owns credentials, tokens, secure storage, and expiration. Expose only user-safe messages and the profile entity to presentation; do not place secrets in settings, tab parameters, notifications, or logs. Keep remote/local access behind the feature's Data boundary. The template's login form and provider contract do not supply a production identity backend.

Treat `AppServices.profile == null` as a supported guest configuration. Observe the use case's state through its listenable rather than reading a one-time snapshot. Keep authentication operations in the feature path; the shell displays the resulting profile/session state.

## Tab restoration and feature data

`ShellTabPreference` and `ShellWorkspacePreference` are in `lib/pages/settings/settings_entity.dart`. Shell navigation owns their updates. New pages normally use `ShellViewContext` controllers rather than editing these models directly.

- Destination, registration, instance, and navigation-node IDs must be stable and independent of translated labels. Inspect `Settings.isStableId` and the restore path before changing ID formats.
- Tab `parameters` must be JSON-serializable reconstruction data: identifiers and small options, not widgets, controllers, repositories, or secrets. The coordinator serializes them when opening a tab.
- The shell restores tab metadata and registered navigation paths; it does not automatically persist arbitrary page fields or unsaved drafts. Rehydrate feature state through its use case, and define draft persistence only when the requested behavior needs it.
- Restore only registrations that still exist and are allowed in the destination. If changing or removing persisted registrations, handle existing workspaces intentionally rather than clearing all preferences.
- Breadcrumb IDs identify a path; the feature must register the nodes and restore the corresponding content. Preserve a valid restored path instead of always replacing it with the default selection.
