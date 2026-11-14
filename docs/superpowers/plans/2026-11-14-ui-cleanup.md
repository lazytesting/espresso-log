# UI Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cleaner, consistent screens: minimal Home, one shared shot-result view for "shot done" and
History detail with all metrics in one grid, History grouped by day with roaster, Beans with a
plain `+` FAB.

**Architecture:** Pure UI change in `lib/ui/`. One reusable metric cell/grid widget, one reusable
`ShotResultView`, pure formatting/grouping helpers for History (unit tested), widget tests for each
screen. No domain or data-layer changes.

**Tech Stack:** Flutter (FVM 3.47.9), flutter_bloc, provider, go_router, syncfusion charts,
flutter_test. No `intl` dependency: format dates by hand.

**Spec:** `docs/superpowers/specs/2026-11-14-ui-cleanup-design.md`
(mockups: https://claude.ai/artifact/49B2uSMWDAK5HoZgrGkWw1)

## Global Constraints

- Run every Flutter/Dart command through `fvm`.
- No changes under `lib/domain/` or `lib/data/`; no stored-format changes.
- Missing values render as `--`. No bean renders as `Unknown bean` (`unknownBeanLabel`).
- Ratio text keeps the existing `formatBrewRatio` output (`1 : 2.0`).
- Theme colours come from `lib/ui/theme.dart` / `Theme.of(context)`; cards use the theme's
  `CardThemeData` (no per-widget card styling).
- Shot metric grid: 3 columns, order Dose, Yield, Ratio, Time, Peak pressure, Peak flow.
- `fvm flutter analyze` must be clean and `fvm flutter test` green at the end of every task.

## Review Focus

1. Shot with no bean, no dose and no final weight (pre-bean v1 files): every cell shows `--`,
   header shows `Unknown bean`, no exception. Test in Task 2.
2. Long bean/roaster names in History rows and the result header: ellipsis, no overflow error at
   phone width. Test in Task 4 (pump at 360 px wide with a 60-char name).
3. Shots from an earlier year: header includes the year (`Tue 10 Nov 2025`). Test in Task 4.
4. Two shots on the same day but recorded out of order, and shots just either side of local
   midnight: grouping uses local calendar date. Test in Task 4.
5. Restart after a shot is saved: the Save button must reset to unsaved for the new shot. Test in
   Task 3.

---

### Task 1: Metric cell and grid widgets; live metrics in one card

**Files:**
- Create: `lib/ui/shot/metric_grid.dart`
- Modify: `lib/ui/shot/shot_metrics_widget.dart` (live row uses the grid; delete `ShotSummaryWidget`
  and `_MetricCard`)
- Modify: `lib/ui/components/current-weight/current_weight_widget.dart`,
  `lib/ui/components/weight-change/weight_change_widget.dart`,
  `lib/ui/components/pressure/pressure_widget.dart`, `lib/ui/shot/timer/timer_widget.dart`
  (render a `MetricCell`, no `Card`)
- Modify: `lib/ui/shot/shot_screen.dart` (waiting row wraps the four component widgets in one
  `MetricGrid`-style card)
- Test: `test/ui/shot/metric_grid_test.dart`

**Interfaces:**
- Produces:
  - `class MetricCell extends StatelessWidget { const MetricCell({required String value, String? unit, String? label}); }`
    Value large (`titleLarge`, tabular figures), unit smaller muted after the value, label
    `bodySmall` muted underneath. Keys none.
  - `class MetricGrid extends StatelessWidget { const MetricGrid({required List<Widget> cells, int columns = 3}); }`
    One `Card`, cells laid out in rows of `columns` (each `Expanded`), 16 px between rows.
    Empty trailing slots in the last row stay blank.
  - `ShotMetricsWidget(ShotMetrics)` keeps its constructor; renders `MetricGrid(columns: 4)` with
    cells `g`, `g/s`, `bar`, `s` (unit only, no label).
  - `String formatMetric(double? value) => value?.toStringAsFixed(1) ?? '--'` in `metric_grid.dart`.

- [ ] **Step 1: Write failing tests** in `metric_grid_test.dart`:
  - `MetricGrid` with 4 cells, `columns: 3` → finds 2 `Row`s inside it, one `Card`.
  - `MetricCell(value: '18.0', unit: 'g', label: 'Dose')` → finds text `Dose` and rich text
    containing `18.0` and `g`.
  - `formatMetric(null) == '--'`, `formatMetric(9.24) == '9.2'`.
- [ ] **Step 2:** `fvm flutter test test/ui/shot/metric_grid_test.dart` → FAIL (file missing).
- [ ] **Step 3:** Implement `metric_grid.dart`; switch `ShotMetricsWidget` and the four component
  widgets to `MetricCell`; in `ShotScreen` waiting branch use
  `MetricGrid(columns: 4, cells: const [CurrentWeightWidget(), WeightChangeWidget(), PressureWidget(), TimerWidget()])`.
  Delete `ShotSummaryWidget`; the `ShotGraphStopped` branch temporarily renders
  `ShotMetricsWidget(state.metrics)` (Task 3 replaces it).
- [ ] **Step 4:** `fvm flutter analyze && fvm flutter test` → all PASS. `saved_shot_screen.dart`
  still references `ShotSummaryWidget`: replace that one line with
  `ShotMetricsWidget(shot.snapshot.metrics)` temporarily (Task 2 replaces it) and fix the
  `'Seconds'` expectation in `saved_shot_screen_test.dart` only if it now fails.
- [ ] **Step 5: Commit** `feat: shared metric cell and grid, live metrics in one card`

### Task 2: `ShotResultView` and History detail screen

**Files:**
- Create: `lib/ui/shot/shot_result_view.dart`
- Modify: `lib/ui/history/saved_shot_screen.dart` (body = `ShotResultView`; delete
  `ShotBeanSection`, `_InfoCard`)
- Test: `test/ui/shot/shot_result_view_test.dart`; update `test/ui/history/saved_shot_screen_test.dart`

**Interfaces:**
- Consumes: `MetricGrid`, `MetricCell`, `formatMetric` (Task 1); `ShotGraph` (existing);
  `brewRatio`, `formatBrewRatio`; `Bean.roastLabel`; `unknownBeanLabel`.
- Produces:
  `class ShotResultView extends StatelessWidget { const ShotResultView({required ShotSnapshot snapshot, required Bean? bean, required double? doseGrams}); }`
  Layout (scrollable `ListView`, 16 px horizontal padding):
  1. Bean name (`titleLarge`, ellipsis) and, when a bean exists, `roaster · roast` / roast only
     (`bodyMedium`, muted, ellipsis). Reuse `BeansScreen.subtitle(bean)` for that line.
  2. `MetricGrid` cells, exact labels/units: `Dose` (g), `Yield` (g, `summary.finalWeight`),
     `Ratio` (no unit, `formatBrewRatio(brewRatio(outputGrams: finalWeight, doseGrams: dose))`,
     accent colour), `Time` (s, `durationMillis / 1000` 1 decimal), `Peak pressure` (bar),
     `Peak flow` (g/s, `peakWeightChangeRate`). Units hidden when value is `--`.
  3. Card with legend row (`Weight (g)`, `Pressure (bar)`) and `ShotGraph`, height 300.

- [ ] **Step 1: Write failing tests** in `shot_result_view_test.dart`:
  - full shot (bean Guji / roaster Friedhats / roast 1, dose 18.0, finalWeight 36.0,
    duration 28400, peakPressure 9.2, peakRate 2.4): finds `Guji`, `Friedhats · Light`, labels
    `Dose`, `Yield`, `Ratio`, `Time`, `Peak pressure`, `Peak flow`, text `1 : 2.0`, and
    `find.textContaining('28.4')`.
  - empty shot (`ShotSnapshot.empty`, no bean, no dose): finds `Unknown bean`;
    `find.text('--')` finds 5 (every cell except Time, which shows `0.0`); no exceptions.
  - long name: 60-char bean name at `tester.view.physicalSize = Size(360, 800)` with
    `devicePixelRatio = 1` → `tester.takeException()` is null.
- [ ] **Step 2:** run the test file → FAIL.
- [ ] **Step 3:** implement `ShotResultView`; `SavedShotScreen` body becomes
  `ShotResultView(snapshot: shot.snapshot, bean: loaded.bean, doseGrams: shot.doseGrams)`.
  App bar unchanged (back, `formatShotDate` title for now, share).
- [ ] **Step 4:** update `saved_shot_screen_test.dart`: replace `'Seconds'` with `'Time'`,
  `'36.0 g'` checks with `find.textContaining('36.0')`, and the old-shot `'--'` count with 4
  (dose, ratio, peak pressure, peak flow). Run `fvm flutter analyze && fvm flutter test` → PASS.
- [ ] **Step 5: Commit** `feat: shared shot result view on the history detail screen`

### Task 3: Shot done uses `ShotResultView`

**Files:**
- Modify: `lib/ui/shot/shot_screen.dart`
- Test: `test/ui/shot/save_shot_button_test.dart` (update), new `test/ui/shot/shot_screen_test.dart`

**Interfaces:**
- Consumes: `ShotResultView` (Task 2); `BeansCubit.state.selectedBean` / `.doseGrams`.
- Produces: `SaveShotButton(ShotSnapshot)` is now a `FilledButton` labelled `Save`; after saving
  it shows `Icon(Icons.check)` and is disabled. It must reset when given a different snapshot
  (override `didUpdateWidget`: if `oldWidget.snapshot != widget.snapshot` set `_saved = false`).

- [ ] **Step 1: Write failing tests:**
  - `save_shot_button_test.dart`: tap `find.text('Save')` → one shot saved, then
    `find.byIcon(Icons.check)` found and `find.text('Save')` gone. Re-pump with a different
    `ShotSnapshot` instance → `find.text('Save')` found again (Review Focus 5).
  - `shot_screen_test.dart`: with a `ShotGraphCubit` mock/stub in `ShotGraphStopped` state and a
    `BeansCubit` whose selected bean is Guji at 18.0 g → finds `ShotResultView`, `Guji`,
    `Dose`, `Save`, and `find.text('Shot done')`. Use `@GenerateNiceMocks([MockSpec<ShotGraphCubit>(), MockSpec<TimerCubit>()])`
    and `whenListen`/`when(cubit.state)` per repo conventions; regenerate mocks with build_runner.
- [ ] **Step 2:** run both files → FAIL.
- [ ] **Step 3:** in `ShotScreen`, when state is `ShotGraphStopped` the body is
  `ShotResultView(snapshot: state.snapshot, bean: beans.selectedBean, doseGrams: beans.doseGrams)`
  (read via `BlocBuilder<BeansCubit, BeansState>`); otherwise keep the metrics row + live graph.
  App bar actions order: restart `IconButton`, then `SaveShotButton` (only when stopped), 12 px end
  padding.
- [ ] **Step 4:** `fvm flutter analyze && fvm flutter test` → PASS.
- [ ] **Step 5: Commit** `feat: shot done screen shares the history detail layout`

### Task 4: History grouped by day with roaster

**Files:**
- Create: `lib/ui/history/history_format.dart`
- Modify: `lib/ui/history/history.dart`, `lib/ui/history/shot_bean_labels.dart` (delete
  `historySubtitle`), `lib/ui/history/saved_shot_screen.dart` (title uses `formatShotTitle`)
- Test: `test/ui/history/history_format_test.dart`; update `shot_bean_labels_test.dart`,
  `history_screen_test.dart`

**Interfaces:**
- Consumes: `HistoryEntry` (existing), `formatDose`, `beanNameFor`, `formatBrewRatio`.
- Produces (all in `history_format.dart`):
  - `class HistoryDay { final DateTime day; final List<HistoryEntry> entries; }` (`day` is local
    midnight).
  - `List<HistoryDay> groupByDay(List<HistoryEntry> entries)` — keeps input order of days and
    entries; groups by local `DateTime(y, m, d)` of `shot.recordedAt.toLocal()`.
  - `String formatDayHeader(DateTime day, DateTime now)` → `Today`, `Yesterday`, else
    `Thu 12 Nov`, plus ` 2025` when `day.year != now.year`. English 3-letter names, hand-written
    lists.
  - `String formatTime(DateTime t)` → `08:42`.
  - `String formatShotTitle(DateTime t, DateTime now)` → `formatDayHeader(...) · formatTime(...)`
    (used as the detail app-bar title, e.g. `Thu 12 Nov · 08:42`).
  - `String formatDoseYield(double? dose, double? yield)` → `18.0 → 36.4 g`, nulls as `--`.
- History row widget (private in `history.dart`): `ListTile`-free custom `InkWell` row, min height
  64: time (muted, 56 px) | bean name (ellipsis) with roaster below when `bean?.roaster != null`
  (ellipsis) | right column `formatDoseYield` and ratio (accent; muted `--`). Header: section
  label in `labelLarge`, accent colour, padding 16/20/16/8.
  `HistoryScreen` takes optional `DateTime Function() now` (default `DateTime.now`) for tests.

- [ ] **Step 1: Write failing tests** in `history_format_test.dart` with
  `now = DateTime(2026, 11, 14, 9)`:
  - `formatDayHeader(DateTime(2026,11,14), now) == 'Today'`; `(2026,11,13)` → `Yesterday`;
    `(2026,11,12)` → `Thu 12 Nov`; `(2025,11,10)` → `Mon 10 Nov 2025`.
  - `groupByDay` on entries (newest first, as `ShotRepository.list()` returns) at 11-14 08:42,
    11-14 00:00, 11-13 23:59, 11-12 07:00 → days `[11-14 (2), 11-13 (1), 11-12 (1)]`, entries in
    input order. A second case with input 11-14 08:42, 11-13 09:00, 11-14 07:00 (out of order) →
    days `[11-14 (2), 11-13 (1)]`: groups merge by local date, first-seen day order.
  - `formatDoseYield(18.0, 36.44) == '18.0 → 36.4 g'`; `formatDoseYield(null, 38.0) == '-- → 38.0 g'`;
    `formatDoseYield(null, null) == '-- → -- g'`.
  - `formatTime(DateTime(2026,1,1,8,4)) == '08:04'`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement helpers and new list (`ListView` of headers + rows built from
  `groupByDay`). Delete `historySubtitle` and its tests. Keep `formatShotDate` only if still used
  (share text in `saved_shot_screen.dart` keeps it).
- [ ] **Step 4:** update `history_screen_test.dart`: expect `find.text('08:14')`; add a widget
  test with bean `Guji`/roaster `Friedhats` dose 18 finalWeight 36 → finds `Friedhats`,
  `18.0 → 36.0 g`, `1 : 2.0`, and the header for its day; add the 360 px / 60-char-name overflow
  test (`tester.takeException()` null). `fvm flutter analyze && fvm flutter test` → PASS.
- [ ] **Step 5: Commit** `feat: group history by day and show roaster`

### Task 5: Home bean/dose card without metrics or title

**Files:**
- Create: `lib/ui/home/setup_label.dart`
- Modify: `lib/ui/home/home.dart`, `lib/ui/home/bean_selector.dart`, `lib/ui/home/dose_selector.dart`
- Test: update `test/ui/home/bean_selector_test.dart`, `dose_selector_test.dart`; new
  `test/ui/home/home_test.dart`

**Interfaces:**
- Produces: `class SetupLabel extends StatelessWidget { const SetupLabel(String text); }` — fixed
  width 64, `labelLarge`, muted colour, letter spacing 1. Both selectors use it (text `Bean`,
  `Dose`; same widget, so same size).
- `BeanSelector` and `DoseSelector` return a bare row (no `Card`), min height 72, horizontal
  padding 16. `BeanSelector` row: `SetupLabel('Bean')`, name + subtitle column (ellipsis),
  `Icons.arrow_drop_down`; whole row tappable (`InkWell`). `DoseSelector` keeps the `Key('dose-text')`
  and the `−`/`+` `IconButton`s (use `IconButton.outlined`).
- `HomeScreen`: no app bar/title, no metric widgets. Centred column with 16 px padding: one `Card`
  containing `BeanSelector`, `Divider(height: 1, indent: 16, endIndent: 16)`, `DoseSelector`;
  24 px gap; full-width `FilledButton.icon` `START SHOT` (height 64, `Icons.coffee`) that pushes
  `/shot`.

- [ ] **Step 1: Write failing tests:** `home_test.dart` pumps `HomeScreen` with a `BeansCubit`
  (fake settings, in-memory beans) → finds `Bean`, `Dose`, `START SHOT`, exactly one `Card`, and
  no `CurrentWeightWidget`/`PressureWidget`/`WeightChangeWidget`; `find.byType(SetupLabel)`
  finds 2 and both have the same rendered height (`tester.getSize`).
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement. Existing selector tests that tap `find.byType(BeanSelector)` keep
  working; fix any `ListTile` finder only in the BottomSheet (unchanged).
- [ ] **Step 4:** `fvm flutter analyze && fvm flutter test` → PASS.
- [ ] **Step 5: Commit** `feat: single bean and dose card on home`

### Task 6: Beans list, `+` FAB, nav label, docs

**Files:**
- Modify: `lib/ui/beans/beans_screen.dart`, `lib/ui/scaffold/root_scaffold.dart`, `CLAUDE.md`
- Test: update `test/ui/beans/beans_screen_test.dart`

**Interfaces:**
- `BeansScreen` FAB: `FloatingActionButton(tooltip: 'Add bean', child: Icon(Icons.add))`.
- Rows: same row style as History (no `Card`): name (ellipsis), `BeansScreen.subtitle(bean)`
  below, trailing `formatDose(bean.doseGrams)` muted; `Divider` between rows.
- Bottom nav label `home` → `Home`.

- [ ] **Step 1:** update `beans_screen_test.dart`: replace `find.text('Add bean')` with
  `find.byTooltip('Add bean')`; add expectation `find.byType(Card)` finds nothing and the bean
  dose text (e.g. `18.0 g`) is shown.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement; update `CLAUDE.md` UI-layer paragraph: Home has one bean/dose card,
  shot done and history detail share `ShotResultView` (`lib/ui/shot/shot_result_view.dart`),
  History is grouped by day (`history_format.dart`).
- [ ] **Step 4:** `fvm flutter analyze && fvm flutter test` → PASS. Then
  `fvm flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true` and
  compare each screen against the mockup.
- [ ] **Step 5: Commit** `feat: plain add button and list rows on beans; docs`
