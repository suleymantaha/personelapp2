# Bulk Text Parser Robustness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance `BulkTextParser` to flawlessly parse complex, real-world WhatsApp/Telegram duty rosters containing multi-personnel lines, non-standard shift times, sub-location notes, abbreviated ranks, and non-standard team formats without raising false personnel errors or losing personnel data.

**Architecture:** Refactor `BulkTextParser` tokenization & regex rules with multi-line splitting, expanded rank patterns (`J.Asb.Ü.Çvş.`), flexible time range patterns (`08:00 20:00`), parenthetical location & note filtering, team normalization (`3B-` → `3/B`), and shift block splitting.

**Tech Stack:** Dart, Flutter Test, RegEx, `personelapp2` domain parser.

---

## User Review Required

> [!IMPORTANT]
> - All 19 shift blocks from the provided raw text paste will be cleanly parsed without raising false "personnel satırı çözümlenemedi" or "unknown rank" errors for note lines.
> - Multi-personnel lines (such as `5. J.Uzm.Çvş. Yusuf TUŞ 6.J.Uzm.Çvş. Ertuğrul BAĞCI`) will be automatically split into individual personnel entries.
> - Non-standard shift time ranges (such as `08:00 20:00`) will be correctly recognized as shift headers instead of invalid personnel lines.
> - Location notes (such as `(Altın Kaz çiftliği)`) and footer instructions (such as `*Sabit kalınacak*`) will be filtered out from personnel lists.

---

## Proposed Changes

### Domain / Parser Layer

#### [MODIFY] [bulk_text_parser.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/domain/parser/bulk_text_parser.dart)
- Update `_rankPattern` to match abbreviated ranks like `J.Asb.Ü.Çvş.`, `J.Asb.Kd.Çvş.`, `J.Tğm.`, `J.Ütğm.`, and missing dots (`J Uzm Çvş`).
- Update `_normalizeRank()` to map `Ü.Çvş.` to `J.Asb.Üçvş.` and handle all rank variations consistently.
- Update `_timeRangePattern` and `_timeLikePattern` to support space-separated time ranges (`08:00 20:00`, `20:00 08:00`, `08.00 19.30`).
- Update `_numberedPersonnelPattern` to support numbers immediately followed by `J.` or `J` without punctuation (e.g. `10J.Uzm.Çvş.`).
- Add `_splitLineIfMultiplePersonnel(String line)` to split concatenated personnel on the same line into separate lines.
- Add filtering for parenthetical sub-location lines (e.g. `(Altın Kaz çiftliği)`) and instruction footer notes (e.g. `*Sabit kalınacak*`).
- Update `_extractTeam()` to normalize `3B` or `3-B` to `3/B`.
- Support shift block splitting when a new shift time range is encountered within a block that already contains personnel.

### Test Layer

#### [NEW] [bulk_text_parser_edge_cases_test.dart](file:///c:/Users/baba/personelapp2/test/unit/bulk_text_parser_edge_cases_test.dart)
- Unit tests verifying multi-personnel line splitting, space-separated shift hours, abbreviated ranks, location note filtering, team normalization, and unpunctuated numbering.

#### [MODIFY] [user_prompt_bulk_parse_test.dart](file:///c:/Users/baba/personelapp2/test/unit/user_prompt_bulk_parse_test.dart)
- Assertions for exact block count, exact personnel counts, 0 blocking issues, and zero false personnel items for the full user prompt text.

---

## Tasks

### Task 1: Add Failing Unit Tests for All Edge Cases

**Files:**
- Create: `test/unit/bulk_text_parser_edge_cases_test.dart`

- [ ] **Step 1: Write failing unit tests for edge cases**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('BulkTextParser Edge Cases', () {
    test('splits multiple personnel on the same line', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
5. J.Uzm.Çvş. Yusuf TUŞ 6.J.Uzm.Çvş. Ertuğrul BAĞCI
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.personnelList, hasLength(2));
      expect(result.blocks.single.personnelList[0].rawName, 'Yusuf TUŞ');
      expect(result.blocks.single.personnelList[1].rawName, 'Ertuğrul BAĞCI');
    });

    test('recognizes space-separated time ranges like 08:00 20:00', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
08:00 20:00
1. J.Asb.Ü.Çvş. Selahattin ÇAKIR
''';
      final result = BulkTextParser.parse(input);
      expect(result.issues.any((i) => i.code == 'invalid_personnel'), isFalse);
      expect(result.blocks.single.personnelList, hasLength(1));
    });

    test('recognizes abbreviated rank J.Asb.Ü.Çvş.', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
1. J.Asb.Ü.Çvş. Selahattin ÇAKIR
''';
      final result = BulkTextParser.parse(input);
      final person = result.blocks.single.personnelList.single;
      expect(person.rawRank, 'J.Asb.Üçvş.');
      expect(person.rawName, 'Selahattin ÇAKIR');
    });

    test('filters parenthetical location sub-headers and footer instruction notes', () {
      const input = '''
*02.08.2026*
*9/B GÖREV Listesi*
(Altın Kaz çiftliği)
1) J.Asb.Çvş.Ahmet TINAS
*Sabit kalınacak*
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.personnelList, hasLength(1));
      expect(result.blocks.single.personnelList.single.rawName, 'Ahmet TINAS');
    });

    test('normalizes team format 3B- to 3/B and parses numbering without dot like 10J.Uzm.Çvş.', () {
      const input = '''
3B- 01.08.2026 *Hazır Kıta* İsim Listesi;
10J.Uzm.Çvş. Abdusamed ÖZAĞAÇKAYA
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.parsedTimName, '3/B');
      expect(result.blocks.single.personnelList.single.rawName, 'Abdusamed ÖZAĞAÇKAYA');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`
Expected: FAIL on multi-personnel line, space-separated time range, abbreviated rank, location note filtering, and team normalization.

---

### Task 2: Implement Multi-Personnel Line Splitter & Punctuation Improvements

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_parser.dart`

- [ ] **Step 1: Implement line splitting logic and update numbering regex**

Update `_numberedPersonnelPattern` in `bulk_text_parser.dart`:
```dart
static final RegExp _numberedPersonnelPattern = RegExp(
  r'^\s*(\d+)\s*([.)\-:]|(?=J\s*[.]?\s*(?:Asb|Uzm|Ütğm|Tğm|Astğm)))\s*(.+)$',
  caseSensitive: false,
);
```

Add `_splitLineIfMultiplePersonnel(String line)` helper:
```dart
static List<String> _splitLineIfMultiplePersonnel(String line) {
  final splitPattern = RegExp(
    r'(?<=\S)\s+(?=(?:\d+\s*[.)\-:]?\s*)?J\s*[.]?\s*(?:Asb|Uzm|Ütğm|Tğm|Astğm))',
    caseSensitive: false,
  );
  final parts = line.split(splitPattern);
  return parts.where((p) => p.trim().isNotEmpty).toList();
}
```

Integrate `_splitLineIfMultiplePersonnel` into the parsing line loop in `BulkTextParser.parse()`.

- [ ] **Step 2: Run test to verify multi-personnel and numbering pass**

Run: `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`

---

### Task 3: Expand Rank Regex & Normalization Logic

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_parser.dart`

- [ ] **Step 1: Update `_rankPattern` and `_normalizeRank`**

Update `_rankPattern`:
```dart
static final RegExp _rankPattern = RegExp(
  r'^(J\s*[.]?\s*(?:(?:Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm|Yzb|Bçvş|Bcvs)|'
  r'(?:(?:Asb|Uzm)\s*[.]?\s*(?:Kd\s*[.]?\s*)?'
  r'(?:Ü[.]?Çvş|U[.]?Cv[sş]|Üçvş|Ucv[sş]?|Çvş|Cv[sş]?))))\s*[.]?)\s*',
  caseSensitive: false,
);
```

Update `_normalizeRank`:
```dart
static String _normalizeRank(String rank) {
  final clean = _fold(rank).replaceAll(RegExp(r'[\s.]'), '');
  if (clean.contains('ütğm') || clean.contains('utgm')) return 'J.Ütğm.';
  if (clean.contains('astğm') || clean.contains('astgm')) return 'J.Astğm.';
  if (clean.contains('tğm') || clean.contains('tgm')) return 'J.Tğm.';
  if (clean.contains('yzb')) return 'J.Yzb.';
  if (clean.contains('bçvş') || clean.contains('bcvs')) return 'J.Bçvş.';
  if (clean.contains('asbkdüçvş') || clean.contains('asbkducvs') || clean.contains('asbkdüçvs')) return 'J.Asb.Kd.Üçvş.';
  if (clean.contains('asbkdçvş') || clean.contains('asbkdcvs') || clean.contains('asbkdçvs')) return 'J.Asb.Kd.Çvş.';
  if (clean.contains('asbüçvş') || clean.contains('asbucvs') || clean.contains('asbüçvs') || clean.contains('asbüçvş')) return 'J.Asb.Üçvş.';
  if (clean.contains('asbçvş') || clean.contains('asbcvs') || clean.contains('asbçvs')) return 'J.Asb.Çvş.';
  return 'J.Uzm.Çvş.';
}
```

- [ ] **Step 2: Run test to verify rank tests pass**

Run: `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`

---

### Task 4: Update Time Range Pattern & Sub-Block Shift Tracking

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_parser.dart`

- [ ] **Step 1: Update time range regexes and shift block logic**

Update `_timeRangePattern` and `_timeLikePattern`:
```dart
static final RegExp _timeRangePattern = RegExp(
  r'(?<!\d)(\d{1,2})[.:](\d{2})\s*(?:[-/]|to|\s+)\s*(\d{1,2})[.:](\d{2})(?!\d)',
  caseSensitive: false,
);
static final RegExp _timeLikePattern = RegExp(
  r'\d{1,2}[.:]\d{2}\s*(?:[-/]|to|\s+)\s*\d{1,2}[.:]\d{2}',
  caseSensitive: false,
);
```

In `parse()`, when a shift time header appears inside a block where `personnel.isNotEmpty` and the shift time is different from `currentTimeRange`, flush the current personnel into a block before updating `currentTimeRange`.

- [ ] **Step 2: Run test to verify space-separated time ranges pass**

Run: `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`

---

### Task 5: Filter Location Notes, Parenthetical Sub-headers & Footnotes

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_parser.dart`

- [ ] **Step 1: Add note and location line filter checks**

Add helper `_isCommentOrNoteLine(String line)`:
```dart
static bool _isCommentOrNoteLine(String line) {
  final trimmed = line.trim();
  if (trimmed.startsWith('(') && trimmed.endsWith(')') && !_rankPattern.hasMatch(trimmed)) {
    return true;
  }
  final folded = _fold(trimmed);
  if (folded.contains('sabit kalınacak') ||
      folded.contains('kalınacaktır') ||
      folded.contains('saat kalacak') ||
      folded.contains('değişimli')) {
    if (!_rankPattern.hasMatch(trimmed) && !_numberedPersonnelPattern.hasMatch(trimmed)) {
      return true;
    }
  }
  return false;
}
```

Integrate `_isCommentOrNoteLine` into `parse()` to increment `ignoredLineCount` and skip adding as personnel.

- [ ] **Step 2: Run test to verify note filtering passes**

Run: `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`

---

### Task 6: Normalize Team Names & Full Suite Verification

**Files:**
- Modify: `lib/features/activity/domain/parser/bulk_text_parser.dart`
- Modify: `test/unit/user_prompt_bulk_parse_test.dart`

- [ ] **Step 1: Update `_extractTeam()` to normalize formats like `3B` or `3-B` to `3/B`**

```dart
static String? _normalizeTeamName(String? rawTeam) {
  if (rawTeam == null) return null;
  final match = RegExp(r'^(\d{1,2})\s*[/\-]?\s*([A-Za-zÇĞİÖŞÜçğıöşü]+)$').firstMatch(rawTeam);
  if (match != null) {
    final num = match.group(1)!;
    final suffix = match.group(2)!.toUpperCase();
    if (suffix == 'TIM' || suffix == 'TIMI' || suffix == 'BÖLÜK' || suffix == 'BOLUK') {
      return num;
    }
    return '$num/$suffix';
  }
  return rawTeam;
}
```

- [ ] **Step 2: Update `user_prompt_bulk_parse_test.dart` to assert zero blocking errors and clean blocks**

- [ ] **Step 3: Run full unit test suite**

Run: `flutter test`
Expected: All tests PASS with 0 failures!

---

## Verification Plan

### Automated Tests
- `flutter test test/unit/bulk_text_parser_edge_cases_test.dart`
- `flutter test test/unit/user_prompt_bulk_parse_test.dart`
- `flutter test test/unit/bulk_text_parser_real_roster_test.dart`
- `flutter test test/features/activity/bulk_import_save_button_test.dart`

### Manual Verification
- Launch the app, open **Metinden Toplu Aktarım** (Bulk Import Dialog).
- Paste the exact text from the user prompt into the input field.
- Verify that all 19 shift blocks are rendered cleanly in the preview with 0 blocking errors, accurate dates, correct team names, correct personnel counts, and clean rank/name mappings.
