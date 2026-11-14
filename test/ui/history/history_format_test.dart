import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/history/history_cubit.dart';
import 'package:espresso_log/ui/history/history_format.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryEntry _entry(DateTime at) =>
    HistoryEntry(RecordedShot.create(ShotSnapshot.empty, now: at), null);

void main() {
  final now = DateTime(2026, 11, 14, 9);

  group('formatDayHeader', () {
    test('today and yesterday', () {
      expect(formatDayHeader(DateTime(2026, 11, 14), now), 'Today');
      expect(formatDayHeader(DateTime(2026, 11, 13), now), 'Yesterday');
    });

    test('older day this year', () {
      expect(formatDayHeader(DateTime(2026, 11, 12), now), 'Thu 12 Nov');
    });

    test('earlier year includes the year', () {
      expect(formatDayHeader(DateTime(2025, 11, 10), now), 'Mon 10 Nov 2025');
    });

    test('yesterday across a year boundary', () {
      expect(
        formatDayHeader(DateTime(2025, 12, 31), DateTime(2026, 1, 1, 8)),
        'Yesterday',
      );
    });
  });

  group('groupByDay', () {
    test('groups newest-first entries by local date', () {
      final days = groupByDay([
        _entry(DateTime(2026, 11, 14, 8, 42)),
        _entry(DateTime(2026, 11, 14, 0, 0)),
        _entry(DateTime(2026, 11, 13, 23, 59)),
        _entry(DateTime(2026, 11, 12, 7, 0)),
      ]);

      expect(days.map((d) => d.day), [
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 12),
      ]);
      expect(days.map((d) => d.entries.length), [2, 1, 1]);
    });

    test('merges out-of-order entries into the first-seen day', () {
      final first = _entry(DateTime(2026, 11, 14, 8, 42));
      final late = _entry(DateTime(2026, 11, 14, 7, 0));
      final days = groupByDay([
        first,
        _entry(DateTime(2026, 11, 13, 9, 0)),
        late,
      ]);

      expect(days.map((d) => d.day), [
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 13),
      ]);
      expect(days.first.entries, [first, late]);
    });

    test('empty input gives no days', () {
      expect(groupByDay([]), isEmpty);
    });
  });

  test('formatTime', () {
    expect(formatTime(DateTime(2026, 1, 1, 8, 4)), '08:04');
    expect(formatTime(DateTime(2026, 1, 1, 23, 59)), '23:59');
  });

  test('formatShotTitle', () {
    expect(
      formatShotTitle(DateTime(2026, 11, 12, 8, 42), now),
      'Thu 12 Nov · 08:42',
    );
  });

  test('formatDoseYield', () {
    expect(formatDoseYield(18.0, 36.44), '18.0 → 36.4 g');
    expect(formatDoseYield(null, 38.0), '-- → 38.0 g');
    expect(formatDoseYield(null, null), '-- → -- g');
  });

  test('formatShotSeconds', () {
    expect(formatShotSeconds(28400), '28.4 s');
    expect(formatShotSeconds(0), '0.0 s');
  });
}
