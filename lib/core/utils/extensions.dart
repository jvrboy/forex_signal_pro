import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get formatted => DateFormat('MMM dd, yyyy HH:mm').format(this);
  String get shortDate => DateFormat('MM/dd').format(this);
  String get shortTime => DateFormat('HH:mm').format(this);
}

extension StringCapitalize on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

extension DoubleFormatting on double {
  String toStringPips(int pipSize) {
    return toStringAsFixed(pipSize);
  }

  String get asPercent => '${(this * 100).toStringAsFixed(1)}%';

  String get asPrice => '\$${toStringAsFixed(2)}';
}

extension BuildContextExtensions on BuildContext {
  void showSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
