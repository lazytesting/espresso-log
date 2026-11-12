# Beans & Dose — Design

**Date:** 2026-11-12
**Status:** Draft, awaiting user approval

## Intent

Let the user record which beans a shot was pulled with and how many grams of
coffee went in, so that saved shots can show the bean, the dose and the brew
ratio. The user typically keeps the same beans on the grinder for many shots
and only makes small dose tweaks between them; switching beans is the rarer
action. The app's principle of adding as few steps as possible to the espresso
workflow still holds: on a normal shot the user should not have to touch the
bean or dose at all, because the last-used values are already there.

## Goals

- Manage a list of beans (add, edit, archive) in a new **Beans** tab.
- On Home, pick a bean (or "Unknown bean") and set the dose in grams.
- Remember the dose per bean, and remember which bean was selected last.
- Save the bean and dose with a shot.
- Show bean and dose in the history list, and bean, dose and ratio on the
  history detail screen, which becomes scrollable.

## Non-goals

- No UI to view or restore archived beans.
- No hard delete of beans.
- No editing of the bean or dose on an already-saved shot.
- No filtering or grouping of history by bean.
- No grinder setting, roast date, origin or other bean fields beyond the four
  listed below.
- No change to how or when shots are saved (still the manual save button on
  the shot screen).

## Anti-goals

- Selecting a bean or entering a dose must never be required to start or save
  a shot.
- Archiving a bean must never break or blank out an old shot that references
  it.
- Shots saved before this feature must keep loading and displaying.

## Current state (for context)

- `lib/ui/home/home.dart` — three live reading widgets and the START SHOT
  button, in a `Column`.
- `lib/ui/scaffold/root_scaffold.dart` + `lib/router.dart` — three bottom
  tabs (Home, History, Settings), each a `StatefulShellBranch`.
- `lib/domain/shot/recorded_shot.dart` — `RecordedShot {id, recordedAt,
  snapshot}`, JSON `version: 1`. Stored one file per shot by
  `lib/data/shot/file_shot_repository.dart` under `<documents>/shots/`.
- `lib/ui/shot/shot_screen.dart` — `_SaveShotButton` calls
  `RecordedShot.create(snapshot)` and `ShotRepository.save`.
- `lib/ui/history/history.dart` — list rows show only the date.
- `lib/ui/history/saved_shot_screen.dart` — a `Column` with
  `ShotSummaryWidget` (Grams, peak g/s, peak Bar, Seconds) and an `Expanded`
  `ShotGraph`.

## What the user decided

### Beans

A bean has:

| Field | Rules |
|---|---|
| id | assigned by the app, never changes |
| name | mandatory |
| roaster | optional text |
| roast profile | a slider from light to dark with **5 steps** |
| notes | optional free text |

Beans are never removed. "Removing" a bean archives it: it no longer appears
in the Beans tab or in the Home bean picker, but shots that reference it still
show it.

### Navigation

Bottom tabs become **Home, History, Beans, Settings** (Beans third, Settings
last).

### Beans tab

- A list of non-archived beans. Each row shows the name, with roaster and
  roast level as a second line. Tapping a row opens the edit screen.
- An "Add bean" button opens the same screen, empty.
- The add/edit screen has Name, Roaster, the 5-step Roast profile slider
  labelled Light … Dark, Notes, and Save. When editing, it also has an
  "Archive bean" button, which asks for confirmation.

### Home screen

Between the live readings and START SHOT:

- A **Bean** row showing the selected bean (name, and roaster/roast as a
  second line). Tapping it opens a list of the non-archived beans, ending with
  **"Unknown bean"** for when the user does not want to pick a specific bean.
- A **Dose** control: minus button, the dose in grams with one decimal, plus
  button. Plus/minus change it by 0.1 g. Tapping the number lets the user type
  a value.
- The screen opens with the bean used last time and that bean's remembered
  dose. Selecting another bean shows that bean's remembered dose.
- The dose is stored per bean. "Unknown bean" remembers its own dose too.

### History

- **List:** each row keeps the date and gets a second line with the bean name
  and dose, e.g. "Ethiopia Guji · 18.0 g", or "Unknown bean · 18.0 g".
- **Detail:** the screen becomes scrollable (more data will be added here
  soon). It keeps the existing four-metric summary row unchanged (Grams, peak
  g/s, peak Bar, Seconds) and the graph, and adds below them:
  - the bean (name, roaster/roast as second line), or "Unknown bean";
  - the dose in grams;
  - the ratio, output weight / input weight, shown as `1 : 2.1`.

## Builder's calls (made by the designer, not confirmed by the user)

These follow existing patterns in the codebase. The user should glance over
them; a builder may refine them where the plan demands it.

### Domain and storage

- New `lib/domain/bean/`: `Bean` (`id`, `name`, `roaster?`, `roastLevel`,
  `notes?`, `archived`, `doseGrams`) with `fromJson`/`toJson`, and
  `BeanRepository`, a driven port like `ShotRepository`: `save(Bean)`,
  `list()` (all beans including archived; callers filter), `get(id)`.
- `roastLevel` is an int 1–5. Labels: 1 Light, 2 Medium-light, 3 Medium,
  4 Medium-dark, 5 Dark. A new bean starts at 3. The slider always has a
  value; there is no "roast not set".
- New `lib/data/bean/file_bean_repository.dart`: one `<id>.json` per bean
  under `<documents>/beans/`, mirroring `FileShotRepository` (unreadable files
  are logged and skipped).
- Bean ids are generated the same way as shot ids
  (`microsecondsSinceEpoch` as a string).
- The remembered dose lives on the bean itself (`doseGrams`). The selected
  bean id and the "Unknown bean" dose are added to `SettingsRepository` /
  `SharedPreferencesSettingsService` (`selectedBeanId`, nullable, null meaning
  Unknown bean; `unknownBeanDoseGrams`).
- Default dose for a new bean and for Unknown bean: **18.0 g**. Allowed range
  **5.0–30.0 g**, clamped; stored and compared at one-decimal precision.
- A dose change is persisted immediately (not only when a shot is saved).

### Shot record

- `RecordedShot` gains two optional fields: `beanId` (`String?`) and
  `doseGrams` (`double?`). JSON `formatVersion` goes to 2; version 1 files
  load with both fields null.
- **Decided by the user:** the saved shot references the bean by id only.
  Renaming a bean or changing its roast therefore changes how old shots
  display, which is fine.
- **Decided by the user:** the shared JSON export of a shot contains the full
  bean data, not just the id. Designer's call on how: the bean is looked up
  (archived beans included) when the user taps share and embedded in the
  exported JSON as a `bean` object (the bean's full `toJson()`), next to
  `beanId` and `doseGrams`. The shot file stored on the device stays id-only,
  and `RecordedShot.fromJson` ignores an embedded `bean`. For Unknown bean or
  an unresolvable id, `bean` is null.
- Bean and dose are attached at the moment the user taps save on the shot
  screen, taken from the current Home selection. (The shot screen is
  full-screen, so the selection cannot change during a shot.)
- Ratio = `summary.finalWeight / doseGrams`, one decimal, shown as
  `1 : 2.1`. If either value is missing (old shots, no final weight) the
  ratio shows `--`.
- Display for shots without bean data: a shot with `beanId == null` but a
  dose shows "Unknown bean"; a version 1 shot with neither shows no bean line
  in the list, and "Unknown bean" with `--` for dose and ratio on the detail
  screen. A `beanId` that cannot be resolved (file missing) also shows
  "Unknown bean".

### UI structure

- New `lib/ui/beans/` following the cubit-per-feature pattern. One app-wide
  `BeansCubit`, created in `main()` like the other top-level cubits, holds the
  non-archived beans, the selected bean and the current dose. Home, the Beans
  tab and the shot screen's save button all read it, so an edit in the Beans
  tab shows on Home immediately.
- Archiving the currently selected bean switches the selection to Unknown
  bean.
- The bean picker on Home is a modal bottom sheet. With no beans yet it shows
  only "Unknown bean"; adding beans happens in the Beans tab.
- Typing a dose happens in a small dialog with a numeric field.
- Add/edit bean is a route under the Beans tab (`/beans/new`,
  `/beans/:id`), so the bottom bar stays visible, like `/history/:id`.
- Save is disabled, or shows a validation message, while the name is empty or
  only whitespace.
- History resolves bean names through `BeanRepository` (including archived
  beans) when the list or detail loads.
- On the history detail screen the graph gets a fixed height so it can sit
  inside a scroll view.
- Home gets enough scroll/spacing handling not to overflow on small phones.

### Testing

Follow the existing conventions (`flutter_test`, `mockito`, `bloc_test`):

- `Bean` JSON round trip; `RecordedShot` JSON round trip with and without
  bean/dose, including loading a version 1 file.
- `FileBeanRepository` against a temp directory, like
  `test/data/shot/file_shot_repository_test.dart`.
- `BeansCubit`: add, edit, archive (including archiving the selected bean),
  select, dose change and per-bean dose recall, restore of last selection on
  start.
- Ratio calculation/formatting including the missing-value cases.

## Left to the builder

- Exact widget composition, spacing and styling, within the existing dark
  theme (`lib/ui/theme.dart`) and card style.
- The state shape of `BeansCubit` and whether history gets its own small
  view-model for "shot + resolved bean".
- Icons for the Beans tab and buttons.
- Whether holding plus/minus auto-repeats.
- Updating `CLAUDE.md` and the README future-plans list to reflect the new
  feature.

## Reference mockups

Throwaway HTML mockups the user reacted to are in
`.superpowers/brainstorm/59788-1794467908/content/` (`home-layout.html`
variant A was chosen; `beans-and-history.html`, with the corrections above:
5-step roast slider, "Unknown bean" wording, and the existing four-metric
summary row kept on the detail screen).
