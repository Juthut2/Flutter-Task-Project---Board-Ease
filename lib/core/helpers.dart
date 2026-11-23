import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Small, dependency-light helpers shared across screens.
class AppHelpers {
  const AppHelpers._();

  /// Converts Firestore [Timestamp]s, ISO strings, and DateTimes to DateTime.
  static DateTime? parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String formatCurrency(num amount) {
    return NumberFormat.currency(
      symbol: '\u20B1',
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatCompactCurrency(num amount) {
    if (amount >= 1000000) {
      return '\u20B1${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\u20B1${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\u20B1${amount.toStringAsFixed(0)}';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '\u2014';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '\u2014';
    return DateFormat('MMM d, yyyy \u2022 h:mm a').format(date);
  }

  static String formatMonth(String month) {
    final parsed = DateTime.tryParse('$month-01');
    if (parsed == null) return month;
    return DateFormat('MMMM yyyy').format(parsed);
  }

  static String monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  static String currentMonth() => monthKey(DateTime.now());

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final scheme = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: isError ? TextStyle(color: scheme.onError) : null,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? scheme.error : null,
          showCloseIcon: isError,
        ),
      );
  }
}
