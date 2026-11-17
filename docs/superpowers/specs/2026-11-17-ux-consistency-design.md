# UX consistency pass

Follow-up to the UI cleanup (2026-11-14). Findings from a UX-consistency review, with the user's
decisions. Approved in conversation on 2026-11-17.

## Intent

Remove the remaining inconsistencies between screens, and let the user delete shots.

## Decisions

- **Delete shot.** Delete icon in the History detail app bar → confirm dialog "Delete shot?"
  (Cancel / Delete, same pattern as "Archive bean?") → hard delete of the shot file → back to
  History. New port method `ShotRepository.delete(String id)`.
- **One save button.** Add/Edit bean uses the same filled `Save` button as Shot done.
- **Settings title bar.** Settings gets an app bar titled `Settings`.
- **One section header.** Shared header widget (History day-header style: `labelLarge`, accent
  colour, letter spacing 1) used by History and Settings.
- **Beans list** no longer shows the dose.
- **Connection dialog.** Stays a blocking dialog. Connecting: spinner + `Connecting to your scale
  and pressure sensor`. Paused: `Devices paused to save battery` + `Touch the screen to
  reconnect`.
- **Capitalisation.** Sentence case everywhere, never all caps: `Start shot`.
- **Settings naming.** `Scale` section first, then `Pressure sensor`. Options `Decent scale`,
  `Bookoo pressure sensor`, `Mock`. Delay setting unchanged.
- **One date format.** `Thu 12 Nov · 08:42` (`formatShotTitle`) everywhere, including the share
  text; `formatShotDate` is removed.
- **Ratio** formatted `1:2.0` (no spaces), in the normal text colour.
- **Beans tab icon.** Custom-painted coffee bean (oval with an S-shaped centre line) that follows
  the bottom bar's selected/unselected colours; no new package.

## Not changing

Unsaved-shot warning, shot correction, save feedback, list row implementations, empty states,
Logs screen styling.

## Approaches

Connection dialog: blocking dialog with explanation (picked: keeps "no shot without devices") vs a
non-blocking banner (less intrusive, but lets the user start a shot while disconnected).
Bean icon: custom painter (picked: no dependency) vs an SVG via `flutter_svg` (new dependency) vs
a generic Material icon (weaker meaning).
