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

# Pages Overview

The template contains six example destinations, `page1` through `page6`. Each destination has a default registered view that can be opened in a workspace tab. Destination navigation and tabs are independent: a page may add nested navigation items without creating a tab for every item.

Each feature keeps its main files flat and adds subfolders only when useful:

- Page in `lib/pages/pageN/pageN_page.dart`
- Data access in `lib/pages/pageN/pageN_datasource.dart`
- Repository in `lib/pages/pageN/pageN_repository.dart`
- Singular use case in `lib/pages/pageN/pageN_usecase.dart`
- Optional entities in `lib/pages/pageN/entities/`
- Optional feature-only widgets in `lib/pages/pageN/widgets/`

Datasources and repositories are the Data layer. Use cases and entities are the Domain layer. Pages and presentation controllers are the Presentation layer. Page 1 stores its item model in `lib/pages/page1/entities/item_entity.dart`.

Replace `page1` to `page6` with your actual feature names. The shell also registers `profile` and `settings` utility destinations.


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

# Page 1

Demonstrates:

- Loading placeholder items through a use case
- Pull-to-refresh
- A search UI
- Navigating to a detail page
- A scroll-to-top floating action button
- A per-tab hierarchical breadcrumb tree with Overview, Items (All Items and Recent Items), and Reports (Summary)
- A contextual right-sidebar section for the selected item; opening an item opens the sidebar and focuses that section

The shell renders the active breadcrumb path in its bottom status bar. Clicking a breadcrumb label opens that node's child menu; children with their own children open nested menus. Selecting a leaf updates the page path. Page 1 registers its nodes with `ShellNavigationNode` and `view.breadcrumbs`, so another tab can keep its own navigation path.

Page-provided sidebar content uses the `ShellViewContext.rightSidebar` controller. Register sections with `setSections(...)`, update the selection label with `setSelection(...)`, and call `focusSection(id)` when the page needs the sidebar to open at a particular section.

Files:

- `lib/pages/page1/page1_page.dart`
- `lib/pages/page1/page1_detail_page.dart`
- `lib/pages/page1/page1_usecase.dart`
- `lib/pages/page1/entities/item_entity.dart`
- `lib/pages/page1/page1_repository.dart`
- `lib/pages/page1/page1_datasource.dart`


---

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

