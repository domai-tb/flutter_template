# Page 2

Demonstrates:

- A list-style page with pull-to-refresh
- Using localization for the page title
- Scroll-to-top FAB support for long lists

Files:

- `lib/pages/page2/page2_page.dart`
- `lib/pages/page2/page2_usecase.dart`
- `lib/pages/page2/entities/item_entity.dart`
- `lib/pages/page2/page2_repository.dart`
- `lib/pages/page2/page2_datasource.dart`


---

# Page 3

Demonstrates:

- A simple list with placeholder content
- Pull-to-refresh and scroll-to-top behavior

Files:

- `lib/pages/page3/page3_page.dart`
- `lib/pages/page3/page3_usecase.dart`
- `lib/pages/page3/entities/item_entity.dart`
- `lib/pages/page3/page3_repository.dart`
- `lib/pages/page3/page3_datasource.dart`


---

# Page 6

Demonstrates:

- A simple menu list
- Navigation to Settings and About sub-pages

The shell also registers Settings as a dedicated utility destination. Its settings screen demonstrates:

- Theme, accent, and density preferences
- Language and text-scaling preferences
- Navigation visibility and ordering
- Persisted onboarding state

Files:

- `lib/pages/page6/page6_page.dart`
- `lib/pages/page6/page6_usecase.dart`
- `lib/pages/page6/entities/item_entity.dart`
- `lib/pages/page6/page6_settings_page.dart`
- `lib/pages/page6/page6_about_page.dart`


---

# Page 1

Demonstrates:

- Loading placeholder items through a use case
- Pull-to-refresh
- A search UI
- Navigating to a detail page
- A scroll-to-top floating action button
- A per-tab hierarchical breadcrumb tree with Overview, Items (All Items and Recent Items), and Reports (Summary)
- A contextual right-sidebar section for the selected item; opening an item opens the sidebar and focuses that section

The shell renders the active breadcrumb path in its bottom status bar. Clicking a breadcrumb label opens its child menu; nested children open further menus. Selecting a leaf updates the path saved for that tab. Page 1 registers nodes with `ShellNavigationNode` through `view.breadcrumbs`.

Page-provided sidebar content uses `ShellViewContext.rightSidebar`. Register sections with `setSections(...)`, update the selection label with `setSelection(...)`, and call `focusSection(id)` to open the sidebar and focus a registered section.

Files:

- `lib/pages/page1/page1_page.dart`
- `lib/pages/page1/page1_detail_page.dart`
- `lib/pages/page1/page1_usecase.dart`
- `lib/pages/page1/entities/item_entity.dart`
- `lib/pages/page1/page1_repository.dart`
- `lib/pages/page1/page1_datasource.dart`


---

# Pages Overview

This directory contains short guides for the six example features. See the main [Pages overview](../Pages.md) for the feature folder layout, architecture, and shell behavior.

Each destination has a default view that can open in a workspace tab. Navigation within a page is independent of tab creation. The shell also includes Profile and Settings utility destinations.

- [Page 1](02_page1.md) demonstrates hierarchical navigation and page-owned right-sidebar sections.
- [Page 2](03_page2.md)
- [Page 3](04_page3.md)
- [Page 4](05_page4.md)
- [Page 5](06_page5.md)
- [Page 6](07_page6.md)


---

# Page 4

Demonstrates:

- Another list page variant
- Placeholder rows with a trailing value
- Pull-to-refresh and scroll-to-top behavior

Files:

- `lib/pages/page4/page4_page.dart`
- `lib/pages/page4/page4_usecase.dart`
- `lib/pages/page4/entities/item_entity.dart`
- `lib/pages/page4/page4_repository.dart`
- `lib/pages/page4/page4_datasource.dart`


---

# Page 5

Demonstrates:

- A scrollable page built with `ListView` (not `ListView.builder`)
- Buttons and placeholder actions
- Pull-to-refresh and scroll-to-top behavior

Files:

- `lib/pages/page5/page5_page.dart`
- `lib/pages/page5/page5_usecase.dart`
- `lib/pages/page5/entities/item_entity.dart`
- `lib/pages/page5/page5_repository.dart`
- `lib/pages/page5/page5_datasource.dart`


---

