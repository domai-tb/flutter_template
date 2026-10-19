import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_de.dart';
import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Template App'**
  String get appTitle;

  /// No description provided for @page1Title.
  ///
  /// In en, this message translates to:
  /// **'Page 1'**
  String get page1Title;

  /// No description provided for @page2Title.
  ///
  /// In en, this message translates to:
  /// **'Page 2'**
  String get page2Title;

  /// No description provided for @page3Title.
  ///
  /// In en, this message translates to:
  /// **'Page 3'**
  String get page3Title;

  /// No description provided for @page4Title.
  ///
  /// In en, this message translates to:
  /// **'Page 4'**
  String get page4Title;

  /// No description provided for @page5Title.
  ///
  /// In en, this message translates to:
  /// **'Page 5'**
  String get page5Title;

  /// No description provided for @page6Title.
  ///
  /// In en, this message translates to:
  /// **'Page 6'**
  String get page6Title;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detailTitle;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @onboardingIntroBody.
  ///
  /// In en, this message translates to:
  /// **'This is a skeleton app that preserves the architecture and UI shell.'**
  String get onboardingIntroBody;

  /// No description provided for @onboardingIntroHint.
  ///
  /// In en, this message translates to:
  /// **'Replace \"Page 1..Page 6\" with your own features.'**
  String get onboardingIntroHint;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get onboardingPreferencesTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @accessibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityLabel;

  /// No description provided for @useSystemTextScaling.
  ///
  /// In en, this message translates to:
  /// **'Use system text scaling'**
  String get useSystemTextScaling;

  /// No description provided for @navigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigationLabel;

  /// No description provided for @navigationOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder menu items.'**
  String get navigationOrderHint;

  /// No description provided for @navigationVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Show in navigation'**
  String get navigationVisibilityLabel;

  /// No description provided for @navigationSettingsAlwaysVisibleHint.
  ///
  /// In en, this message translates to:
  /// **'Page 6 stays visible so settings remain reachable.'**
  String get navigationSettingsAlwaysVisibleHint;

  /// No description provided for @currentPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current page'**
  String get currentPageLabel;

  /// No description provided for @shellPlaceholderTab.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get shellPlaceholderTab;

  /// No description provided for @shellPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This tab is a neutral content slot. Register a view builder to supply app content.'**
  String get shellPlaceholderBody;

  /// No description provided for @inspectorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inspector content is registered.'**
  String get inspectorEmpty;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @shellMissingRoute.
  ///
  /// In en, this message translates to:
  /// **'This destination is unavailable.'**
  String get shellMissingRoute;

  /// No description provided for @shellNoDestinations.
  ///
  /// In en, this message translates to:
  /// **'No destinations are registered.'**
  String get shellNoDestinations;

  /// No description provided for @shellContentError.
  ///
  /// In en, this message translates to:
  /// **'This content could not be shown: {details}'**
  String shellContentError(String details);

  /// No description provided for @shellMissingView.
  ///
  /// In en, this message translates to:
  /// **'This view is unavailable.'**
  String get shellMissingView;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @openInspector.
  ///
  /// In en, this message translates to:
  /// **'Open inspector'**
  String get openInspector;

  /// No description provided for @closeInspector.
  ///
  /// In en, this message translates to:
  /// **'Close inspector'**
  String get closeInspector;

  /// No description provided for @restoreLayout.
  ///
  /// In en, this message translates to:
  /// **'Restore default layout'**
  String get restoreLayout;

  /// No description provided for @openSplitView.
  ///
  /// In en, this message translates to:
  /// **'Open split view'**
  String get openSplitView;

  /// No description provided for @closeSplitView.
  ///
  /// In en, this message translates to:
  /// **'Close split view'**
  String get closeSplitView;

  /// No description provided for @toggleAppearance.
  ///
  /// In en, this message translates to:
  /// **'Toggle light or dark appearance'**
  String get toggleAppearance;

  /// No description provided for @addPlaceholderTab.
  ///
  /// In en, this message translates to:
  /// **'Add placeholder tab'**
  String get addPlaceholderTab;

  /// No description provided for @openView.
  ///
  /// In en, this message translates to:
  /// **'Open view: {view}'**
  String openView(String view);

  /// No description provided for @navigateTo.
  ///
  /// In en, this message translates to:
  /// **'Navigate to {destination}'**
  String navigateTo(String destination);

  /// No description provided for @selectContext.
  ///
  /// In en, this message translates to:
  /// **'Select context'**
  String get selectContext;

  /// No description provided for @selectModule.
  ///
  /// In en, this message translates to:
  /// **'Select module'**
  String get selectModule;

  /// No description provided for @switchContext.
  ///
  /// In en, this message translates to:
  /// **'Switch context: {context}'**
  String switchContext(String context);

  /// No description provided for @switchModule.
  ///
  /// In en, this message translates to:
  /// **'Switch module: {module}'**
  String switchModule(String module);

  /// No description provided for @commandPalette.
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get commandPalette;

  /// No description provided for @commandPaletteHint.
  ///
  /// In en, this message translates to:
  /// **'Search shell commands'**
  String get commandPaletteHint;

  /// No description provided for @switchView.
  ///
  /// In en, this message translates to:
  /// **'Switch view'**
  String get switchView;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @reorderTab.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder tab'**
  String get reorderTab;

  /// No description provided for @tabActions.
  ///
  /// In en, this message translates to:
  /// **'Tab actions'**
  String get tabActions;

  /// No description provided for @moveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move tab left'**
  String get moveLeft;

  /// No description provided for @moveRight.
  ///
  /// In en, this message translates to:
  /// **'Move tab right'**
  String get moveRight;

  /// No description provided for @closeTab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get closeTab;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @resizeInspector.
  ///
  /// In en, this message translates to:
  /// **'Resize inspector'**
  String get resizeInspector;

  /// No description provided for @resizeSplitPane.
  ///
  /// In en, this message translates to:
  /// **'Resize split pane'**
  String get resizeSplitPane;

  /// No description provided for @splitPanePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This is a neutral second content slot.'**
  String get splitPanePlaceholder;

  /// No description provided for @shellReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get shellReady;

  /// No description provided for @phoneLayout.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLayout;

  /// No description provided for @desktopLayout.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get desktopLayout;

  /// No description provided for @accentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accentLabel;

  /// No description provided for @resetAppearance.
  ///
  /// In en, this message translates to:
  /// **'Reset appearance'**
  String get resetAppearance;

  /// No description provided for @densityLabel.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get densityLabel;

  /// No description provided for @compactDensity.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compactDensity;

  /// No description provided for @comfortableDensity.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get comfortableDensity;

  /// No description provided for @localStorageNote.
  ///
  /// In en, this message translates to:
  /// **'Settings are stored on this device or browser only.'**
  String get localStorageNote;

  /// No description provided for @resetLayout.
  ///
  /// In en, this message translates to:
  /// **'Reset layout'**
  String get resetLayout;

  /// No description provided for @resetAllPreferences.
  ///
  /// In en, this message translates to:
  /// **'Reset all preferences'**
  String get resetAllPreferences;

  /// No description provided for @resetAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Reset all local template preferences? This cannot be undone.'**
  String get resetAllConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get confirmReset;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @keyboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get keyboardLabel;

  /// No description provided for @shortcutReference.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcutReference;

  /// No description provided for @aboutShell.
  ///
  /// In en, this message translates to:
  /// **'About this shell'**
  String get aboutShell;

  /// No description provided for @textScalingHint.
  ///
  /// In en, this message translates to:
  /// **'System text scaling is always respected.'**
  String get textScalingHint;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @openViewTab.
  ///
  /// In en, this message translates to:
  /// **'Open view'**
  String get openViewTab;

  /// No description provided for @viewPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Open registered view'**
  String get viewPickerTitle;

  /// No description provided for @viewPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Search registered views'**
  String get viewPickerHint;

  /// No description provided for @openTabOverflow.
  ///
  /// In en, this message translates to:
  /// **'Find open tab'**
  String get openTabOverflow;

  /// No description provided for @tabOverflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Open tabs'**
  String get tabOverflowTitle;

  /// No description provided for @noTabsOpen.
  ///
  /// In en, this message translates to:
  /// **'No views are open.'**
  String get noTabsOpen;

  /// No description provided for @closeOtherTabs.
  ///
  /// In en, this message translates to:
  /// **'Close other tabs'**
  String get closeOtherTabs;

  /// No description provided for @closeTabsToRight.
  ///
  /// In en, this message translates to:
  /// **'Close tabs to the right'**
  String get closeTabsToRight;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @openNotifications.
  ///
  /// In en, this message translates to:
  /// **'Open notifications'**
  String get openNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @dismissNotification.
  ///
  /// In en, this message translates to:
  /// **'Dismiss notification'**
  String get dismissNotification;

  /// No description provided for @clearNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearNotifications;

  /// No description provided for @notificationAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationAction;

  /// No description provided for @notificationInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get notificationInfo;

  /// No description provided for @notificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get notificationSuccess;

  /// No description provided for @notificationWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get notificationWarning;

  /// No description provided for @notificationError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get notificationError;

  /// No description provided for @notificationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications stay in memory and are cleared when the app closes.'**
  String get notificationPrivacyNote;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get settingsLayout;

  /// No description provided for @settingsNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get settingsNavigation;

  /// No description provided for @settingsKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get settingsKeyboard;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @shellEmptyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose a registered view to open.'**
  String get shellEmptyWorkspace;

  /// No description provided for @walletPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Placeholder for a wallet-style feature.'**
  String get walletPlaceholderBody;

  /// No description provided for @primaryAction.
  ///
  /// In en, this message translates to:
  /// **'Primary Action'**
  String get primaryAction;

  /// No description provided for @secondaryAction.
  ///
  /// In en, this message translates to:
  /// **'Secondary Action'**
  String get secondaryAction;

  /// No description provided for @primaryActionSnack.
  ///
  /// In en, this message translates to:
  /// **'Replace this with your real action'**
  String get primaryActionSnack;

  /// No description provided for @secondaryActionSnack.
  ///
  /// In en, this message translates to:
  /// **'Another placeholder action'**
  String get secondaryActionSnack;

  /// No description provided for @menuSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Template app settings'**
  String get menuSettingsSubtitle;

  /// No description provided for @menuAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'About this template'**
  String get menuAboutSubtitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'This repository is a mobile app skeleton.\n\nReplace the placeholder pages (Page 1..Page 6) with your own features while keeping the architecture (datasources, repositories, usecases, entities, pages).'**
  String get aboutBody;

  /// No description provided for @serverFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load server data.'**
  String get serverFailureMessage;

  /// No description provided for @generalFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred.'**
  String get generalFailureMessage;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error.'**
  String get errorMessage;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occured...'**
  String get unexpectedError;

  /// No description provided for @invalid2FATokenFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your TOTP is incorrect. Please try again!'**
  String get invalid2FATokenFailureMessage;

  /// No description provided for @invalidLoginIDAndPasswordFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The credentials are invalid!'**
  String get invalidLoginIDAndPasswordFailureMessage;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please login with your username and password.'**
  String get login_prompt;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @empty_input_field.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials!'**
  String get empty_input_field;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid input!'**
  String get login_error;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in!'**
  String get login_success;

  /// No description provided for @login_already.
  ///
  /// In en, this message translates to:
  /// **'Allready logged in.'**
  String get login_already;

  /// No description provided for @enter_totp.
  ///
  /// In en, this message translates to:
  /// **'Please enter your TOTP.'**
  String get enter_totp;

  /// No description provided for @closeUnsavedTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Close modified view?'**
  String get closeUnsavedTabTitle;

  /// No description provided for @closeUnsavedTabMessage.
  ///
  /// In en, this message translates to:
  /// **'Close {title} and discard its unsaved changes?'**
  String closeUnsavedTabMessage(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
