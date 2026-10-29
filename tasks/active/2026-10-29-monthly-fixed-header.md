# Scrollable daily list with fixed summary

User approved the daily detail concept, replaced pagination with vertical list scrolling, and explicitly requested fixed date, person/assignment cards and tabs, then emulator verification. Excel work canceled for this follow-up.

Implementation: bounded modal height, fixed header containing date/status, responsive person/assignment cards, team count and tabs. Only Expanded ListView scrolls. Owned ScrollController is disposed and resets on tab selection. Narrow/large text uses shorter visible labels with full accessible units; duplicate screen reader content excluded.

Regression: at320px/2x, scroll to last team heading, ensure visible, and compare fixed header/card coordinates before/after. Independent source review clear after semantics duplication fix. Domain/calculation behavior unchanged from previous work.

Runtime: separate QA harness with lib/assets/integration/test-driver directory junctions to actual sources, distinct application ID com.example.personelapp2.analyticsqa on verified nizam-nobet-test/emulator-5554. Original application package not updated or cleared. Synthetic fixture only. Screenshots/logs output/monthly-visual-qa/.

Checks so far: analytics79PASS; final dedicated sheet4PASS; scoped analyze clean. Android final rerun pending. Earlier harness issues: tinyviewport used separate numeric/unit text (assertions now scope visible sheet and full accessible labels), test scrolling aligned target center. No production behavior bypassed.

Status: COMPLETE, verified 2026-10-30 Europe/Istanbul. Analytics79PASS; finalsheet4PASS; scopedanalyzeclean; AndroidintegrationPASS with listoffset/header+KPIcoordinate assertions. Actual emulator screenshots viewed, nooverflow. Independent source review clear. Interactive preview opened separately from integration-test mode. Evidence docs/verification/monthly-fixed-header-2026-10-30.md. No commit/push/release.
