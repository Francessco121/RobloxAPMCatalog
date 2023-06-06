import 'dart:math';

const _daysInMonth = const [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/// Returns a new [DateTime] only containing the date component of the given [dateTime].
DateTime getDateOfDateTime(DateTime dateTime) {
  return new DateTime(
    dateTime.year, dateTime.month, dateTime.day
  );
}

/// Returns a new [DateTime] only containing the time component of the given [dateTime].
DateTime getTimeOfDateTime(DateTime dateTime) {
  return new DateTime(
    1, // year 
    1, // month
    1, // day
    dateTime.hour, dateTime.minute, dateTime.second, 
    dateTime.millisecond, dateTime.microsecond
  );
}

/// Returns a new [DateTime] with the date components from [date] 
/// and the time components from [time].
DateTime combineDateAndTime(DateTime date, DateTime time) {
  return new DateTime(
    date.year, date.month, date.day,
    time.hour, time.minute, time.second, time.millisecond, time.microsecond
  );
}

/// Returns whether the date components of [a] and [b] are identical.
bool areDatesEqual(DateTime a, DateTime b) {
  return a.year == b.year
    && a.month == b.month
    && a.day == b.day;
}

/// Returns whether the given [year] is a leap year.
bool isLeapYear(int year) =>
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);

/// Returns the number of days in the given [month] of the given [year].
/// 
/// Takes into account leap years.
int getDaysInMonth(int year, int month) {
  var result = _daysInMonth[month];

  if (month == 2 && isLeapYear(year)) {
    result++;
  }

  return result;
}

/// Returns the ISO 8601 Week of Year of the given [dateTime].
int getWeekOfYear(DateTime dateTime) {
  // See: https://stackoverflow.com/a/51122613

  final int weekYear = _getWeekYear(dateTime);
  final DateTime weekYearStartDate = _getWeekYearStartDate(weekYear);

  final int dayDiff = dateTime.difference(weekYearStartDate).inDays;

  return ((dayDiff + 1) / 7).ceil();
}

/// Returns a new [DateTime] equal to the given number of [months] added to the [dateTime].
DateTime addMonths(DateTime dateTime, int months) {
  var r = months % 12;
  var q = (months - r) ~/ 12;
  var newYear = dateTime.year + q;
  var newMonth = dateTime.month + r;

  if (newMonth > 12) {
    newYear++;
    newMonth -= 12;
  }

  var newDay = min(dateTime.day, getDaysInMonth(newYear, newMonth));

  if (dateTime.isUtc) {
    return new DateTime.utc(
        newYear,
        newMonth,
        newDay,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond);
  } else {
    return new DateTime(
        newYear,
        newMonth,
        newDay,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond);
  }
}

/// Returns a new [DateTime] equal to the given number of [years] added
/// to the [dateTime].
DateTime addYears(DateTime dateTime, int years) {
  int newYear = dateTime.year + years;

  var newDay = min(dateTime.day, getDaysInMonth(newYear, dateTime.month));

  if (dateTime.isUtc) {
    return new DateTime.utc(
        newYear,
        dateTime.month,
        newDay,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond);
  } else {
    return new DateTime(
        newYear,
        dateTime.month,
        newDay,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond);
  }
}

int _getWeekYear(DateTime dateTime) {
  // See: https://stackoverflow.com/a/51122613

  final DateTime weekYearStartDate = _getWeekYearStartDate(dateTime.year);

  // In previous week year?
  if (weekYearStartDate.isAfter(dateTime)) {
    return dateTime.year - 1;
  }

  // In next week year
  final DateTime nextWeekYearStartDate = _getWeekYearStartDate(dateTime.year + 1);
  if (nextWeekYearStartDate.isAtSameMomentAs(dateTime)
    || nextWeekYearStartDate.isBefore(dateTime)) {
    return dateTime.year + 1;
  }

  return dateTime.year;
}


DateTime _getWeekYearStartDate(int year) {
  final DateTime firstDayOfYear = DateTime.utc(year, 1, 1);
  final int dayOfWeek = firstDayOfYear.weekday;

  if (dayOfWeek <= DateTime.thursday) {
    return firstDayOfYear.add(Duration(days: 1 - dayOfWeek));
  } else {
    return firstDayOfYear.add(Duration(days: 8 - dayOfWeek));
  }
}
