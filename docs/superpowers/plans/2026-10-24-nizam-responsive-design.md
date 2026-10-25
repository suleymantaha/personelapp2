# Nizam responsive design implementation plan

**Goal:** Apply the approved navy/light visual direction to the existing Flutter dashboard on mobile and web, preserving all existing tools and workflows.
**Architecture:** Existing Riverpod session and pending providers and AppNavigator callbacks remain the source of behavior. One typed action registry feeds mobile cards, desktop sidebar and the all-tools sheet. No database, authorization, export or routing contracts change.
**Tech stack:** Existing Flutter 3.47.2, Riverpod, go_router and Material icons; no new dependencies.
**Spec:** User-approved desktop/mobile concepts in this chat; mobile may be improved after source inspection. Fake sample roster data must not appear in the real product.

## Global constraints
- Preserve all eight admin tools and six commander tools, settings, backup/restore and pending approval notice.
- Keep OCR platform warning and role visibility; NÖBET stays inside analytics.
- Preserve user changes to AGENTS.md and docs/bounded-analysis.md.
- No push, merge, deployment, release APK or personal-device data access.

## Review focus
- Small/landscape screens, 2x text scaling and dark mode must scroll without overflow.
- Every actual tool must remain reachable; mobile bottom navigation must invoke real existing destinations.
- Import dialog and settings must retain their original context and Riverpod behavior after closing all-tools sheet.
- Desktop sidebar must not truncate tools on shorter screens.
- No new database subscriptions or mock counts/rosters on dashboard.

## Tasks
- [x] Record baseline dashboard/theme tests and preserve initial Git state.
- [x] Add failing responsive/navigation/role/palette regression tests.
- [x] Extract the existing action callbacks into a typed registry (worker owns models/dashboard_action_item.dart and dashboard_actions.dart only).
- [x] Implement responsive dashboard shell, navy identity, primary schedule card, grouped tools, mobile bottom navigation and desktop sidebar (primary owns remaining source/tests/theme).
- [x] Format, analyze, run focused and full regression tests; attempt web build (blocked by existing native database imports).
- [x] Render and inspect real Flutter mobile/desktop widget views and exercise navigation; independently review combined diff. Browser runtime blocked by native database.
- [x] Record tested revision/hash manifest and remaining limitations.
