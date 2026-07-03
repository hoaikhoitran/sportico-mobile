import 'package:intl/intl.dart';

/// ISO-8601 UTC strings from the backend → local Vietnamese display.
abstract final class DateFormatter {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dateTime = DateFormat('HH:mm dd/MM/yyyy');
  static final DateFormat _weekdayDate = DateFormat('EEEE, dd/MM', 'vi');

  /// Backend dates are UTC but not always suffixed with `Z` — force UTC
  /// before converting to local time.
  static DateTime? parseUtc(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final utc = parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
          );
    return utc.toLocal();
  }

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value);

  static String time(DateTime? value) =>
      value == null ? '—' : _time.format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value);

  /// e.g. `Thứ Hai, 08/06`.
  static String weekdayDate(DateTime? value) => value == null
      ? '—'
      : toBeginningOfSentenceCase(_weekdayDate.format(value));

  /// e.g. `09:00 – 10:00`.
  static String timeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    return '${_time.format(start)} – ${_time.format(end)}';
  }
}
