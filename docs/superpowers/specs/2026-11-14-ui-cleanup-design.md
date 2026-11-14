# UI cleanup: cleaner, more consistent screens

Mockups: https://claude.ai/artifact/49B2uSMWDAK5HoZgrGkWw1 (approved direction).

## Intent

The UI has become cluttered and inconsistent as features were added (beans, dose, ratio). Make
the screens cleaner and make the same kind of information look the same everywhere. More shot
metrics are coming, so the shot screens must absorb new metrics without redesign.

## Goals

- Home: only what is needed to start a shot.
- One shot-result screen, used both right after a shot and from History.
- All shot metrics shown together in one place, in a layout that grows.
- History easier to scan: grouped by date, roaster visible.
- Lists (History, Beans) look alike.

## Non-goals

- No change to shot recording, auto-tare or auto start/stop logic.
- No change to stored shot or bean file formats.
- No new metrics in this change (the grid only has to make adding them easy).
- No bean/dose editing on the shot-done screen.

## Approaches (metrics on the shot screens)

- **Grid (picked).** One card, 3 columns, value with unit and a small label per cell. New metric =
  new cell; a new row starts every 3. Even and predictable.
- Hero + chips. Dose → yield and ratio in large text, other metrics as wrapping chips. More
  compact, but the metrics get unequal weight and chips get messy as the list grows.

## Design

### Home (`lib/ui/home/`)
- Remove `CurrentWeightWidget`, `WeightChangeWidget`, `PressureWidget` from the screen. No title.
- Bean and dose in one card, two rows split by a divider. Both rows use the same label style
  (small uppercase "BEAN" / "DOSE", fixed label width) so values line up.
  - Bean row: name, `roaster · roast` below, dropdown icon; tap opens the existing bottom sheet.
  - Dose row: `−` / value / `+`, value tap opens the existing dialog.
- Full-width START SHOT button below the card. Content vertically centred.

### Shot in progress (`ShotScreen` while waiting/updating)
- Keep the live metrics (weight, g/s, bar, seconds) but as one card with a 4-column row in the
  same cell style as the grid, instead of four separate cards. Graph below.

### Shot done = shot detail
- Extract one shared widget (e.g. `ShotResultView`) used by `ShotScreen` when `ShotGraphStopped`
  and by `SavedShotScreen`. Content, top to bottom:
  1. Bean name, with `roaster · roast` below ("Unknown bean" when none).
  2. Metrics grid card: Dose, Yield, Ratio (accent colour), Time, Peak pressure, Peak flow
     (`peakWeightChangeRate`). Missing values show `--`.
  3. Graph card with legend (weight, pressure).
- Only the app bar differs:
  - Shot done: close, restart, filled **Save** button (becomes a check once saved). Bean and dose
    come from the current `BeansCubit` selection.
  - Shot detail: back, title `Thu 12 Nov · 08:42`, share.
- Removes `ShotSummaryWidget` above the graph and `ShotBeanSection` below it.

### History
- Group shots by local calendar day. Headers: "Today", "Yesterday", else `Tue 10 Nov` (add the
  year when not the current year).
- Row: time (`08:42`) | bean name with roaster below | `18.0 → 36.4 g` with ratio below.
  Missing dose shows `--`; shots with no bean show "Unknown bean". No chevron.

### Beans
- Replace extended "Add bean" FAB with a plain round `+` FAB (tooltip/semantic label "Add bean").
- Plain list rows instead of cards, matching History; dose on the right.

### Consistency
- Bottom tab label "home" → "Home".
- Shared card style (surface colour, 12 px radius, subtle border) for metric and graph cards.

## Builder's calls
- Exact widget/file names and how the grid widget is factored.
- Date header formatting helper location (likely next to `formatShotDate`).
- Updating/adding widget tests for the changed screens.
