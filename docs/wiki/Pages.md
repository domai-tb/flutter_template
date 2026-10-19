# Pages Overview

The template contains 6 placeholder tabs. Each tab demonstrates the same basic pattern:

- UI in `lib/pages/pageN/pageN_page.dart`
- A `DataSource` that simulates I/O
- A `Repository` that wraps the datasource
- A `Usecases` class that the UI calls

Replace `page1` to `page6` with your actual features, keeping the folder structure if it works for your team.


---

# Page 1

Demonstrates:

- Loading placeholder items through `Usecases`
- Pull-to-refresh
- A search UI
- Navigating to a detail page
- A scroll-to-top floating action button

Files:

- `lib/pages/page1/page1_page.dart`
- `lib/pages/page1/page1_detail_page.dart`
- `lib/pages/page1/page1_usecases.dart`
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
- `lib/pages/page2/page2_usecases.dart`
- `lib/pages/page2/page2_repository.dart`
- `lib/pages/page2/page2_datasource.dart`


---

# Page 3

Demonstrates:

- A simple list with placeholder content
- Pull-to-refresh and scroll-to-top behavior

Files:

- `lib/pages/page3/page3_page.dart`
- `lib/pages/page3/page3_usecases.dart`
- `lib/pages/page3/page3_repository.dart`
- `lib/pages/page3/page3_datasource.dart`


---

# Page 4

Demonstrates:

- Another list page variant
- Placeholder rows with a trailing value
- Pull-to-refresh and scroll-to-top behavior

Files:

- `lib/pages/page4/page4_page.dart`
- `lib/pages/page4/page4_usecases.dart`
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
- `lib/pages/page5/page5_usecases.dart`
- `lib/pages/page5/page5_repository.dart`
- `lib/pages/page5/page5_datasource.dart`


---

# Page 6

Demonstrates:

- A simple menu list
- Navigation to Settings and About sub-pages

The Settings screen also demonstrates:

- Theme selection
- Language selection (English/German/System)
- A persisted onboarding flag

Files:

- `lib/pages/page6/page6_page.dart`
- `lib/pages/page6/page6_settings_page.dart`
- `lib/pages/page6/page6_about_page.dart`


---

