part of '../backend.dart';

// Хелперы для статусов заказов: модерации, принятия, отмены и
// прогрессии статусов поставщика (собирается → в пути → доставлен).

String _normalizeModerationStatus(
  Object? value, {
  String fallback = 'pending',
}) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (_allowedModerationStatuses.contains(raw)) return raw;
  return fallback;
}

bool _isAcceptedOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return false;
  return _acceptedOrderStatuses.contains(raw);
}

bool _isCancelledOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) return false;
  return raw.contains('отмен') ||
      raw.contains('отмена') ||
      raw == 'canceled' ||
      raw == 'cancelled';
}

String? _normalizeSupplierOrderStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (raw.contains('собира') ||
      raw.contains("собира") ||
      raw == "assembling" ||
      raw == "processing") {
    return _supplierOrderStatusAssembling;
  }
  if (raw.contains('в пути') ||
      raw.contains("в пути") ||
      raw == "in transit" ||
      raw == "on the way") {
    return _supplierOrderStatusInTransit;
  }
  if (raw.contains('достав') || raw.contains("достав") || raw == "delivered") {
    return _supplierOrderStatusDelivered;
  }
  return null;
}

int _supplierOrderStatusStep(Object? value) {
  final normalized = _normalizeSupplierOrderStatus(value);
  if (normalized == _supplierOrderStatusAssembling) return 0;
  if (normalized == _supplierOrderStatusInTransit) return 1;
  if (normalized == _supplierOrderStatusDelivered) return 2;
  if (_isAcceptedOrderStatus(value)) return 3;
  return -1;
}

bool _canSupplierUpdateOrderStatus(Object? currentStatus, String nextStatus) {
  final currentStep = _supplierOrderStatusStep(currentStatus);
  final nextStep = _supplierOrderStatusStep(nextStatus);
  if (nextStep < 0 || nextStep > 2) {
    return false;
  }
  if (currentStep < 0) {
    return true;
  }
  if (currentStep >= 3) {
    return false;
  }
  if (nextStep == currentStep) {
    return true;
  }
  return nextStep == currentStep + 1;
}
