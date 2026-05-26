part of '../backend.dart';

// Утилиты приведения dynamic-значений к int / double / DateTime
// с защитой от отрицательных и некорректных значений.

int _toPositiveInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value < 0 ? fallback : value;
  }
  if (value is double) {
    final rounded = value.round();
    return rounded < 0 ? fallback : rounded;
  }
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 0) {
    return fallback;
  }
  return parsed;
}

int? _toNullablePositiveInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value > 0 ? value : null;
  if (value is double) {
    final rounded = value.round();
    return rounded > 0 ? rounded : null;
  }
  final parsed = int.tryParse(value.toString());
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

double _toNonNegativeDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) {
    return fallback;
  }
  if (value is double) {
    return value < 0 ? fallback : value;
  }
  if (value is int) {
    return value < 0 ? fallback : value.toDouble();
  }
  final parsed = double.tryParse(value.toString());
  if (parsed == null || parsed < 0) {
    return fallback;
  }
  return parsed;
}

DateTime? _toNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _toIso8601OrNow(dynamic value) {
  final parsed = _toNullableDateTime(value);
  return (parsed ?? DateTime.now()).toIso8601String();
}
