# Pages Overview

The template contains six example destinations, `page1` through `page6`. Each destination has a default registered view that can be opened in a workspace tab. Destination navigation and tabs are independent: a page may add nested navigation items without creating a tab for every item.

Most examples demonstrate the same feature pattern:

- UI in `lib/pages/pageN/pageN_page.dart`
- A `DataSource` that simulates I/O
- A `Repository` that wraps the datasource
- A `Usecases` class that the UI calls

Replace `page1` to `page6` with your actual features, keeping the folder structure if it works for your team. The shell also registers `profile` and `settings` utility destinations.

