# Beans & Dose Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user manage beans in a new Beans tab, pick a bean and dose on Home, store both with saved shots, and show bean, dose and ratio in history.

**Architecture:** A `Bean` domain type and a `BeanRepository` port (file-backed, one JSON per bean, mirroring `ShotRepository`). One app-wide `BeansCubit` owns the non-archived beans, the selected bean and the current dose; Home, the Beans tab and the shot save button read it. `RecordedShot` gains optional `beanId`/`doseGrams`; history resolves bean names through `BeanRepository`.

**Tech Stack:** Flutter (via `fvm`), `flutter_bloc`, `provider`, `go_router`, `shared_preferences`, `equatable`, `flutter_test` + `bloc_test`.

**Spec:** `docs/superpowers/specs/2026-11-12-beans-and-dose-design.md`

## Global Constraints

- Commands run with `fvm` (`fvm flutter test`, `fvm flutter analyze`). `fvm flutter analyze` must stay clean after every task.
- Domain code (`lib/domain/`) must not import Flutter or `lib/data/`. Cubits depend on domain interfaces only; `lib/main.dart` is the only place that constructs concrete implementations.
- Bean fields: `name` (mandatory), `roaster`, `roastLevel` (int 1–5: 1 Light, 2 Medium-light, 3 Medium, 4 Medium-dark, 5 Dark; new beans start at 3), `notes`, `id`, `archived`, `doseGrams`.
- Dose: default 18.0 g (new bean and Unknown bean), allowed 5.0–30.0 g, one-decimal precision, plus/minus step 0.1 g, persisted immediately on change.
- "Unknown bean" is the exact label for no specific bean (never "No bean").
- Bean ids are `DateTime.microsecondsSinceEpoch.toString()`, like shot ids.
- Beans are never deleted, only archived. Archived beans are hidden from the Beans tab and Home picker but resolve for shots.
- Bottom tabs in order: Home, History, Beans, Settings.
- `RecordedShot.formatVersion` becomes 2; version 1 files must still load (bean and dose null).
- Stored shot files hold `beanId` only. The share/export JSON additionally embeds the full bean as `bean` (bean's `toJson()`), or `null` for Unknown bean or an unresolvable id.
- Ratio = final weight / dose, shown as `1 : 2.1` (one decimal), `--` when either value is missing.
- History detail keeps the existing four-metric `ShotSummaryWidget` row unchanged.
- Tests use hand-written fakes in `test/support/` (no new `@GenerateNiceMocks`, so no build_runner step).
- Commit messages are Conventional Commits (`feat:`, `test:`, `docs:`).

## Review Focus

Inputs and conditions the spec implies but no happy-path test covers; each has a test in the owning task.

1. Whitespace-only bean name must not be savable; names, roaster and notes are trimmed, empty roaster/notes become null (Task 1, Task 6).
2. Typed dose with a decimal comma (`18,5`), non-numeric text, empty text, or out-of-range values: comma accepted, junk ignored (dose unchanged), range clamped (Task 1, Task 7).
3. A corrupt or foreign JSON file in the beans directory is skipped, not a crash (Task 2).
4. A shot whose `beanId` points at an archived bean shows that bean; a missing/unresolvable id shows "Unknown bean" (Task 9).
5. Final weight null or 0, dose null or 0: ratio is `--`, never a division by zero or `Infinity` (Task 3).
6. The selected bean is archived (or the stored selection id no longer exists): selection falls back to Unknown bean and its remembered dose (Task 5).
7. Version 1 shot files (no bean fields) still load and list (Task 3, Task 9).

---

### Task 1: Bean domain model, dose rules, repository port

**Files:**
- Create: `lib/domain/bean/bean.dart`, `lib/domain/bean/dose.dart`, `lib/domain/bean/bean_repository.dart`
- Create: `test/support/in_memory_bean_repository.dart`
- Test: `test/domain/bean/bean_test.dart`, `test/domain/bean/dose_test.dart`
- Also commit: the spec and this plan (`docs/superpowers/`)

**Interfaces:**
- Produces (`dose.dart`):
  - `const double defaultDoseGrams = 18.0`, `minDoseGrams = 5.0`, `maxDoseGrams = 30.0`, `doseStepGrams = 0.1`
  - `double normalizeDose(double grams)` — clamps to 5.0–30.0 and rounds to one decimal
  - `double? parseDose(String input)` — trims, accepts `,` or `.` as decimal separator, returns `normalizeDose(value)`, or null when the text is not a finite number
- Produces (`bean.dart`): `class Bean extends Equatable` with fields `String id`, `String name`, `String? roaster`, `int roastLevel`, `String? notes`, `bool archived`, `double doseGrams`; constants `Bean.minRoastLevel = 1`, `maxRoastLevel = 5`, `defaultRoastLevel = 3`; `static String roastLabel(int level)`;
  `factory Bean.create({required String name, String? roaster, int roastLevel = defaultRoastLevel, String? notes, DateTime? now})` (trims text, empty roaster/notes → null, `doseGrams = defaultDoseGrams`, `archived = false`);
  `Bean copyWith({String? name, String? Function()? roaster, int? roastLevel, String? Function()? notes, bool? archived, double? doseGrams})` (the function-wrapped params allow setting null);
  `factory Bean.fromJson(Map<String, dynamic>)` (clamps `roastLevel` to 1–5, normalizes `doseGrams`, `archived` defaults false), `Map<String, dynamic> toJson()`.
- Produces (`bean_repository.dart`): `abstract class BeanRepository { Future<void> save(Bean bean); Future<List<Bean>> list(); Future<Bean?> get(String id); }` — `list()` returns all beans including archived, sorted by name case-insensitively.
- Produces (`test/support/in_memory_bean_repository.dart`): `class InMemoryBeanRepository implements BeanRepository` with a public `final Map<String, Bean> beans` and `int saveCount`, same ordering rule in `list()`.

- [ ] **Step 1: Write failing tests**
  - `dose_test.dart`: `normalizeDose(18.04) == 18.0`; `normalizeDose(31) == 30.0`; `normalizeDose(4) == 5.0`; `normalizeDose(18.0 + doseStepGrams) == 18.1`; `parseDose('18,5') == 18.5`; `parseDose(' 17.25 ') == 17.3` (round half up is acceptable: assert `closeTo(17.3, 0.051)`); `parseDose('abc')`, `parseDose('')`, `parseDose('NaN')`, `parseDose('Infinity')` are null; `parseDose('99') == 30.0`.
  - `bean_test.dart`: `Bean.create(name: '  Guji ', roaster: '   ')` gives name `'Guji'`, roaster null, roastLevel 3, doseGrams 18.0, archived false, non-empty id; `now:` fixes the id to `now.microsecondsSinceEpoch.toString()`; `toJson`/`fromJson` round trip equals the original (all fields set); `fromJson` with `roastLevel: 9` gives 5 and with a missing `archived` gives false; `copyWith(roaster: () => null)` clears roaster; `Bean.roastLabel(1) == 'Light'`, `2 == 'Medium-light'`, `3 == 'Medium'`, `4 == 'Medium-dark'`, `5 == 'Dark'`.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/domain/bean`
Expected: FAIL (files do not exist).

- [ ] **Step 3: Implement** `dose.dart`, `bean.dart`, `bean_repository.dart` and the in-memory fake with the signatures above. Use `Equatable` for `Bean` (already a dependency).

- [ ] **Step 4: Run to verify pass**

Run: `fvm flutter test test/domain/bean && fvm flutter analyze`
Expected: PASS, no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers lib/domain/bean test/domain/bean test/support
git commit -m "feat: add Bean domain model, dose rules and BeanRepository port"
```

---

### Task 2: File-backed bean repository

**Files:**
- Create: `lib/data/bean/file_bean_repository.dart`
- Test: `test/data/bean/file_bean_repository_test.dart`

**Interfaces:**
- Consumes: `Bean`, `BeanRepository` (Task 1).
- Produces: `class FileBeanRepository implements BeanRepository` with constructor `FileBeanRepository(Directory directory, {Talker? talker})`; stores `<directory>/<id>.json`; `save` creates the directory if missing and overwrites an existing file for the same id; unreadable/invalid files are logged via `talker?.handle` and skipped.

- [ ] **Step 1: Write failing tests** (temp-directory setup identical to `test/data/shot/file_shot_repository_test.dart`):
  - `list` is empty before any save (directory does not exist yet).
  - save two beans named `'brazil'` and `'Ethiopia'`; `list()` returns `['brazil', 'Ethiopia']` (case-insensitive name order); `get(id)` returns an equal bean; `get('missing')` is null.
  - saving a bean again with `archived: true` replaces it: `list()` still has one entry and it is archived (archived beans are included in `list`).
  - a file `broken.json` containing `not json` and a file `notes.txt` in the directory: `list()` still returns the valid beans.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/data/bean/file_bean_repository_test.dart`
Expected: FAIL (class not defined).

- [ ] **Step 3: Implement `FileBeanRepository`** by mirroring `lib/data/shot/file_shot_repository.dart`; sort in `list()` by `name.toLowerCase()`.

- [ ] **Step 4: Run to verify pass**

Run: `fvm flutter test test/data/bean && fvm flutter analyze`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/bean test/data/bean
git commit -m "feat: store beans as JSON files"
```

---

### Task 3: Bean and dose on RecordedShot, brew ratio

**Files:**
- Modify: `lib/domain/shot/recorded_shot.dart`
- Create: `lib/domain/shot/brew_ratio.dart`
- Test: `test/domain/shot/recorded_shot_test.dart`, `test/domain/shot/brew_ratio_test.dart`

**Interfaces:**
- Consumes: `Bean` (Task 1).
- Produces (`RecordedShot`): new fields `final String? beanId`, `final double? doseGrams` (both optional named constructor params); `RecordedShot.create(ShotSnapshot snapshot, {String? beanId, double? doseGrams, DateTime? now})`; `formatVersion = 2`; `toJson()` additionally writes `beanId` and `doseGrams`; `fromJson` reads them as nullable (absent in version 1 files); `Map<String, dynamic> toExportJson({Bean? bean})` = `toJson()` plus `'bean': bean?.toJson()`; `double? get ratio` = `brewRatio(outputGrams: snapshot.summary.finalWeight, doseGrams: doseGrams)`. `fromJson` ignores a `bean` key.
- Produces (`brew_ratio.dart`): `double? brewRatio({double? outputGrams, double? doseGrams})` — null when either is null, or dose ≤ 0, or output ≤ 0; otherwise `outputGrams / doseGrams`. `String formatBrewRatio(double? ratio)` — `'1 : 2.1'` style (`'1 : ${ratio.toStringAsFixed(1)}'`), `'--'` for null.

- [ ] **Step 1: Write failing tests**
  - `brew_ratio_test.dart`: `brewRatio(outputGrams: 37.8, doseGrams: 18.0)` is `closeTo(2.1, 0.001)`; null for null output, null dose, dose 0, output 0 (no `Infinity`/`NaN` ever returned); `formatBrewRatio(2.1) == '1 : 2.1'`, `formatBrewRatio(null) == '--'`, `formatBrewRatio(1.96) == '1 : 2.0'`.
  - `recorded_shot_test.dart` (build a snapshot like `_snapshot()` in the file repository test with `finalWeight: 36.0`): round trip with `beanId: 'b1', doseGrams: 18.0` preserves both and `ratio == 2.0`; round trip without them gives nulls and `ratio == null`; `fromJson` of a map built from `toJson()` with `version: 1` and the two keys removed loads with nulls; `toExportJson(bean: bean)['bean']` equals `bean.toJson()` and `toExportJson()['bean']` is null; `toJson()` has no `bean` key; `RecordedShot.formatVersion == 2`.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/domain/shot/recorded_shot_test.dart test/domain/shot/brew_ratio_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement** the changes above. Existing callers of `RecordedShot(...)`/`create` keep compiling because the new params are optional.

- [ ] **Step 4: Run the whole suite**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS (including the existing `file_shot_repository_test.dart`).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/shot test/domain/shot
git commit -m "feat: record bean and dose on shots, add brew ratio"
```

---

### Task 4: Selection and Unknown-bean dose in settings

**Files:**
- Modify: `lib/domain/settings/settings_repository.dart`, `lib/data/settings/shared_preferences_settings_service.dart`
- Create: `test/support/fake_settings.dart`
- Test: `test/data/settings/shared_preferences_settings_service_test.dart`

**Interfaces:**
- Consumes: `defaultDoseGrams`, `normalizeDose` (Task 1).
- Produces on `SettingsRepository`: `String? get selectedBeanId`; `Future<void> setSelectedBeanId(String? id)` (null removes the key); `double get unknownBeanDoseGrams` (default `defaultDoseGrams`, normalized on read); `Future<void> setUnknownBeanDoseGrams(double grams)`.
- Produces: `class FakeSettings implements SettingsRepository` in `test/support/fake_settings.dart`, in-memory, with the pre-existing members returning defaults (`startDelayCompensationSeconds` 0, `ScaleSource.mock`, `PressureSource.mock`) and the new members stored in plain fields (`selectedBeanId`, `unknownBeanDoseGrams`, both writable via the setters).

- [ ] **Step 1: Write failing tests** using `SharedPreferences.setMockInitialValues({})` and `SharedPreferencesSettingsService.create()`: `selectedBeanId` is null by default, round-trips `'abc'`, and is null again after `setSelectedBeanId(null)`; `unknownBeanDoseGrams` is `18.0` by default, round-trips `17.5`, and a stored `99.0` reads as `30.0`.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/data/settings`
Expected: FAIL.

- [ ] **Step 3: Implement** the four members in the interface and `SharedPreferencesSettingsService` (keys `selectedBeanId`, `unknownBeanDoseGrams`), plus `FakeSettings`. `SharedPreferencesSettingsService` is the only implementer in `lib/`, so nothing else needs updating.

- [ ] **Step 4: Run to verify pass**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/settings lib/data/settings test/data/settings test/support
git commit -m "feat: persist selected bean and unknown-bean dose in settings"
```

---

### Task 5: BeansCubit

**Files:**
- Create: `lib/ui/beans/beans_cubit.dart`, `lib/ui/beans/beans_state.dart` (`part of` the cubit file, per project convention)
- Test: `test/ui/beans/beans_cubit_test.dart`

**Interfaces:**
- Consumes: `Bean`, `BeanRepository`, `SettingsRepository`, `normalizeDose`, `defaultDoseGrams`, `InMemoryBeanRepository`, `FakeSettings`.
- Produces: `class BeansState extends Equatable` with `bool loaded` (false initially), `List<Bean> beans` (non-archived only, name order), `String? selectedBeanId`, `double doseGrams`, getter `Bean? get selectedBean`. `class BeansCubit extends Cubit<BeansState>` with constructor `BeansCubit(BeanRepository beans, SettingsRepository settings)` and:
  - `Future<void> load()` — reads beans and `settings.selectedBeanId`; if the id is not among non-archived beans the selection becomes null; dose is the selected bean's `doseGrams`, or `settings.unknownBeanDoseGrams` when null; sets `loaded: true`.
  - `Future<void> select(String? beanId)` — updates state (ignore ids not in `beans`, treat as null), persists via `settings.setSelectedBeanId`, dose follows the newly selected bean's remembered dose.
  - `Future<void> setDose(double grams)` — `normalizeDose`, emits, persists on the selected bean (`beans.save(bean.copyWith(doseGrams: …))`, and the updated bean replaces the one in `state.beans`) or via `settings.setUnknownBeanDoseGrams` when Unknown bean is selected.
  - `Future<Bean> addBean({required String name, String? roaster, required int roastLevel, String? notes})` — creates with `Bean.create`, saves, adds to state; selection unchanged.
  - `Future<void> updateBean(Bean bean)` — saves and replaces in state; if it is the selected bean, `doseGrams` follows `bean.doseGrams`.
  - `Future<void> archiveBean(String id)` — saves the bean with `archived: true`, removes it from state; if it was selected, selection becomes null (persist `setSelectedBeanId(null)`) and dose becomes the Unknown-bean dose.

- [ ] **Step 1: Write failing tests** with `bloc_test`/`flutter_test` against `InMemoryBeanRepository` and `FakeSettings`:
  - `load` with no beans: `loaded` true, `selectedBeanId` null, `doseGrams == 18.0`.
  - `load` restores the stored selection and that bean's dose (bean saved with `doseGrams: 17.0`, settings `selectedBeanId` set → state dose 17.0); archived beans are not in `state.beans`.
  - `load` with a stored `selectedBeanId` pointing at a missing id, and another pointing at an archived bean: selection null, dose = `settings.unknownBeanDoseGrams`.
  - Per-bean dose recall: two beans A and B; `select(A.id)`, `setDose(17.5)`, `select(B.id)` (dose 18.0), `setDose(19.0)`, `select(A.id)` → dose 17.5; `beans.beans[A.id]!.doseGrams == 17.5`.
  - Unknown bean has its own dose: `select(null)`, `setDose(16.0)` → `settings.unknownBeanDoseGrams == 16.0` and selecting a bean then null again shows 16.0.
  - `setDose(100)` emits 30.0; `setDose(1)` emits 5.0.
  - `select(A.id)` persists `settings.selectedBeanId == A.id`; `select('nonexistent')` falls back to null.
  - `addBean(name: ' Guji ', roastLevel: 2)` returns a bean named `'Guji'`, it is in `state.beans` and in the repository, selection unchanged.
  - `updateBean(existing.copyWith(name: 'New'))` changes the name in state and repository.
  - `archiveBean` of a non-selected bean removes it from state and marks it archived in the repository (still retrievable via `get`); `archiveBean` of the selected bean sets `selectedBeanId` null, `settings.selectedBeanId` null and dose to the Unknown-bean dose.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/ui/beans/beans_cubit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `BeansCubit` and `BeansState`** per the interface above.

- [ ] **Step 4: Run to verify pass**

Run: `fvm flutter test test/ui/beans && fvm flutter analyze`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/beans test/ui/beans
git commit -m "feat: add BeansCubit for bean list, selection and dose"
```

---

### Task 6: Beans tab, edit screen, navigation and app wiring

**Files:**
- Create: `lib/ui/beans/beans_screen.dart`, `lib/ui/beans/bean_edit_screen.dart`
- Modify: `lib/router.dart`, `lib/ui/scaffold/root_scaffold.dart`, `lib/main.dart`
- Test: `test/ui/beans/bean_edit_screen_test.dart`, `test/ui/beans/beans_screen_test.dart`

**Interfaces:**
- Consumes: `BeansCubit`/`BeansState` (Task 5), `Bean`, `FileBeanRepository` (Task 2).
- Produces:
  - `class BeansScreen extends StatelessWidget` — `BlocBuilder<BeansCubit, BeansState>` list of non-archived beans: title is the bean name, subtitle is roaster and roast label joined with ` · ` (roaster omitted when null); tapping pushes `/beans/<id>`; an "Add bean" `FloatingActionButton.extended` pushes `/beans/new`; empty state text `No beans yet`.
  - `class BeanEditScreen extends StatefulWidget` with constructor `BeanEditScreen({super.key, String? beanId})` — `beanId == null` means add. Fields: Name (required), Roaster, Roast profile `Slider(min: 1, max: 5, divisions: 4)` with `label: Bean.roastLabel(level)` and "Light"/"Dark" end captions, Notes (multi-line). A `Save` action is disabled while `name.trim()` is empty. Editing shows an `Archive bean` button which opens a confirmation dialog (`Archive` / `Cancel`) and on confirm calls `archiveBean` and pops. Save calls `addBean` or `updateBean(existing.copyWith(...))` then pops. If `beanId` is not found in `state.beans`, show `Bean not found`.
  - Routes in `AppRouter`: new `static const beansPath = '/beans'`; a fourth `StatefulShellBranch` with its own navigator key between History and Settings: `GoRoute(path: '/beans', builder: BeansScreen, routes: [GoRoute(path: 'new', …BeanEditScreen()), GoRoute(path: ':id', …BeanEditScreen(beanId: …))])` (`new` declared before `:id`).
  - `RootScaffold` items in order Home, History, Beans, Settings (Beans uses `Icons.grain` or similar; label `Beans`).
  - `main.dart`: build `FileBeanRepository(Directory('${documents}/beans'), talker: talker)`, expose it as `Provider<BeanRepository>.value`, and add `BlocProvider(create: (_) => BeansCubit(beanRepository, settings)..load())`.

- [ ] **Step 1: Write failing widget tests** (pump with `MaterialApp` + `BlocProvider<BeansCubit>.value` built on `InMemoryBeanRepository`/`FakeSettings`, plus a `GoRouter` stub or `Navigator` so pop works):
  - `bean_edit_screen_test.dart`: Save is disabled with an empty name and with `'   '`; entering `'Guji'` enables it; saving in add mode creates a bean with roast level 3 by default and stores trimmed text; dragging/setting the slider to 5 saves `roastLevel == 5` (drive the slider through `tester.widget<Slider>(...).onChanged!(5)` or a drag); in edit mode the fields are pre-filled and saving keeps the bean's `doseGrams`; tapping `Archive bean` then `Archive` archives the bean (repository entry has `archived == true`), `Cancel` leaves it untouched.
  - `beans_screen_test.dart`: shows `No beans yet` when empty; lists names with the `roaster · Light` style subtitle; an archived bean is not listed.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/ui/beans`
Expected: FAIL (screens not defined).

- [ ] **Step 3: Implement** the screens, router branch, scaffold items and `main.dart` wiring above. Keep widgets within the existing dark theme and card styling.

- [ ] **Step 4: Verify tests, analysis, and the app**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS. Then run `fvm flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true`, open the Beans tab, add, edit and archive a bean; the tab order is Home, History, Beans, Settings.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat: add Beans tab to manage beans"
```

---

### Task 7: Home bean selector and dose control

**Files:**
- Create: `lib/ui/home/bean_selector.dart`, `lib/ui/home/dose_selector.dart`
- Modify: `lib/ui/home/home.dart`
- Test: `test/ui/home/bean_selector_test.dart`, `test/ui/home/dose_selector_test.dart`

**Interfaces:**
- Consumes: `BeansCubit`/`BeansState`, `parseDose`, `doseStepGrams`, `Bean.roastLabel`.
- Produces:
  - `class BeanSelector extends StatelessWidget` — a `Card`/tile labelled `Bean` showing the selected bean's name with roaster and roast label as a second line, or `Unknown bean`; trailing dropdown arrow; tap opens a modal bottom sheet listing the non-archived beans (selected one has a check mark) followed by a last entry `Unknown bean`; picking an entry calls `select` and closes the sheet. With no beans the sheet shows only `Unknown bean`.
  - `class DoseSelector extends StatelessWidget` — labelled `Dose`; `IconButton(Icons.remove)`, the dose text `18.0 g` (one decimal), `IconButton(Icons.add)`; minus/plus call `setDose(state.doseGrams ∓ doseStepGrams)`; tapping the number opens a dialog with a numeric text field (initial text = current dose), `OK` calls `setDose(parseDose(text))` only when `parseDose` is non-null, `Cancel` or invalid text leaves the dose unchanged.
  - `HomeScreen` shows both between the readings row and START SHOT, inside a `SingleChildScrollView` so small phones do not overflow.

- [ ] **Step 1: Write failing widget tests** (`BlocProvider<BeansCubit>` over `InMemoryBeanRepository`/`FakeSettings`, `await cubit.load()` first):
  - `bean_selector_test.dart`: with no beans it shows `Unknown bean`; with beans `Guji` (roaster `Friedhats`, roast 1) and `Santos`, and `Guji` selected, it shows `Guji` and `Friedhats · Light`; tapping it shows the sheet with `Guji`, `Santos`, `Unknown bean`; tapping `Santos` selects it (`cubit.state.selectedBeanId`) and shows its remembered dose elsewhere through the cubit; tapping `Unknown bean` selects null; an archived bean is absent from the sheet.
  - `dose_selector_test.dart`: shows `18.0 g`; tap `Icons.add` → `18.1 g`; tap `Icons.remove` twice → `17.9 g`; at 30.0 g, `Icons.add` keeps `30.0 g`; tapping the number, entering `18,5` and `OK` → `18.5 g`; entering `abc` and `OK` leaves the dose unchanged; entering `99` and `OK` → `30.0 g`; `Cancel` leaves it unchanged.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/ui/home`
Expected: FAIL.

- [ ] **Step 3: Implement** the two widgets and wire them into `home.dart`.

- [ ] **Step 4: Verify tests, analysis, and the app**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS. In the mock-device app, pick a bean, change the dose, switch beans and back (each bean keeps its dose), restart the app (last bean and dose are restored), and confirm the Home screen does not overflow on a small simulator.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home test/ui/home
git commit -m "feat: select bean and dose on the home screen"
```

---

### Task 8: Save and export shots with bean and dose

**Files:**
- Modify: `lib/ui/shot/shot_screen.dart` (`_SaveShotButtonState._save`), `lib/ui/history/saved_shot_screen.dart` (`_share`)
- Test: `test/ui/shot/save_shot_button_test.dart`

**Interfaces:**
- Consumes: `BeansCubit` (Task 5), `RecordedShot.create`/`toExportJson` (Task 3), `BeanRepository` (Task 2, provided in `main.dart` by Task 6).
- Produces: saving reads `context.read<BeansCubit>().state` and calls `RecordedShot.create(snapshot, beanId: state.selectedBeanId, doseGrams: state.doseGrams)`. Sharing resolves `beanId` through `context.read<BeanRepository>().get(...)` (archived beans included) and writes `shot.toExportJson(bean: bean)` as the exported file.
- To make the save path testable, extract `_SaveShotButton` into a public `class SaveShotButton extends StatefulWidget` (same file, constructor `SaveShotButton(ShotSnapshot snapshot, {super.key})`).

- [ ] **Step 1: Write failing widget test** (`test/ui/shot/save_shot_button_test.dart`): providers for a recording fake `ShotRepository` (keeps saved shots in a list), `BeansCubit` with one bean `Guji` selected at dose 17.5; tap the save icon; the saved shot has `beanId == guji.id` and `doseGrams == 17.5`. Second case: Unknown bean selected with dose 16.0 saves `beanId == null` and `doseGrams == 16.0`.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/ui/shot/save_shot_button_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement** the extraction and both changes. The export change has no automated test beyond Task 3's `toExportJson` coverage; verify it manually in Step 4.

- [ ] **Step 4: Verify**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS. In the mock-device app, record and save a shot, then use Share in history detail and confirm the JSON contains `beanId`, `doseGrams` and a full `bean` object (and `"bean": null` for Unknown bean).

- [ ] **Step 5: Commit**

```bash
git add lib/ui test/ui/shot
git commit -m "feat: store bean and dose on saved shots and embed bean in export"
```

---

### Task 9: History list and detail

**Files:**
- Create: `lib/ui/history/shot_bean_labels.dart`
- Modify: `lib/ui/history/history_cubit.dart`, `lib/ui/history/history.dart`, `lib/ui/history/saved_shot_screen.dart`
- Test: `test/ui/history/shot_bean_labels_test.dart`, `test/ui/history/history_cubit_test.dart`

**Interfaces:**
- Consumes: `RecordedShot` (`beanId`, `doseGrams`, `ratio`), `Bean`, `BeanRepository`, `ShotRepository`, `formatBrewRatio`.
- Produces (`shot_bean_labels.dart`):
  - `const unknownBeanLabel = 'Unknown bean'`
  - `String beanNameFor(RecordedShot shot, Bean? bean)` — `bean.name` when `bean != null`, else `unknownBeanLabel`.
  - `String formatDose(double? grams)` — `'18.0 g'` or `'--'`.
  - `String? historySubtitle(RecordedShot shot, Bean? bean)` — `null` when `beanId == null && doseGrams == null` (old shot); otherwise `'<beanNameFor> · <formatDose>'` (dose part omitted when `doseGrams` is null).
- Produces: `class HistoryEntry { final RecordedShot shot; final Bean? bean; }` and `HistoryCubit extends Cubit<List<HistoryEntry>?>` with constructor `HistoryCubit(ShotRepository shots, BeanRepository beans)`; `load()` reads shots and all beans (archived included) once and pairs each shot with `beans[shot.beanId]` (null when `beanId` is null or unresolvable).
- `HistoryScreen` creates the cubit with both repositories (`context.read`), rows keep the date as title and add `historySubtitle` as `subtitle` when non-null.
- `SavedShotScreen` body becomes a scroll view (`ListView`/`SingleChildScrollView`) containing, in order: the unchanged `ShotSummaryWidget`, the `ShotGraph` in a `SizedBox` of fixed height (about 300), a bean card (`beanNameFor`, with roaster and roast label as second line when the bean is resolved), and a row of three cards: dose (`formatDose`), weight out (`'<finalWeight> g'` or `--`), ratio (`formatBrewRatio(shot.ratio)`). The bean is resolved with `BeanRepository.get(shot.beanId!)` when `beanId != null`.

- [ ] **Step 1: Write failing tests**
  - `shot_bean_labels_test.dart`: shot with `beanId: 'b1', doseGrams: 18.0` and a resolved bean `Guji` → subtitle `'Guji · 18.0 g'`; same shot with `bean: null` (archived beans resolve, so null means missing) → `'Unknown bean · 18.0 g'`; shot with `beanId: null, doseGrams: 18.0` → `'Unknown bean · 18.0 g'`; shot with neither → `null`; `formatDose(null) == '--'`, `formatDose(18.04) == '18.0 g'`; `beanNameFor(shot, null) == 'Unknown bean'`.
  - `history_cubit_test.dart` (in-memory/fake repositories): a shot referencing an **archived** bean is paired with that bean; a shot referencing an id that does not exist is paired with null; a shot with `beanId: null` is paired with null; a version-1-style shot (both null) loads and is listed.

- [ ] **Step 2: Run to verify failure**

Run: `fvm flutter test test/ui/history`
Expected: FAIL.

- [ ] **Step 3: Implement** the helpers, cubit change and both screens. Add a small in-memory `ShotRepository` fake next to the test if none exists.

- [ ] **Step 4: Verify**

Run: `fvm flutter test && fvm flutter analyze`
Expected: PASS. In the mock-device app: list rows show `<bean> · <dose>`; detail scrolls, still shows the four metrics (Grams, g/s, Bar, Seconds), and shows bean, dose and ratio; archive a bean and confirm its old shots still show its name; an old shot saved before this feature shows no subtitle in the list and `Unknown bean` with `--` dose and ratio in the detail.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/history test/ui/history
git commit -m "feat: show bean, dose and ratio in history"
```

---

### Task 10: Documentation and final verification

**Files:**
- Modify: `CLAUDE.md`, `README.md`

- [ ] **Step 1: Update `CLAUDE.md`**: mention `lib/domain/bean/` (`Bean`, `BeanRepository`, dose rules), `FileBeanRepository` in the data layer, `BeansCubit` in the UI layer (app-wide, created in `main()`), the Beans tab in Navigation, and that `RecordedShot` now carries `beanId`/`doseGrams` (version 2). Remove the sentence claiming there is no persistence if README/CLAUDE.md still say so for beans; in `README.md` remove any future-plans item this feature covers.

- [ ] **Step 2: Full verification**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no analyzer issues.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "docs: document beans and dose"
```
