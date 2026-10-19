# Page 1

Demonstrates:

- Loading placeholder items through `Usecases`
- Pull-to-refresh
- A search UI
- Navigating to a detail page
- A scroll-to-top floating action button
- A per-tab hierarchical breadcrumb tree with Overview, Items (All Items and Recent Items), and Reports (Summary)
- A contextual right-sidebar section for the selected item; opening an item opens the sidebar and focuses that section

The shell renders the active breadcrumb path in its footer. Clicking a breadcrumb label opens that node's child menu; selecting a child reveals the next level and updates the page path. Page 1 registers its nodes with `ShellNavigationNode` and `view.breadcrumbs`, so another tab can keep its own navigation path.

Page-provided sidebar content uses the `ShellViewContext.rightSidebar` controller. Register sections with `setSections(...)`, update the selection label with `setSelection(...)`, and call `focusSection(id)` when the page needs the sidebar to open at a particular section.

Files:

- `lib/pages/page1/page1_page.dart`
- `lib/pages/page1/page1_detail_page.dart`
- `lib/pages/page1/page1_usecases.dart`
- `lib/pages/page1/page1_repository.dart`
- `lib/pages/page1/page1_datasource.dart`

