# Modern Dashboard Design

## Goal

Modernize the existing Nizam dashboard using the selected third visual direction: a compact, balanced two-column action grid with a full-width archive action. Preserve all current workflows, role-based visibility, routes, Turkish copy, and the military-olive product identity.

## Source Of Truth

- Current screen: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Current action card: `lib/features/dashboard/presentation/widgets/dashboard_menu_card.dart`
- Current layout logic: `lib/features/dashboard/presentation/widgets/dashboard_grid_layout.dart`
- Existing theme: `lib/core/theme/app_theme.dart`
- Existing spacing scale: `lib/core/theme/spacing.dart`
- Visual target: the third generated Product Design option selected by the user on 2026-08-07.
- Original reference: `C:\Users\baba\Desktop\Screenshot_1786134588.png`

The selected visual target wins for hierarchy, density, card treatment, and archive placement. Existing code wins for routes, permissions, data loading, settings behavior, dark mode, and business logic.

## Scope

### Included

- Redesign only the dashboard presentation layer.
- Keep the `Nizam` app bar and settings action.
- Keep the `İşlemler` section heading.
- Keep the seven existing admin actions and their current destinations.
- Keep the five non-admin actions and role-dependent subtitle for `Personel & Tim`.
- Keep the pending-assignment warning banner for admins when pending data is non-empty.
- Preserve the bulk-import dialog flow and repository invalidation.
- Preserve light and dark themes.
- Improve mobile density while retaining responsive behavior on larger widths.
- Add focused widget tests for layout, role visibility, semantics, and interactions.

### Excluded

- New routes, workflows, metrics, charts, navigation bars, or backend behavior.
- Changes to authentication, repositories, databases, exports, or settings content.
- A redesign of destination screens.
- A complete application-wide design-system refactor.
- Figma mutations before a target Figma file is supplied and Phase 0 discovery is approved.

## Visual Direction

### Page Structure

1. Use the existing scaffold and app bar behavior.
2. Present the `İşlemler` heading with stronger spacing and typography than the current screen.
3. Show the six primary admin actions in a compact two-column grid:
   - Faaliyet Çizelgesi
   - Aylık Matris
   - TEMGÜNDRAP
   - Personel & Tim
   - Metinden Toplu Aktar
   - Bekleyen Onaylar
4. Show `Faaliyet Arşivi` below the grid as a full-width horizontal action row.
5. For non-admin users, render the four grid actions in two complete rows, then place `Faaliyet Arşivi` full width. Do not leave an empty grid cell.
6. Allow vertical scrolling when the pending warning, text scale, or compact viewport makes the content taller than the screen.

### Hierarchy

- `Faaliyet Çizelgesi` is the primary tile and receives the strongest olive outline/tint.
- Standard planning and personnel tiles use restrained neutral/olive surfaces.
- `Metinden Toplu Aktar` uses the existing blue semantic accent.
- `Bekleyen Onaylar` uses the existing amber semantic accent.
- `Faaliyet Arşivi` is lower emphasis and horizontally arranged with a trailing chevron.
- Every action remains clearly enabled; semantic color differences must not make neutral tiles appear disabled.

### Card Treatment

- Use compact cards with consistent internal alignment: icon container, title, then subtitle.
- Use a 16 px visual radius for dashboard action surfaces.
- Use subtle tonal backgrounds and thin borders; avoid heavy elevation.
- Keep at least 12 px between cards and at least 16 px page padding on normal phones.
- Keep titles to two lines and subtitles to two lines without clipping at supported text scales.
- Use Material icons already available through Flutter; do not introduce image assets or custom SVG icons.

### Typography

- Continue using the app's current Material typography and bundled Roboto assets.
- Use a clear title hierarchy rather than introducing a second font.
- Dashboard action titles use a semibold or bold weight.
- Subtitles use the theme's secondary text color and remain readable in both themes.

## Theme And Tokens

Reuse the existing values in `AppColors` and `AppSpacing` wherever they match the target. Add dashboard-specific semantic getters or narrowly scoped constants only when the current theme cannot express the selected design.

Required semantic roles:

- dashboard page background
- dashboard primary tile background, border, icon background, and content color
- dashboard neutral tile background, border, icon background, and content color
- dashboard import tile background, border, icon background, and content color
- dashboard pending tile background, border, icon background, and content color
- dashboard archive row background, border, icon background, and content color

Dark mode must map the same roles to existing dark surfaces and accessible accent colors. Raw colors must not be duplicated inside individual widgets when a theme role can represent them.

## Component Architecture

### DashboardScreen

Responsibilities:

- Read session and pending-assignment state.
- Define action data and retain existing callbacks.
- Render the warning banner, section heading, responsive action grid, and archive row.
- Keep business logic out of the visual components.

### DashboardActionItem

Introduce a small immutable view model owned by the dashboard presentation layer with:

- `IconData icon`
- `String title`
- `String subtitle`
- `DashboardActionTone tone`
- `VoidCallback onTap`

This model removes repeated widget construction from `DashboardScreen` without moving navigation or repository behavior into a global service.

### DashboardMenuCard

Keep this as the reusable grid tile. Extend it to consume a semantic tone rather than a raw color. It owns:

- compact vertical layout
- icon container
- title and subtitle typography
- border, surface, and interaction states
- tooltip/semantics label
- responsive padding and text overflow behavior

### DashboardArchiveAction

Add a dedicated horizontal action widget for the full-width archive row. It owns:

- leading archive icon container
- title and subtitle column
- trailing chevron
- full-row tap and semantic behavior

This avoids forcing one component to support unrelated vertical-card and horizontal-row layouts.

### DashboardGridLayout

Simplify this helper to calculate column count and fixed/controlled card extent for the grid actions only. The archive action is excluded from grid calculations. Mobile uses two columns; wider layouts may use three columns when minimum card width and readable text constraints are satisfied.

## Data And Interaction Flow

1. `DashboardScreen` reads `userSessionProvider` and `pendingAssignmentsProvider` exactly as it does now.
2. Role state determines which action models are included.
3. Tapping a route action calls the existing `GoRouter` path.
4. Tapping bulk import opens the existing `BulkImportDialog`; after dismissal, the existing repository invalidation runs.
5. Tapping settings opens the existing settings bottom sheet.
6. Pending-data loading and errors stay visually silent, matching current behavior; a non-empty result renders the existing warning action above the dashboard grid.

No new state management or persistence is introduced.

## Responsive Behavior

- Small and standard phones: two grid columns.
- Narrow phones and large accessibility text: retain two columns when readable; allow cards to grow vertically and the page to scroll.
- Tablet/desktop widths: use up to three columns inside the existing `ResponsiveCenter` content width.
- The archive action always spans the available content width.
- The warning banner always spans the available content width.
- Do not use `NeverScrollableScrollPhysics` for the page-level dashboard content.

## Accessibility

- Every action has a minimum 48 px touch target.
- Every card exposes one concise semantic button label combining title and subtitle.
- Decorative chevrons are excluded from semantics.
- Focus, hover, pressed, and splash states remain visible.
- Text contrast meets WCAG AA for normal text in light and dark themes.
- Semantic blue and amber are not the only signals; labels and icons remain present.
- Layout remains usable at increased text scale without clipping or inaccessible actions.

## Error And Empty States

- Pending-assignment loading and failure continue to omit the warning banner; the rest of the dashboard remains usable.
- An empty pending list shows no warning banner.
- Navigation and dialog errors remain owned by their existing destination workflows.
- The dashboard redesign must not add placeholder, skeleton, or retry UI that implies unsupported behavior.

## Testing Strategy

### Unit Tests

- Verify `DashboardGridLayout` returns two columns for phone widths and no more than three for supported wide layouts.
- Verify card sizing remains finite for constrained heights and large text layouts.

### Widget Tests

- Admin dashboard shows all seven actions.
- Non-admin dashboard hides bulk import and pending approvals and shows five actions.
- Archive renders as a full-width action outside the grid.
- Settings action retains its tooltip and opens the settings surface.
- Each route action invokes the expected navigation callback or route.
- Bulk import retains the dialog path.
- Pending warning appears only for a non-empty admin result.
- Light and dark themes render without overflow at the target mobile viewport.
- Increased text scale renders without clipped titles or inaccessible actions.

### Visual Verification

- Capture the implemented dashboard at the same mobile viewport as the selected visual target.
- Compare the selected target and implementation side by side.
- Fix all layout, spacing, typography, color, border, and radius mismatches rated P0-P2.
- Record Product Design QA in `design-qa.md`; handoff requires `final result: passed`.

## Figma Library Follow-Up

Figma library work is a separate, sequential deliverable after the Flutter design specification is approved. Phase 0 will:

- inspect the target Figma file without mutations
- extract the finalized Flutter color, spacing, radius, and typography roles
- search available Figma libraries before creating components
- map code tokens to Figma variables
- define the v1 component scope as Dashboard Menu Card, Dashboard Archive Action, App Bar action, and Pending Warning Banner
- report gaps and conflicts for approval before creating variables or components

The user must provide an editable Figma file URL or identify an existing connected Figma file before Phase 0 can complete.

## Acceptance Criteria

- The dashboard visually follows the selected third option.
- All existing admin and non-admin actions remain reachable.
- Existing routes, dialog behavior, settings, providers, and repository invalidation remain unchanged.
- Admin layout has six compact grid tiles plus a full-width archive row.
- Non-admin layout has four compact grid tiles plus a full-width archive row.
- The page scrolls safely when content exceeds the viewport.
- Light theme, dark theme, and increased text scale have no overflow.
- Static analysis and dashboard tests pass.
- Product Design visual QA passes before handoff.
