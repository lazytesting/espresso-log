# UX Consistency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved UX-consistency decisions and add shot deletion.

**Architecture:** One new port method (`ShotRepository.delete`) through domain, data and test
doubles; everything else is `lib/ui/` widget changes with widget tests.

**Tech Stack:** Flutter (FVM), flutter_bloc, provider, go_router, flutter_test, mockito.

**Spec:** `docs/superpowers/specs/2026-11-17-ux-consistency-design.md`

## Global Constraints

- Run Flutter/Dart through `fvm`; `fvm flutter analyze` clean and `fvm flutter test` green at the
  end of every task; `fvm dart format lib test` before each commit.
- Sentence case for all UI copy; never all caps.
- No new packages.

## Review Focus

1. Deleting the shot that is currently open, then History reloading: the deleted shot must not
   reappear and nothing throws. Test in Task 1.
2. Deleting a shot id whose file is already gone: no exception. Test in Task 1.
3. Cancel in the delete dialog leaves the shot untouched. Test in Task 1.
4. Bean icon renders in both selected and unselected tab colours without overflow at 24 px.
   Test in Task 5.
5. Connection dialog for every non-established state (`ConnectionConnecting`, `ConnectionPaused`)
   shows the right copy. Test in Task 4.

---

### Task 1: Delete shot

**Files:** `lib/domain/shot/shot_repository.dart`, `lib/data/shot/file_shot_repository.dart`,
`test/support/in_memory_shot_repository.dart`, `test/ui/shot/save_shot_button_test.dart`
(`_RecordingShotRepository`), `lib/ui/history/saved_shot_screen.dart`; tests
`test/data/shot/file_shot_repository_test.dart`, `test/ui/history/saved_shot_screen_test.dart`.

**Interfaces:** Produces `Future<void> ShotRepository.delete(String id)` — removes the shot; no-op
when it does not exist.

- [ ] **Step 1: Failing tests.**
  - file repo: `delete removes the shot` (save, delete, `get` → null, `list` empty);
    `delete of a missing id does nothing` (no throw).
  - saved shot screen: tap `find.byTooltip('Delete shot')` → dialog `Delete shot?`; tap
    `Cancel` → repo still has it; repeat and tap `Delete` → repo empty and the screen popped
    (pump inside a `Navigator` with a home route showing text `History home`, push the screen,
    expect `History home` visible after delete).
- [ ] **Step 2:** run → FAIL (no `delete`).
- [ ] **Step 3:** implement. File repo: delete `<id>.json` if it exists, `talker.info`. Detail app
  bar gets `IconButton(icon: Icon(Icons.delete_outline), tooltip: 'Delete shot')` after share;
  dialog copy `Delete shot?` / `This can't be undone.` / `Cancel` / `Delete`; on confirm delete
  then `Navigator.of(context).pop()`. History reloads via its existing reload-on-active plus
  `context.push(...).then((_) => cubit.load())` on the row tap.
- [ ] **Step 4:** analyze + full suite → PASS.
- [ ] **Step 5:** commit `feat: delete shots from history detail`.

### Task 2: Shared section header, Settings title and naming

**Files:** create `lib/ui/components/section_header.dart`; modify `lib/ui/history/history.dart`
(`_DayHeader` → `SectionHeader`), `lib/ui/settings/settings.dart`; test
`test/ui/settings/settings_test.dart` (new; `FakeSettings` from `test/support`).

**Interfaces:** `class SectionHeader extends StatelessWidget { const SectionHeader(String label); }`
— padding `16, 20, 16, 8`, `labelLarge`, `colorScheme.primary`, letter spacing 1.

- [ ] **Step 1: Failing test** `settings_test.dart`: pumps `SettingsScreen` with
  `Provider<SettingsRepository>` → finds `AppBar` with `Settings`; `find.byType(SectionHeader)`
  finds 3 (`Scale`, `Pressure sensor`, `Developer tools`) and `Scale` is above
  `Pressure sensor` (`getTopLeft` dy); open the scale dropdown → `Decent scale`; pressure
  dropdown → `Bookoo pressure sensor`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement; Settings wraps its `ListView` in `Scaffold(appBar: AppBar(title: Text('Settings')))`;
  scale section moves above pressure; the delay slider stays in the pressure section.
- [ ] **Step 4:** analyze + full suite → PASS.
- [ ] **Step 5:** commit `feat: shared section header, settings title and naming`.

### Task 3: Copy and format alignment

**Files:** `lib/ui/home/home.dart`, `lib/domain/shot/brew_ratio.dart`,
`lib/ui/shot/shot_result_view.dart`, `lib/ui/history/history.dart` (remove `formatShotDate`),
`lib/ui/history/saved_shot_screen.dart` (share text), `lib/ui/beans/bean_edit_screen.dart`,
`lib/ui/beans/beans_screen.dart`; tests: `brew_ratio_test.dart`, `home_test.dart`,
`shot_result_view_test.dart`, `saved_shot_screen_test.dart`, `history_screen_test.dart`,
`shot_screen_test.dart`, `bean_edit_screen_test.dart`, `beans_screen_test.dart`.

- [ ] **Step 1: Failing tests:**
  - `formatBrewRatio(2.04) == '1:2.0'`; all `'1 : 2.0'` expectations become `'1:2.0'`.
  - home: `find.text('Start shot')`, `find.text('START SHOT')` nothing.
  - result view: the ratio `Text` style colour equals the Dose value colour (compare
    `tester.widget<Text>(find.text('1:2.0', findRichText: true)).style?.color` with the dose
    cell's).
  - bean edit: `find.widgetWithText(FilledButton, 'Save')` found.
  - beans list: `find.text('18.0 g')` nothing.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement; share text `Espresso shot ${formatShotTitle(shot.recordedAt, DateTime.now())}`;
  drop `valueColor` from the ratio cell (keep the `MetricCell.valueColor` parameter only if
  something else uses it, otherwise remove it).
- [ ] **Step 4:** analyze + full suite → PASS.
- [ ] **Step 5:** commit `fix: consistent copy, ratio and date formats`.

### Task 4: Connection dialog explains itself

**Files:** `lib/ui/home/device_connection/connection_modal_wrapper.dart`; test
`test/ui/home/connection_modal_wrapper_test.dart` (new).

**Interfaces:** extract `class ConnectionDialog extends StatelessWidget { const ConnectionDialog({required bool paused}); }`
used by both `showDialog` calls.

- [ ] **Step 1: Failing test:** pump `ConnectionDialog(paused: false)` → `CircularProgressIndicator`
  and `Connecting to your scale and pressure sensor`; `paused: true` → `Devices paused to save battery`
  and `Touch the screen to reconnect`, no spinner.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement (`AlertDialog`, title text, content row/column as above).
- [ ] **Step 4:** analyze + full suite → PASS.
- [ ] **Step 5:** commit `feat: explain the connection dialog`.

### Task 5: Coffee bean tab icon

**Files:** create `lib/ui/components/bean_icon.dart`; modify `lib/ui/scaffold/root_scaffold.dart`;
test `test/ui/components/bean_icon_test.dart`.

**Interfaces:** `class BeanIcon extends StatelessWidget { const BeanIcon({double? size}); }` —
`CustomPaint` sized `size ?? IconTheme.of(context).size ?? 24`, colour from
`IconTheme.of(context).color`; paints a filled oval tilted ~30° with an S-curve centre line in
the background colour gap (stroke in `Colors.transparent`-free way: draw the S-curve with
`BlendMode.clear` inside a `saveLayer`).

- [ ] **Step 1: Failing test:** inside `IconTheme(data: IconThemeData(color: Colors.red, size: 24))`
  → `tester.getSize(find.byType(BeanIcon)) == Size(24, 24)`; root scaffold test not needed —
  check `find.byType(BeanIcon)` inside a pumped `BottomNavigationBar` with the same items list
  exported as `rootNavItems`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement; Beans tab uses `icon: BeanIcon()`.
- [ ] **Step 4:** analyze + full suite → PASS.
- [ ] **Step 5:** commit `feat: coffee bean tab icon`; update `CLAUDE.md` (delete shot, shared
  `SectionHeader`) in this commit.
