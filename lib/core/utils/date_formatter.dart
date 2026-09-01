import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('d-MMM-yyyy').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMM-yyyy').format(date);
}

String formatDateShort(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) {
    return DateFormat('h:mm a').format(date);
  }
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return DateFormat('EEEE').format(date);
  return DateFormat('d-MMM').format(date);
}
