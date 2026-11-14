import 'package:espresso_log/ui/history/history_cubit.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The shots of one local calendar day.
class HistoryDay {
  /// Local midnight of the day.
  final DateTime day;
  final List<HistoryEntry> entries;

  const HistoryDay(this.day, this.entries);
}

DateTime _dateOf(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Groups entries by the local date they were recorded, keeping the order
/// in which days and entries first appear.
List<HistoryDay> groupByDay(List<HistoryEntry> entries) {
  final days = <DateTime, List<HistoryEntry>>{};
  for (final entry in entries) {
    days.putIfAbsent(_dateOf(entry.shot.recordedAt), () => []).add(entry);
  }
  return [for (final day in days.entries) HistoryDay(day.key, day.value)];
}

/// `Today`, `Yesterday`, or `Thu 12 Nov` (with the year when not [now]'s).
String formatDayHeader(DateTime day, DateTime now) {
  final date = _dateOf(day);
  final today = _dateOf(now);
  if (date == today) return 'Today';
  if (date == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday';
  }
  final label =
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
  return date.year == today.year ? label : '$label ${date.year}';
}

/// `08:42`.
String formatTime(DateTime t) {
  final local = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// `Thu 12 Nov · 08:42`, used as the shot detail title.
String formatShotTitle(DateTime t, DateTime now) =>
    '${formatDayHeader(t, now)} · ${formatTime(t)}';

/// `18.0 → 36.4 g`, with `--` for unknown values.
String formatDoseYield(double? dose, double? yield) {
  String f(double? v) => v?.toStringAsFixed(1) ?? '--';
  return '${f(dose)} → ${f(yield)} g';
}

/// `28.4 s`.
String formatShotSeconds(int millis) =>
    '${(millis / 1000).toStringAsFixed(1)} s';
