# Flutter Mobile App Skeleton

This repository is a Flutter mobile app template that preserves an opinionated app shell:
- Home page with bottom navigation (and tablet side navigation).
- Clean-ish feature structure: datasources, repositories, usecases, entities, pages.
- Placeholder features named `Page 1` through `Page 6`.

## Structure
- `lib/pages/page1` ... `lib/pages/page6`: feature placeholders
- `lib/core`: app-wide concerns (settings, theme, DI)
- `lib/utils/widgets`: reusable UI building blocks

## Replace Placeholders
1. Pick a page folder (e.g. `lib/pages/page1`).
2. Replace the datasource/repository/usecases/entity/page with your real implementation.
3. Keep the public surface area similar so the navigation shell stays stable.

## License
See `LICENSE`.
