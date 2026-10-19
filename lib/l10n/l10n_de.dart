// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get helloWorld => 'Hallo Welt!';

  @override
  String get appTitle => 'Template App';

  @override
  String get page1Title => 'Seite 1';

  @override
  String get page2Title => 'Seite 2';

  @override
  String get page3Title => 'Seite 3';

  @override
  String get page4Title => 'Seite 4';

  @override
  String get page5Title => 'Seite 5';

  @override
  String get page6Title => 'Seite 6';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get aboutTitle => 'Ueber';

  @override
  String get detailTitle => 'Details';

  @override
  String get searchLabel => 'Suchen';

  @override
  String get back => 'Zurueck';

  @override
  String get next => 'Weiter';

  @override
  String get finish => 'Fertig';

  @override
  String get onboardingIntroBody =>
      'Dies ist eine Skeleton-App, die Architektur und UI-Shell beibehält.';

  @override
  String get onboardingIntroHint =>
      'Ersetze \"Page 1..Page 6\" durch deine eigenen Features.';

  @override
  String get onboardingPreferencesTitle => 'Einstellungen';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get accessibilityLabel => 'Barrierefreiheit';

  @override
  String get useSystemTextScaling => 'System-Textskalierung verwenden';

  @override
  String get navigationLabel => 'Navigation';

  @override
  String get navigationOrderHint =>
      'Menuepunkte per Drag-and-drop neu anordnen.';

  @override
  String get navigationVisibilityLabel => 'In der Navigation anzeigen';

  @override
  String get navigationSettingsAlwaysVisibleHint =>
      'Seite 6 bleibt sichtbar, damit Einstellungen erreichbar bleiben.';

  @override
  String get currentPageLabel => 'Aktuelle Seite';

  @override
  String get shellPlaceholderTab => 'Platzhalter';

  @override
  String get shellPlaceholderBody =>
      'Dieser Tab ist ein neutraler Inhaltsbereich. Registriere einen View-Builder, um App-Inhalte bereitzustellen.';

  @override
  String get inspectorEmpty => 'Es ist kein Inspector-Inhalt registriert.';

  @override
  String get loading => 'Wird geladen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get shellMissingRoute => 'Dieses Ziel ist nicht verfügbar.';

  @override
  String get shellNoDestinations => 'Es sind keine Ziele registriert.';

  @override
  String shellContentError(String details) {
    return 'Dieser Inhalt konnte nicht angezeigt werden: $details';
  }

  @override
  String get shellMissingView => 'Diese Ansicht ist nicht verfügbar.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get openInspector => 'Inspector öffnen';

  @override
  String get closeInspector => 'Inspector schließen';

  @override
  String get restoreLayout => 'Standardlayout wiederherstellen';

  @override
  String get openSplitView => 'Geteilte Ansicht öffnen';

  @override
  String get closeSplitView => 'Geteilte Ansicht schließen';

  @override
  String get toggleAppearance => 'Helles oder dunkles Design wechseln';

  @override
  String get addPlaceholderTab => 'Platzhalter-Tab hinzufügen';

  @override
  String openView(String view) {
    return 'Ansicht öffnen: $view';
  }

  @override
  String navigateTo(String destination) {
    return 'Zu $destination wechseln';
  }

  @override
  String get selectContext => 'Kontext auswählen';

  @override
  String get selectModule => 'Modul auswählen';

  @override
  String switchContext(String context) {
    return 'Kontext wechseln: $context';
  }

  @override
  String switchModule(String module) {
    return 'Modul wechseln: $module';
  }

  @override
  String get commandPalette => 'Befehlspalette';

  @override
  String get commandPaletteHint => 'Shell-Befehle suchen';

  @override
  String get switchView => 'Ansicht wechseln';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get reorderTab => 'Zum Neuordnen ziehen';

  @override
  String get tabActions => 'Tab-Aktionen';

  @override
  String get moveLeft => 'Tab nach links verschieben';

  @override
  String get moveRight => 'Tab nach rechts verschieben';

  @override
  String get closeTab => 'Tab schließen';

  @override
  String get inspector => 'Inspector';

  @override
  String get resizeInspector => 'Inspector-Größe ändern';

  @override
  String get resizeSplitPane => 'Geteilten Bereich skalieren';

  @override
  String get splitPanePlaceholder =>
      'Dies ist ein neutraler zweiter Inhaltsbereich.';

  @override
  String get shellReady => 'Bereit';

  @override
  String get phoneLayout => 'Telefon';

  @override
  String get desktopLayout => 'Desktop';

  @override
  String get accentLabel => 'Akzentfarbe';

  @override
  String get resetAppearance => 'Darstellung zurücksetzen';

  @override
  String get densityLabel => 'Abstände';

  @override
  String get compactDensity => 'Kompakt';

  @override
  String get comfortableDensity => 'Komfortabel';

  @override
  String get localStorageNote =>
      'Einstellungen werden nur auf diesem Gerät oder in diesem Browser gespeichert.';

  @override
  String get resetLayout => 'Layout zurücksetzen';

  @override
  String get resetAllPreferences => 'Alle Einstellungen zurücksetzen';

  @override
  String get resetAllConfirmation =>
      'Alle lokalen Template-Einstellungen zurücksetzen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirmReset => 'Zurücksetzen';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get keyboardLabel => 'Tastatur';

  @override
  String get shortcutReference => 'Tastenkürzel';

  @override
  String get aboutShell => 'Über diese Shell';

  @override
  String get textScalingHint =>
      'Die System-Textskalierung wird immer berücksichtigt.';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get openViewTab => 'Ansicht öffnen';

  @override
  String get viewPickerTitle => 'Registrierte Ansicht öffnen';

  @override
  String get viewPickerHint => 'Registrierte Ansichten suchen';

  @override
  String get openTabOverflow => 'Offenen Tab suchen';

  @override
  String get tabOverflowTitle => 'Offene Tabs';

  @override
  String get noTabsOpen => 'Es sind keine Ansichten geöffnet.';

  @override
  String get closeOtherTabs => 'Andere Tabs schließen';

  @override
  String get closeTabsToRight => 'Tabs rechts schließen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get openNotifications => 'Benachrichtigungen öffnen';

  @override
  String get noNotifications => 'Keine Benachrichtigungen';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get dismissNotification => 'Benachrichtigung schließen';

  @override
  String get clearNotifications => 'Alle löschen';

  @override
  String get notificationAction => 'Öffnen';

  @override
  String get notificationInfo => 'Information';

  @override
  String get notificationSuccess => 'Erfolg';

  @override
  String get notificationWarning => 'Warnung';

  @override
  String get notificationError => 'Fehler';

  @override
  String get notificationPrivacyNote =>
      'Benachrichtigungen bleiben im Speicher und werden beim Schließen der App gelöscht.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsLayout => 'Layout';

  @override
  String get settingsNavigation => 'Navigation';

  @override
  String get settingsKeyboard => 'Tastatur';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsAbout => 'Über';

  @override
  String get shellEmptyWorkspace =>
      'Wähle eine registrierte Ansicht zum Öffnen.';

  @override
  String get walletPlaceholderBody =>
      'Platzhalter fuer eine Wallet-aehnliche Funktion.';

  @override
  String get primaryAction => 'Primaere Aktion';

  @override
  String get secondaryAction => 'Sekundaere Aktion';

  @override
  String get primaryActionSnack => 'Ersetze das durch deine echte Aktion';

  @override
  String get secondaryActionSnack => 'Noch eine Platzhalter-Aktion';

  @override
  String get menuSettingsSubtitle => 'Einstellungen der Template-App';

  @override
  String get menuAboutSubtitle => 'Ueber dieses Template';

  @override
  String get aboutBody =>
      'Dieses Repository ist ein Mobile-App-Skeleton.\n\nErsetze die Platzhalter-Seiten (Page 1..Page 6) durch deine eigenen Features und behalte dabei die Architektur (Datasources, Repositories, Usecases, Entities, Pages) bei.';

  @override
  String get serverFailureMessage =>
      'Serverdaten konnten nicht geladen werden.';

  @override
  String get generalFailureMessage => 'Ein Fehler ist aufgetreten.';

  @override
  String get errorMessage => 'Fehler.';

  @override
  String get unexpectedError => 'Ein unerwarteter Fehler ist aufgetreten...';

  @override
  String get invalid2FATokenFailureMessage =>
      'Dein Einmalcode (TOTP) is ungültig. Bitte versuche es erneut!';

  @override
  String get invalidLoginIDAndPasswordFailureMessage =>
      'Die Anmeldedaten sind ungültig!';

  @override
  String get welcome => 'Willkommen!';

  @override
  String get login_prompt =>
      'Bitte melde dich mit deinem Benutzernamen und deinem Passwort an.';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get login => 'Anmelden';

  @override
  String get empty_input_field => 'Bitte gib deine Anmeldedaten ein!';

  @override
  String get login_error => 'Ungültige Eingabe!';

  @override
  String get login_success => 'Erfolgreich angemeldet!';

  @override
  String get login_already => 'Du bist bereits angemeldet.';

  @override
  String get enter_totp => 'Bitte gib deinen Einmalcode (TOTP) ein.';

  @override
  String get inspectorWorkspace => 'Arbeitsbereich';

  @override
  String get inspectorSelection => 'Auswahl';

  @override
  String get inspectorSection => 'Bereich';

  @override
  String get inspectorOpenTabs => 'Offene Tabs';

  @override
  String get inspectorView => 'Ansicht';

  @override
  String get inspectorInstance => 'Instanz';

  @override
  String get inspectorEmptyState => 'Kein Tab ist aktiv.';

  @override
  String get renameTab => 'Tab umbenennen';

  @override
  String get tabTitleLabel => 'Tab-Name';

  @override
  String get save => 'Speichern';

  @override
  String get openSectionPanel => 'Bereichsfenster öffnen';

  @override
  String get closeSectionPanel => 'Bereichsfenster schließen';

  @override
  String get closeUnsavedTabTitle => 'Geänderte Ansicht schließen?';

  @override
  String closeUnsavedTabMessage(String title) {
    return '$title schließen und ungespeicherte Änderungen verwerfen?';
  }

  @override
  String get account => 'Konto';

  @override
  String get guestNotSignedIn => 'Gast · Nicht angemeldet';

  @override
  String get signIn => 'Anmelden';

  @override
  String get profile => 'Profil';

  @override
  String get signOut => 'Abmelden';

  @override
  String get authenticationUnavailable =>
      'Die Anmeldung ist für diese Anwendung nicht eingerichtet. Du kannst die App als Gast weiter nutzen.';

  @override
  String get returnToApp => 'Zur App';

  @override
  String get signInPrompt => 'Melde dich bei deinem Konto an';

  @override
  String get emailOrUsername => 'E-Mail oder Benutzername';

  @override
  String get requiredField => 'Dieses Feld ist erforderlich.';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get authenticationFailed =>
      'Die Anmeldung war nicht möglich. Prüfe deine Angaben und versuche es erneut.';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get continueAsGuest => 'Als Gast fortfahren';

  @override
  String get profileGuestMessage =>
      'Es ist kein Konto verbunden. Dein Arbeitsbereich bleibt im Gastmodus verfügbar.';

  @override
  String get accountIdentifier => 'Konto-ID';

  @override
  String get userIdentifier => 'Benutzer-ID';

  @override
  String get authenticationProvider => 'Anmeldeanbieter';

  @override
  String get signOutFailed =>
      'Die Abmeldung war nicht möglich. Bitte versuche es erneut.';

  @override
  String get returnToPreviousSection => 'Zum vorherigen Bereich zurückkehren';

  @override
  String get sessionExpired =>
      'Deine Sitzung ist abgelaufen. Melde dich erneut an.';

  @override
  String get checkingSession => 'Konto wird geprüft …';
}
