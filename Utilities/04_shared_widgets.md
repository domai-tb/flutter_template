# Shared Widgets

Cross-feature widgets live in:

- `lib/widgets/`

The goal is to keep page modules small and avoid duplicating UI components across features.

App-shell components live separately in `lib/pages/home/widgets/`. That folder contains destination navigation, the tab strip, status and notification UI, breadcrumb menus, and right-sidebar sections. Shell pages should use the controllers in `ShellViewContext` instead of importing those shell widgets directly.

## Included Examples

- Buttons: `app_button.dart`
- Icon button: `app_icon_button.dart`
- Search bar: `app_search_bar.dart`
- Segmented control: `app_segmented_triple_control.dart`
- Scroll-to-top FAB: `scroll_to_top_button.dart`

If a widget is only used by a single feature, keep it inside that feature folder instead.

