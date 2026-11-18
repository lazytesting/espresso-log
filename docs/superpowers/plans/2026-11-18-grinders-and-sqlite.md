# Grinders & SQLite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move beans and shots from JSON files to SQLite (`drift`), then add grinders with a per-bean+grinder remembered grind size, shown and saved with shots.

**Architecture:** `lib/data/db/` holds one `AppDatabase` (drift). `DriftBeanRepository`, `DriftShotRepository`, `DriftGrinderRepository`, `DriftGrindMemoryRepository` implement domain ports; `main()` is the only place that wires them. A new app-wide `GrindersCubit` owns grinder list, selection and grind size, and cooperates with `BeansCubit`. Existing JSON files are imported once, then their folders are renamed.

**Tech Stack:** Flutter (FVM 3.47.9), `drift`, `drift_flutter`, `drift_dev` (dev), `flutter_bloc`, `mockito`/`bloc_test`.

**Spec:** `docs/superpowers/specs/2026-11-18-grinders-and-sqlite-design.md`

## Global Constraints

- Prefix every Flutter/Dart command with `fvm`. Run `fvm flutter analyze` and `fvm flutter test` green before each commit.
- `lib/domain/` must not import `drift` or any storage package. Cubits/UI must not import `lib/data/`.
- Setting types: `numeric` 1-10; `coarse_fine` coarse 1-10 + fine A-F, text form `"3C"`.
- Settings (`SettingsRepository`) stay in `shared_preferences`; only beans, shots, grinders, grind memory go to SQLite.
- Mobile targets only. Generated drift code (`*.g.dart`) is checked in, like mocks.
- Shot `formatVersion` becomes 3; v1 and v2 files still load/import.
- Commit messages: Conventional Commits, ending with the attribution line the session specifies.

## Review Focus

- Old v1/v2 shot JSON (no grinder, no dose) imports and displays with "Unknown grinder" and no grind cell.
- Grinder archived while selected, or selected id in settings pointing at a missing/archived grinder at startup: selection falls back to none, old shots still show the grinder name.
- Unknown-bean grind memory: two `remember` calls for the same grinder with null bean leave exactly one row.
- Corrupt legacy JSON file: skipped and logged, rest imports; a shot whose bean file is missing imports with `bean_id` null.
- Invalid grind text (`"3G"`, `"11"`, `"0"`, `""`) is rejected by `GrindSetting.parse`, never throws.

---

## Task 1: Database foundation

**Files:**
- Modify: `pubspec.yaml` (add `drift`, `drift_flutter`; dev `drift_dev`; use `fvm flutter pub add` for current versions)
- Create: `lib/data/db/app_database.dart` (+ checked-in `app_database.g.dart`)
- Test: `test/data/db/app_database_test.dart`

**Interfaces:**
- Produces: `AppDatabase(QueryExecutor e)` with `AppDatabase.memory()` for tests (`NativeDatabase.memory()`), `schemaVersion = 1`, foreign keys enabled via `beforeOpen` (`PRAGMA foreign_keys = ON`). Tables (all text ids): `Beans(id, name, roaster?, roastLevel, notes?, archived, doseGrams)`, `Grinders(id, name, brand, settingType, archived)`, `GrindMemory(grinderId FK, beanKey, setting, lastUsedAt int millis; primary key (grinderId, beanKey))` where `beanKey` is the bean id or `''` for unknown bean (no FK; the builder's call to satisfy the spec's one-null-row rule), `Shots(id, recordedAt, beanId? FK, grinderId? FK, grindSetting? text, doseGrams?, finalWeight?, durationMillis, snapshotJson text)`.

- [ ] **Step 1: Write failing test** `inserting a shot with unknown beanId fails (foreign keys on)` and `inserting grind memory twice with same (grinderId, beanKey) violates the primary key`. Expect both to throw.
- [ ] **Step 2: Run** `fvm flutter test test/data/db/app_database_test.dart` — FAIL (file missing).
- [ ] **Step 3: Add deps, define tables and `AppDatabase`; run** `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4: Run test** — PASS. Run `fvm flutter analyze`.
- [ ] **Step 5: Commit** `feat: add drift database schema`

## Task 2: DriftBeanRepository

**Files:**
- Create: `lib/data/bean/drift_bean_repository.dart`
- Test: `test/data/bean/drift_bean_repository_test.dart` (port the cases from `test/data/bean/file_bean_repository_test.dart`)

**Interfaces:**
- Consumes: `AppDatabase`, domain `BeanRepository`/`Bean`.
- Produces: `DriftBeanRepository(AppDatabase db) implements BeanRepository` — `save` upserts, `list` returns all incl. archived sorted by lowercase name, `get(id)` returns null when absent.

- [ ] **Step 1: Write failing tests** copied from the file repo test, run against `AppDatabase.memory()`: save+get round trip equals the bean; `list` includes archived and sorts `"b"`, `"A"` as `A, b`; `get('nope')` is null.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** with drift companion upsert (`insertOnConflictUpdate`).
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: drift bean repository`

## Task 3: Shot list without snapshots + DriftShotRepository

**Files:**
- Create: `lib/domain/shot/shot_list_item.dart`, `lib/data/shot/drift_shot_repository.dart`
- Modify: `lib/domain/shot/shot_repository.dart`, `lib/ui/history/history_cubit.dart`, `lib/ui/history/history.dart`, `test/support/in_memory_shot_repository.dart`, `test/ui/history/*` as needed to compile
- Test: `test/data/shot/drift_shot_repository_test.dart`

**Interfaces:**
- Produces: `class ShotListItem { String id; DateTime recordedAt; String? beanId; String? grinderId; String? grindSetting; double? doseGrams; double? finalWeight; int durationMillis; }`. `ShotRepository.list()` now returns `Future<List<ShotListItem>>` newest first; `get(id)` still returns full `RecordedShot`. `HistoryEntry` holds `ShotListItem item` instead of `RecordedShot shot`; `_HistoryRow` reads `finalWeight`/`durationMillis` from it. `DriftShotRepository(AppDatabase db) implements ShotRepository`; `save` stores `jsonEncode(shot.snapshot.toJson())` in `snapshotJson` and copies `summary.finalWeight`/`durationMillis` into columns; the `list` query selects explicit columns and never `snapshotJson` (use `db.selectOnly`/`.map` on columns).
- Note: `grinderId`/`grindSetting` columns exist but are populated in Task 7; `ShotListItem` already carries them (null until then).

- [ ] **Step 1: Write failing tests:** save then `get` returns an equal snapshot (weight/pressure points, summary); `list` returns newest first with `finalWeight` and `durationMillis` equal to the saved summary; `delete` removes the row and is a no-op for unknown id; a spy/inspection test that `list` items expose no snapshot (type-level: `ShotListItem` has no snapshot field).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** the repository, `ShotListItem`, interface change, and update `HistoryCubit`/`history.dart`/in-memory repo until `fvm flutter analyze` is clean.
- [ ] **Step 4: Run** `fvm flutter test test/data/shot test/ui/history` — PASS.
- [ ] **Step 5: Commit** `feat: drift shot repository, history list reads summary only`

## Task 4: Legacy file importer

**Files:**
- Create: `lib/data/db/legacy_file_importer.dart`
- Test: `test/data/db/legacy_file_importer_test.dart` (temp dirs via `Directory.systemTemp.createTemp`)

**Interfaces:**
- Consumes: `AppDatabase`, `Bean.fromJson`, `RecordedShot.fromJson`, `Talker?`.
- Produces: `LegacyFileImporter(AppDatabase db, Directory documents, {Talker? talker})` with `Future<void> run()`. Reads `<documents>/beans/*.json` and `<documents>/shots/*.json`, inserts in **one transaction** (beans first, then shots), then renames the folders to `beans.imported` / `shots.imported`. Idempotent: `insertOrIgnore` by id, and no-op when neither source folder exists. Unreadable file → `talker.handle`, skipped. Shot whose `beanId` has no imported bean → inserted with `beanId` null. If the transaction throws, nothing is renamed or deleted.

- [ ] **Step 1: Write failing tests:** imports 2 beans and 2 shots (one v1 file without `beanId`/`doseGrams`) and the folders are renamed; a corrupt file is skipped and the others import; shot with missing bean imports with null `beanId`; second `run()` after rename changes nothing; a failure inside the transaction (run against an already-closed `AppDatabase`) throws and leaves both folders un-renamed.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** `run()`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: import legacy bean and shot files into drift`

## Task 5: Wire drift in main, remove file repositories

**Files:**
- Modify: `lib/main.dart`
- Delete: `lib/data/bean/file_bean_repository.dart`, `lib/data/shot/file_shot_repository.dart`, `test/data/bean/file_bean_repository_test.dart`, `test/data/shot/file_shot_repository_test.dart`

**Interfaces:**
- Consumes: Tasks 1-4. `main()` opens `AppDatabase(driftDatabase(name: 'espresso_log'))`, awaits `LegacyFileImporter(...).run()`, provides `DriftBeanRepository`/`DriftShotRepository` as `BeanRepository`/`ShotRepository`.

- [ ] **Step 1: Make the change.**
- [ ] **Step 2: Run** `fvm flutter analyze && fvm flutter test` — all green.
- [ ] **Step 3: Verify in the app** (`fvm flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true`): existing beans and History shots still appear, and saving a new shot lists in History. Report if it cannot be run.
- [ ] **Step 4: Commit** `refactor: store beans and shots in sqlite`

## Task 6: Grinder domain and persistence

**Files:**
- Create: `lib/domain/grinder/grind_setting.dart`, `lib/domain/grinder/grinder.dart`, `lib/domain/grinder/grinder_repository.dart`, `lib/domain/grinder/grind_memory_repository.dart`, `lib/data/grinder/drift_grinder_repository.dart`, `lib/data/grinder/drift_grind_memory_repository.dart`, `test/support/in_memory_grinder_repository.dart`, `test/support/in_memory_grind_memory_repository.dart`
- Test: `test/domain/grinder/grind_setting_test.dart`, `test/domain/grinder/grinder_test.dart`, `test/data/grinder/drift_grinder_repository_test.dart`, `test/data/grinder/drift_grind_memory_repository_test.dart`

**Interfaces (Produces):**
```dart
enum GrindSettingType { numeric, coarseFine }          // stored as .name

class GrindSetting extends Equatable {
  final GrindSettingType type;
  final int coarse;        // 1..10 (numeric uses this as the value)
  final String? fine;      // 'A'..'F' for coarseFine, else null
  const GrindSetting.numeric(int value);               // asserts 1..10
  const GrindSetting.coarseFine(int coarse, String fine);
  static GrindSetting defaultFor(GrindSettingType t);  // numeric 5, coarseFine 5A
  static GrindSetting? parse(GrindSettingType t, String text); // null if invalid
  String get text;                                     // "5" / "3C"
  GrindSetting stepped(int delta);   // coarseFine steps A..F then next coarse; clamped at 1/10 A..10 F
}

class Grinder extends Equatable {   // id, name, brand, settingType, archived
  factory Grinder.create({required String name, required String brand,
      required GrindSettingType settingType, DateTime? now}); // trims; id = microsecondsSinceEpoch string
  factory Grinder.fromJson(Map<String, dynamic>); Map<String, dynamic> toJson();
  Grinder copyWith({String? name, String? brand, bool? archived}); // type is fixed after creation (author's call)
}

abstract class GrinderRepository {
  Future<void> save(Grinder g);
  Future<List<Grinder>> list();      // incl. archived, sorted by lowercase name
  Future<Grinder?> get(String id);
}

class GrindMemoryEntry { String grinderId; String? beanId; GrindSetting setting; DateTime lastUsedAt; }
abstract class GrindMemoryRepository {
  Future<GrindSetting?> settingFor({required String grinderId, String? beanId});
  Future<void> remember({required String grinderId, String? beanId,
      required GrindSetting setting, DateTime? now}); // upsert, sets lastUsedAt
  Future<List<GrindMemoryEntry>> entriesFor(String grinderId); // newest lastUsedAt first
}
```
`DriftGrindMemoryRepository` parses stored text using the grinder's `settingType` (join on `Grinders`); `beanKey = beanId ?? ''`.

- [ ] **Step 1: Write failing tests:**
  - `GrindSetting`: `parse(numeric,'5').text=='5'`; `parse(coarseFine,'3C').text=='3C'`; `parse(coarseFine,'3c')` equals `3C` (case-insensitive); `parse` returns null for `'11'`,`'0'`,`''`,`'3G'`, and numeric `'3C'`; `coarseFine(3,'F').stepped(1)==coarseFine(4,'A')`; `numeric(10).stepped(1)==numeric(10)`; `coarseFine(1,'A').stepped(-1)` unchanged; `defaultFor` values.
  - `Grinder`: json round trip; `create` trims name/brand.
  - Grinder repo: round trip, archived included in `list`, sorted case-insensitively.
  - Grind memory repo: `remember` twice for same grinder with `beanId: null` keeps one row in `entriesFor` and the second setting wins; `entriesFor` orders by `lastUsedAt` newest first; `settingFor` of unknown pair is null; coarseFine value round trips as `3C`.
- [ ] **Step 2: Run** `fvm flutter test test/domain/grinder test/data/grinder` — FAIL.
- [ ] **Step 3: Implement** all of the above including the two in-memory fakes (same semantics, no db).
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: grinder domain, grind settings and grind memory`

## Task 7: Shot grinder fields, export v3, selected-grinder setting

**Files:**
- Modify: `lib/domain/shot/recorded_shot.dart`, `lib/data/shot/drift_shot_repository.dart`, `lib/domain/settings/settings_repository.dart`, `lib/data/settings/shared_preferences_settings_service.dart`, `test/support/fake_settings.dart`
- Test: `test/domain/shot/recorded_shot_test.dart` (create if absent), `test/data/shot/drift_shot_repository_test.dart`, `test/data/settings/shared_preferences_settings_service_test.dart`

**Interfaces:**
- `RecordedShot` gains `String? grinderId`, `String? grindSetting` (display text such as `"3C"`), in constructor, `create`, `fromJson`, `toJson`; `formatVersion = 3`. `toExportJson({Bean? bean, Grinder? grinder})` adds `'grinder': grinder?.toJson()`.
- `SettingsRepository`: `String? get selectedGrinderId; Future<void> setSelectedGrinderId(String? id);` (null clears).
- `DriftShotRepository` persists/reads `grinderId`/`grindSetting`; unknown `grinderId` is a foreign-key error, so callers pass saved grinders only.

- [ ] **Step 1: Write failing tests:** v3 JSON round trip keeps grinder fields; v1 and v2 JSON (no grinder keys) load with nulls; `toExportJson` includes `bean` and `grinder`; drift repo round trips grinder id + `"3C"`, and `list` items expose them; settings `selectedGrinderId` set/clear round trip.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `fvm flutter test` — PASS.
- [ ] **Step 5: Commit** `feat: store grinder and grind size on shots`

## Task 8: GrindersCubit

**Files:**
- Create: `lib/ui/grinders/grinders_cubit.dart`, `lib/ui/grinders/grinders_state.dart` (`part of`)
- Test: `test/ui/grinders/grinders_cubit_test.dart` (in-memory fakes, real `BeansCubit` over `InMemoryBeanRepository` + `FakeSettings`)

**Interfaces:**
- Consumes: `GrinderRepository`, `GrindMemoryRepository`, `SettingsRepository`, `BeansCubit` (subscribes to its stream, reacting only when `selectedBeanId` changes).
- Produces:
```dart
class GrindersState extends Equatable {  // loaded, grinders (non-archived, name order), selectedGrinderId, GrindSetting? setting
  Grinder? get selectedGrinder;
}
class GrindersCubit extends Cubit<GrindersState> {
  GrindersCubit(GrinderRepository, GrindMemoryRepository, SettingsRepository, BeansCubit);
  Future<void> load();                       // call after BeansCubit.load()
  Future<void> select(String? grinderId);
  Future<void> setSetting(GrindSetting s);
  Future<Grinder> addGrinder({required String name, required String brand, required GrindSettingType settingType});
  Future<void> updateGrinder(Grinder g);
  Future<void> archiveGrinder(String id);
}
```
Behavior: `load` restores `selectedGrinderId` from settings, falling back to null if missing/archived, then loads that pair's setting for the current bean. `select(id)` stores `selectedGrinderId`, picks the bean of that grinder's newest memory row whose bean is non-archived (null-bean row = Unknown bean → `beansCubit.select(null)`; no rows = leave bean alone), then loads the pair's setting or `GrindSetting.defaultFor(type)`. A bean change while a grinder is selected loads the pair's setting, creating the row with the default and `lastUsedAt` set when none exists. `setSetting` upserts via `remember` (bean key null when no bean selected) and emits. No grinder selected: `setting` null, `setSetting` is a no-op. `archiveGrinder` of the selected one clears selection and setting.

- [ ] **Step 1: Write failing tests** (one per behavior sentence above): `load restores selected grinder`; `load ignores archived selected grinder`; `select picks last used bean and its remembered grind size`; `select with newest row unknown bean selects unknown bean`; `select skips archived bean for next newest row`; `select with no history keeps bean and uses default setting`; `bean change loads that pair's size`; `bean change creates default row for new pair`; `setSetting with unknown bean stores one row per grinder`; `no grinder selected leaves setting null and setSetting does nothing`; `archive selected grinder clears selection`; `addGrinder appears sorted`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement**, using `beansCubit.stream` subscription closed in `close()`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: grinders cubit with remembered grind size`

## Task 9: Grinder management screens and wiring

**Files:**
- Create: `lib/ui/grinders/grinders_screen.dart`, `lib/ui/grinders/grinder_edit_screen.dart`
- Modify: `lib/router.dart` (routes `/settings/grinders`, `/settings/grinders/new`, `/settings/grinders/:id` inside the Settings branch; author's call to avoid a fifth tab), `lib/ui/settings/settings.dart` (a "Grinders" list tile), `lib/main.dart` (create the grinder/grind-memory drift repos, `GrindersCubit(...)` loaded after `BeansCubit.load()`, provide `GrinderRepository` via `Provider`)
- Test: `test/ui/grinders/grinders_screen_test.dart`, `test/ui/grinders/grinder_edit_screen_test.dart`, update `test/ui/settings/settings_test.dart`

**Interfaces:**
- Consumes: `GrindersCubit`. Mirror `BeansScreen`/`BeanEditScreen` (plain add button, list rows, archive action). Edit form: name (required), brand (required), setting type choice (numeric / coarse + fine). The type control is disabled when editing an existing grinder. Save disabled while name or brand is blank.

- [ ] **Step 1: Write failing widget tests:** list shows names with brand; add flow creates a grinder (name, brand, type) and returns to list; edit changes name/brand; type control disabled on edit; archive removes the row; save disabled with blank name; Settings shows a Grinders tile that navigates to the list.
- [ ] **Step 2: Run** `fvm flutter test test/ui/grinders test/ui/settings` — FAIL.
- [ ] **Step 3: Implement screens, routes, settings tile, main wiring.**
- [ ] **Step 4: Run** `fvm flutter analyze && fvm flutter test` — PASS.
- [ ] **Step 5: Commit** `feat: manage grinders`

## Task 10: Home grinder and grind size rows

**Files:**
- Create: `lib/ui/home/grinder_selector.dart`, `lib/ui/home/grind_size_selector.dart`
- Modify: `lib/ui/home/home.dart` (card order: Grinder, Grind size, Bean, Dose; author's call: grinder first so its last bean restores before the bean row is read)
- Test: `test/ui/home/grinder_selector_test.dart`, `test/ui/home/grind_size_selector_test.dart`, update `test/ui/home/home_test.dart`

**Interfaces:**
- `GrinderSelector`: same look and bottom sheet as `BeanSelector` (label via `SetupLabel('Grinder')`); entries are non-archived grinders with brand as subtitle, an "Unknown grinder" entry, and an "Add grinder" entry that pushes `/settings/grinders/new`. `GrindSizeSelector`: row `SetupLabel('Grind')` with `-`/`+` buttons calling `setSetting(setting.stepped(∓1))` and the text from `GrindSetting.text`; tapping the text opens a picker to choose a value directly (numeric: 1-10; coarse+fine: two dropdowns), the control style is the builder's call. Row is hidden when no grinder is selected.

- [ ] **Step 1: Write failing widget tests:** selector shows "Unknown grinder" when none selected; selecting a grinder in the sheet calls through to the cubit and shows its name; grind row hidden with no grinder; `+` on numeric `5` shows `6`; `+` on `3F` shows `4A`; picking a value in the picker sets it; Home shows rows in order Grinder, Grind, Bean, Dose (`tester.getTopLeft` y ordering).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `fvm flutter test test/ui/home` — PASS.
- [ ] **Step 5: Commit** `feat: grinder and grind size on home`

## Task 11: Save and show grinder on shot done

**Files:**
- Modify: `lib/ui/shot/shot_screen.dart` (~lines 50-55, 106-111), `lib/ui/shot/shot_result_view.dart`
- Test: `test/ui/shot/save_shot_button_test.dart`, `test/ui/shot/shot_result_view_test.dart`, `test/ui/shot/shot_screen_test.dart`

**Interfaces:**
- `ShotResultView` gains `Grinder? grinder` and `String? grindSetting`. Shows the grinder name (or `unknownGrinderLabel = 'Unknown grinder'` constant) in the header and a `MetricCell(label: 'Grind', value: grindSetting)` only when `grindSetting != null`. `RecordedShot.create(... grinderId: grinders.selectedGrinderId, grindSetting: grinders.setting?.text)` on save. The Save flow reads `GrindersCubit.state`.

- [ ] **Step 1: Write failing tests:** saving with grinder `Niche`, setting `3C` stores `grinderId` and `grindSetting == '3C'`; saving with no grinder stores nulls; `ShotResultView` shows `Niche` and `3C`; with null grinder shows `Unknown grinder` and no `Grind` label.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `fvm flutter test test/ui/shot` — PASS.
- [ ] **Step 5: Commit** `feat: save and show grinder on shot done`

## Task 12: History row, detail and export show grinder

**Files:**
- Modify: `lib/ui/history/history_cubit.dart` (`HistoryEntry` gains `Grinder? grinder`, loaded from `GrinderRepository`), `lib/ui/history/history.dart`, `lib/ui/history/saved_shot_screen.dart`, `lib/ui/history/shot_bean_labels.dart` (or new label file) 
- Test: `test/ui/history/history_cubit_test.dart`, `test/ui/history/history_screen_test.dart`, `test/ui/history/saved_shot_screen_test.dart`

**Interfaces:**
- `HistoryCubit(ShotRepository, BeanRepository, GrinderRepository)`; `HistoryScreen` passes `context.read<GrinderRepository>()`. History row adds a muted line `"<grinder name> · <grindSetting>"` (only the name when no setting; hidden when no grinder). `SavedShotScreen` loads the grinder (including archived) and passes it with `shot.grindSetting` to `ShotResultView`; share calls `toExportJson(bean:, grinder:)`.

- [ ] **Step 1: Write failing tests:** cubit maps `grinderId` to `Grinder` including an archived grinder; row shows `Niche · 3C`; old shot without grinder shows no grinder line; detail screen shows grinder and grind; share JSON (inspect the written file via a testable seam if one exists, otherwise unit-test `toExportJson` covered in Task 7) contains `grinder`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `fvm flutter analyze && fvm flutter test` — PASS.
- [ ] **Step 5: Commit** `feat: show grinder in history and shot detail`

## Task 13: Docs

**Files:**
- Modify: `README.md` (features: grinders and grind size; remove "Grinder settings" from future plans), `CLAUDE.md` (data layer now drift: `AppDatabase`, `Drift*Repository`, legacy importer, grinder domain, `GrindersCubit`, Home layout, shot `formatVersion` 3; remove `FileBeanRepository`/`FileShotRepository` mentions)

- [ ] **Step 1: Update both files.**
- [ ] **Step 2: Run** `fvm flutter analyze && fvm flutter test` — green.
- [ ] **Step 3: Commit** `docs: describe grinders and sqlite storage`
