# Grinders & SQLite storage — Design

**Date:** 2026-11-18
**Status:** Draft, awaiting user approval

## Intent

Let the user record which grinder and grind size a shot was pulled with, so
shots can be reproduced. At the same time, replace the file-per-entity JSON
storage with a relational store (SQLite via `drift`), because more entity types
and relations are coming (grinders now, tasting notes next) and this feature
already needs relation lookups that files serve poorly.

The app principle holds: no extra steps per shot. On a normal shot the last
used grinder, bean and grind size are already selected.

## Goals

- Manage grinders (add, edit, archive): name, brand, setting type.
- Setting types supported now: `numeric` (1-10) and `coarse_fine`
  (coarse 1-10 + fine A-F, e.g. "3C").
- Home: grinder dropdown first, grind size picker below it (per setting type),
  above/below the existing bean + dose rows (placement: builder's call).
- Remember the last grind size per bean+grinder pair.
- Selecting a grinder restores the last bean used with that grinder.
- Save grinder and grind size with a shot; show both on shot done, History
  detail and the History list row.
- Move beans, shots and grinders to SQLite (`drift`), with a one-time import of
  existing bean and shot JSON files.

## Non-goals

- No hard delete of grinders; no UI to view or restore archived grinders
  (same as beans).
- No editing grinder or grind size on an already-saved shot.
- No filtering/grouping of History by grinder or bean (the store makes it
  possible later).
- No further setting types (stepless RPM, clicks with decimals) now; the type
  must be extensible.
- Settings (scale/pressure source, start delay, selected ids, unknown-bean
  dose) stay in `shared_preferences`.

## Anti-goals

- Selecting a grinder or grind size must never be required to start or save a
  shot.
- Archiving a grinder or bean must never break or blank an old shot.
- Existing saved shots and beans must not be lost or fail to load. A failed
  import must not delete the source files.
- Cubits/UI must not depend on `drift` types; only `lib/data/` does.

## Constraints

- Domain layer stays free of storage packages. `BeanRepository` and
  `ShotRepository` interfaces stay; add `GrinderRepository` and a port for the
  grind memory. New `drift` implementations replace `FileBeanRepository` and
  `FileShotRepository` in `main()`.
- `RecordedShot` gets `grinderId` and `grindSetting`; `formatVersion` 3 for
  export JSON. Version 1 and 2 files still import/load.
- Share/export JSON keeps working; `toExportJson` embeds bean (and now grinder).
- Tests per project conventions; `build_runner` already in use for mocks and
  will also generate `drift` code (checked in or not: follow existing mock
  convention, i.e. checked in).

## Approaches considered

- **A. Keep files, add a grinder file repo and ad-hoc lookup files.** Cheap,
  but relations are hand-maintained, no integrity, History list reads every
  full shot file, and each new entity adds more ad-hoc lookups.
- **B. SQLite (`drift`) for everything. (Chosen.)** Keyed lookups, foreign
  keys, queries, small list reads. Costs: dependency, schema migrations, a
  one-time import.
- **C. Hybrid (SQLite for entities, files for shots).** Two stores and shot
  queries still need file scans. Rejected.

Sub-decision, snapshot storage: separate `shot_snapshot` table (safe list
queries by construction) vs. a blob column on `shot`. **Chosen by the user:
blob column on `shot`**, with list queries selecting explicit columns. Data
needed by the History list (final weight, shot time, etc.) is duplicated into
real columns on `shot` when needed; the blob stays the source of truth for the
full graph.

## Data model (sketch; builder owns exact columns)

- `beans`: id, name, roaster, roast_level, notes, archived, dose_grams.
- `grinders`: id, name, brand, setting_type, archived.
- `grind_memory`: bean_id (nullable = unknown bean), grinder_id, setting,
  last_used_at (the newest row per grinder is that grinder's last bean);
  uniqueness on (bean_id, grinder_id) with exactly one null-bean row per
  grinder (SQLite treats NULLs as distinct in unique keys; builder enforces,
  e.g. sentinel id or partial unique index).
- `shots`: id, recorded_at, bean_id (nullable FK), grinder_id (nullable FK),
  grind_setting (nullable text), dose_grams, duplicated summary columns needed
  by the History list (final weight, shot time), `snapshot_json` blob/text.
  List queries never select `snapshot_json`.

Domain: a `GrindSetting` value type per setting type with validation,
parsing and display ("5", "3C"); serialized as text in the store. Selected
grinder id lives in `SettingsRepository` like `selectedBeanId`.

## Behavior decisions

- Selecting a grinder: select the bean of that grinder's newest
  `grind_memory` row by `last_used_at` (a null-bean row means "Unknown bean";
  an archived bean is skipped for the next newest), then load that pair's grind
  size; if no rows, default is the setting type's midpoint/first value
  (builder's call).
- Selecting a bean with a grinder selected: load that pair's remembered grind
  size. If no row exists, create it with the default size. Set `last_used_at`
  either way.
- Changing grind size upserts the `grind_memory` row for the current pair and
  sets `last_used_at`.
- No grinder selected ("Unknown grinder") is allowed, same as unknown bean;
  grind size is then not recorded.
- Grinder selected with "Unknown bean" (decided by user): grind size is
  remembered per grinder alone. `grind_memory.bean_id` is nullable (or a
  sentinel); one "no bean" row per grinder. Picker always works; shot records
  the grind size.
- Changing a grinder's setting type after shots exist: out of scope; editing
  the type is disabled once the grinder has shots or memory rows (builder's
  call, may simply disable editing the type always).

## Migration

One-time on first launch after update: if `<documents>/beans` and
`<documents>/shots` JSON files exist and the DB is empty, import them in a
transaction, then keep the source folders (rename or leave in place; do not
delete). Idempotent: re-running must not duplicate rows. Unreadable files are
logged to Talker and skipped.

## Delivery order (one branch)

1. Introduce `drift` DB, `DriftBeanRepository`/`DriftShotRepository`, import
   from files, swap in `main()`. No behavior change.
2. Grinders: domain, repository, grinders screen (list/edit/archive), router
   entries, settings key.
3. Home grinder + grind size selectors, `BeansCubit`/new cubit changes, shot
   save, shot done + History display, export JSON v3.
4. README/CLAUDE.md updates.

## Calls made after the builder check (author's calls, open to correction)

- "Last bean per grinder" is derived from `grind_memory.last_used_at` (user's
  suggestion), not stored on `grinders`. It updates on bean select with a
  grinder selected, so restore-on-select works without saving a shot.
- Foreign keys are enforced. On import, a shot whose bean file is missing gets
  `bean_id` null; the shot itself still imports. Skipping unreadable files is
  per file; the import transaction as a whole is all-or-nothing.
- History list summary columns (final weight, shot time) are computed from the
  parsed JSON at import time. Ratio stays computed from dose and final weight,
  not stored.
- Export JSON is one-way (share only); no import-from-export, so no id merge
  policy.
- `schemaVersion = 1`, no migration test harness yet; add it with the first
  real schema change.
- Targets are mobile (iOS/Android) only; use `sqlite3_flutter_libs`.

## Left to the builder

Exact schema and column types, drift code layout, the grind size picker UI
(chips/wheel/two dropdowns), Home layout placement, default grind size, whether
a new `GrindersCubit` or an extended `BeansCubit` owns the selection state,
tests, and the file-import mechanics.
