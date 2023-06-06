import 'dart:math';

// ignore_for_file: prefer_is_empty

/// Parses a string representing a 24-hour time in the format `hh:mm:ss` (e.g. 21:03:40) into a [Duration].
/// 
/// Time components that cannot be parsed will default to 0.
Duration parse24HourDuration(String string) {
  if (string == null) throw ArgumentError.notNull('string');

  final List<String> parts = string.split(':');

  final String hoursString = parts.length >= 1 ? parts[0] : null;
  final String minutesString = parts.length >= 2 ? parts[1] : null;
  final String secondsString = parts.length >= 3 ? parts[2] : null;
  
  return Duration(
    hours: hoursString == null ? 0 : (int.tryParse(hoursString) ?? 0), 
    minutes: minutesString == null ? 0 : (int.tryParse(minutesString) ?? 0), 
    seconds: secondsString == null ? 0 : (int.tryParse(secondsString) ?? 0)
  );
}

/// Parses a string representing a 12-hour time loosely into a [Duration].
/// 
/// Looks for different forms of the format `h:m zz`, for example:
/// - 3:05 PM
/// - 3:5 PM (parses into 3:05 AM)
/// - 3 PM
/// - 3 (parses into 3 AM)
/// - 3:05 (parses into 3:05 AM)
/// 
/// The AM/PM component may also be lowercase and/or just the first letter.
/// 
/// Time components that cannot be parsed will default to 0. 
/// 
/// If AM/PM is missing, it will default to AM.
Duration parse12HourStringLoose(String string) {
  if (string == null) throw ArgumentError.notNull('string');

  String hoursString = null;
  String minutesString = null;
  String amPmString = null;

  if (string.contains(':')) {
    // Try to parse 'h:m zz'
    final List<String> hoursMinutesParts = string.split(':');

    hoursString = hoursMinutesParts.length >= 1 ? hoursMinutesParts[0] : null;

    final String minutesAmPmString = hoursMinutesParts.length >= 2 ? hoursMinutesParts[1] : null;

    // Try to split minutes from AM/PM
    final List<String> minutesAmPmParts = minutesAmPmString?.split(' ') ?? [];

    minutesString = minutesAmPmParts.length >= 1 ? minutesAmPmParts[0] : null;
    amPmString = minutesAmPmParts.length >= 2 ? minutesAmPmParts[1] : null;
  } else {
    // Try to parse 'h zz'
    final List<String> hoursAmPmParts = string.split(' ');

    hoursString = hoursAmPmParts.length >= 1 ? hoursAmPmParts[0] : null;
    amPmString = hoursAmPmParts.length >= 2 ? hoursAmPmParts[1] : null;
  }

  final String amPmStringUpper = amPmString?.toUpperCase();

  int hours = min(23, hoursString == null ? 0 : (int.tryParse(hoursString) ?? 0));
  final int minutes = min(59, minutesString == null ? 0 : (int.tryParse(minutesString) ?? 0));
  final bool pm = amPmStringUpper == 'PM' || amPmStringUpper == 'P' || hours > 12;

  if (hours == 12 && !pm) {
    hours = 0;
  } else if (hours < 12 && pm) {
    hours += 12;
  }
  
  return Duration(hours: hours, minutes: minutes);
}

/// Returns the [duration] as a 24-hour string in the format: `hh:mm:ss` (e.g. 21:03:40).
String durationTo24HourString(Duration duration) {
  if (duration == null) throw ArgumentError.notNull('duration');

  final buffer = new StringBuffer();

  // Add hours
  final int hours = duration.inHours;

  if (hours < 10) {
    buffer.write('0');
  }
  
  buffer.write(hours);
  buffer.write(':');

  // Add minutes
  final int minutes = duration.inMinutes % 60;

  if (minutes < 10) {
    buffer.write('0');
  }
  
  buffer.write(minutes);
  buffer.write(':');

  // Add seconds
  final int seconds = duration.inSeconds % 60;

  if (seconds < 10) {
    buffer.write('0');
  }
  
  buffer.write(seconds);

  // Done
  return buffer.toString();
}

/// Returns the [duration] as a 12-hour string in the format: `h:mm zz` (e.g. 3:05 PM).
String durationTo12HourString(Duration duration) {
  if (duration == null) throw ArgumentError.notNull('duration');

  final buffer = new StringBuffer();

  // Add hours
  final int hours = duration.inHours;

  if (hours == 0) {
    buffer.write('12');
  } else if (hours > 12) {
    buffer.write(hours - 12);
  } else {
    buffer.write(hours);
  }

  buffer.write(':');

  // Add minutes
  final int minutes = duration.inMinutes % 60;

  if (minutes < 10) {
    buffer.write('0');
  }
  
  buffer.write(minutes);
  buffer.write(' ');

  // Add am/pm
  buffer.write(hours >= 12 && hours != 24 ? 'PM' : 'AM');

  // Done
  return buffer.toString();
}
