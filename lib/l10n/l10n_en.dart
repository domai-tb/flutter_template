// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get appTitle => 'Template App';

  @override
  String get page1Title => 'Page 1';

  @override
  String get page2Title => 'Page 2';

  @override
  String get page3Title => 'Page 3';

  @override
  String get page4Title => 'Page 4';

  @override
  String get page5Title => 'Page 5';

  @override
  String get page6Title => 'Page 6';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get detailTitle => 'Detail';

  @override
  String get searchLabel => 'Search';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get onboardingIntroBody =>
      'This is a skeleton app that preserves the architecture and UI shell.';

  @override
  String get onboardingIntroHint =>
      'Replace \"Page 1..Page 6\" with your own features.';

  @override
  String get onboardingPreferencesTitle => 'Preferences';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get accessibilityLabel => 'Accessibility';

  @override
  String get useSystemTextScaling => 'Use system text scaling';

  @override
  String get navigationLabel => 'Navigation';

  @override
  String get navigationOrderHint => 'Drag to reorder menu items.';

  @override
  String get navigationVisibilityLabel => 'Show in navigation';

  @override
  String get navigationSettingsAlwaysVisibleHint =>
      'Page 6 stays visible so settings remain reachable.';

  @override
  String get currentPageLabel => 'Current page';

  @override
  String get shellPlaceholderTab => 'Placeholder';

  @override
  String get shellPlaceholderBody =>
      'This tab is a neutral content slot. Register a view builder to supply app content.';

  @override
  String get inspectorEmpty => 'No right sidebar content is registered.';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Retry';

  @override
  String get shellMissingRoute => 'This destination is unavailable.';

  @override
  String get shellNoDestinations => 'No destinations are registered.';

  @override
  String shellContentError(String details) {
    return 'This content could not be shown: $details';
  }

  @override
  String get shellMissingView => 'This view is unavailable.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get openInspector => 'Open right sidebar';

  @override
  String get closeInspector => 'Close right sidebar';

  @override
  String get restoreLayout => 'Restore default layout';

  @override
  String get openSplitView => 'Open split view';

  @override
  String get closeSplitView => 'Close split view';

  @override
  String get toggleAppearance => 'Toggle light or dark appearance';

  @override
  String get addPlaceholderTab => 'Add placeholder tab';

  @override
  String openView(String view) {
    return 'Open view: $view';
  }

  @override
  String navigateTo(String destination) {
    return 'Navigate to $destination';
  }

  @override
  String get selectContext => 'Select context';

  @override
  String get selectModule => 'Select module';

  @override
  String switchContext(String context) {
    return 'Switch context: $context';
  }

  @override
  String switchModule(String module) {
    return 'Switch module: $module';
  }

  @override
  String get commandPalette => 'Command palette';

  @override
  String get commandPaletteHint => 'Search shell commands';

  @override
  String get switchView => 'Switch view';

  @override
  String get moreActions => 'More actions';

  @override
  String get reorderTab => 'Drag to reorder tab';

  @override
  String get tabActions => 'Tab actions';

  @override
  String get moveLeft => 'Move tab left';

  @override
  String get moveRight => 'Move tab right';

  @override
  String get closeTab => 'Close tab';

  @override
  String get inspector => 'Right sidebar';

  @override
  String get resizeInspector => 'Resize right sidebar';

  @override
  String get resizeSplitPane => 'Resize split pane';

  @override
  String get splitPanePlaceholder => 'This is a neutral second content slot.';

  @override
  String get shellReady => 'Ready';

  @override
  String get phoneLayout => 'Phone';

  @override
  String get desktopLayout => 'Desktop';

  @override
  String get accentLabel => 'Accent';

  @override
  String get resetAppearance => 'Reset appearance';

  @override
  String get densityLabel => 'Spacing';

  @override
  String get compactDensity => 'Compact';

  @override
  String get comfortableDensity => 'Comfortable';

  @override
  String get localStorageNote =>
      'Settings are stored on this device or browser only.';

  @override
  String get resetLayout => 'Reset layout';

  @override
  String get resetAllPreferences => 'Reset all preferences';

  @override
  String get resetAllConfirmation =>
      'Reset all local template preferences? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmReset => 'Reset';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get keyboardLabel => 'Keyboard';

  @override
  String get shortcutReference => 'Shortcuts';

  @override
  String get aboutShell => 'About this shell';

  @override
  String get textScalingHint => 'System text scaling is always respected.';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get openViewTab => 'Open view';

  @override
  String get viewPickerTitle => 'Open registered view';

  @override
  String get viewPickerHint => 'Search registered views';

  @override
  String get openTabOverflow => 'Find open tab';

  @override
  String get tabOverflowTitle => 'Open tabs';

  @override
  String get noTabsOpen => 'No views are open.';

  @override
  String get closeOtherTabs => 'Close other tabs';

  @override
  String get closeTabsToRight => 'Close tabs to the right';

  @override
  String get notifications => 'Notifications';

  @override
  String get openNotifications => 'Open notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get dismissNotification => 'Dismiss notification';

  @override
  String get clearNotifications => 'Clear all';

  @override
  String get notificationAction => 'Open';

  @override
  String get notificationInfo => 'Information';

  @override
  String get notificationSuccess => 'Success';

  @override
  String get notificationWarning => 'Warning';

  @override
  String get notificationError => 'Error';

  @override
  String get notificationPrivacyNote =>
      'Notifications stay in memory and are cleared when the app closes.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLayout => 'Layout';

  @override
  String get settingsNavigation => 'Navigation';

  @override
  String get settingsKeyboard => 'Keyboard';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAbout => 'About';

  @override
  String get shellEmptyWorkspace => 'Choose a registered view to open.';

  @override
  String get walletPlaceholderBody => 'Placeholder for a wallet-style feature.';

  @override
  String get primaryAction => 'Primary Action';

  @override
  String get secondaryAction => 'Secondary Action';

  @override
  String get primaryActionSnack => 'Replace this with your real action';

  @override
  String get secondaryActionSnack => 'Another placeholder action';

  @override
  String get menuSettingsSubtitle => 'Template app settings';

  @override
  String get menuAboutSubtitle => 'About this template';

  @override
  String get aboutBody =>
      'This repository is a mobile app skeleton.\n\nReplace the placeholder pages (Page 1..Page 6) with your own features while keeping the architecture (datasources, repositories, usecases, entities, pages).';

  @override
  String get serverFailureMessage => 'Could not load server data.';

  @override
  String get generalFailureMessage => 'An error has occurred.';

  @override
  String get errorMessage => 'Error.';

  @override
  String get unexpectedError => 'An unexpected error occured...';

  @override
  String get invalid2FATokenFailureMessage =>
      'Your TOTP is incorrect. Please try again!';

  @override
  String get invalidLoginIDAndPasswordFailureMessage =>
      'The credentials are invalid!';

  @override
  String get welcome => 'Welcome!';

  @override
  String get login_prompt => 'Please login with your username and password.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get empty_input_field => 'Please enter your credentials!';

  @override
  String get login_error => 'Invalid input!';

  @override
  String get login_success => 'Successfully logged in!';

  @override
  String get login_already => 'Allready logged in.';

  @override
  String get enter_totp => 'Please enter your TOTP.';

  @override
  String get inspectorWorkspace => 'Workspace';

  @override
  String get inspectorSelection => 'Selection';

  @override
  String get inspectorSection => 'Section';

  @override
  String get inspectorOpenTabs => 'Open tabs';

  @override
  String get inspectorView => 'View';

  @override
  String get inspectorInstance => 'Instance';

  @override
  String get inspectorEmptyState => 'No tab is active.';

  @override
  String get renameTab => 'Rename tab';

  @override
  String get tabTitleLabel => 'Tab name';

  @override
  String get save => 'Save';

  @override
  String get openSectionPanel => 'Open section panel';

  @override
  String get closeSectionPanel => 'Close section panel';

  @override
  String get closeUnsavedTabTitle => 'Close modified view?';

  @override
  String closeUnsavedTabMessage(String title) {
    return 'Close $title and discard its unsaved changes?';
  }

  @override
  String get account => 'Account';

  @override
  String get guestNotSignedIn => 'Guest · Not signed in';

  @override
  String get signIn => 'Sign in';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get authenticationUnavailable =>
      'Sign-in is not configured for this application. You can continue using the app as a guest.';

  @override
  String get returnToApp => 'Return to app';

  @override
  String get signInPrompt => 'Sign in to your account';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get authenticationFailed =>
      'Sign-in could not be completed. Check your details and try again.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAccount => 'Create account';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get profileGuestMessage =>
      'No account is connected. Your workspace remains available in guest mode.';

  @override
  String get accountIdentifier => 'Account ID';

  @override
  String get userIdentifier => 'User ID';

  @override
  String get authenticationProvider => 'Sign-in provider';

  @override
  String get signOutFailed => 'Could not sign out. Please try again.';

  @override
  String get returnToPreviousSection => 'Return to previous section';

  @override
  String get sessionExpired =>
      'Your session has expired. Sign in again to continue.';

  @override
  String get checkingSession => 'Checking account…';

  @override
  String get newTab => 'New tab';

  @override
  String get searchOpenTabs => 'Search open tabs';

  @override
  String get noOpenTabsMatch => 'No open tabs match this search.';

  @override
  String get rightSidebar => 'Right sidebar';

  @override
  String get openRightSidebar => 'Open right sidebar';

  @override
  String get closeRightSidebar => 'Close right sidebar';

  @override
  String get resizeRightSidebar => 'Resize right sidebar';

  @override
  String get page1Overview => 'Overview';

  @override
  String get page1Items => 'Items';

  @override
  String get page1AllItems => 'All items';

  @override
  String get page1RecentItems => 'Recent items';

  @override
  String get page1Reports => 'Reports';

  @override
  String get page1Summary => 'Summary';

  @override
  String get selectedItem => 'Selected item';

  @override
  String get selectItemForDetails => 'Select an item to see its details here.';

  @override
  String page1SummaryDescription(int count) {
    return '$count items are available in this workspace.';
  }
}
