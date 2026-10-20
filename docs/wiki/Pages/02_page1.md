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

