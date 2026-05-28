part of '../backend.dart';

// Глобальные константы, регэкспы и shared-инстансы (env, support events).

final env = DotEnv()..load([File('${Directory.current.path}/.env').path]);

// Роль пользователя по умолчанию
const String _defaultRole = 'buyer';

// Время жизни OTP кода подтверждения email (в минутах)
const int _emailVerificationOtpTtlMinutes = 1;
const Duration _emailVerificationOtpTtl = Duration(
  minutes: _emailVerificationOtpTtlMinutes,
);

// Допустимые роли пользователей
const Set<String> _allowedRoles = {
  'buyer',
  'supplier',
  'moderator',
  'super_admin',
};

// Роли, которые нельзя установить через POST /register —
// модератор создаётся только Super_Admin'ом, Super_Admin создаётся бутстрапом.
const Set<String> _selfRegistrationDeniedRoles = {'moderator', 'super_admin'};

// Главный администратор: фиксированные учётные данные, создаётся при старте.
const String _superAdminEmail = 'dota@gmail.com';
const String _superAdminName = 'dota';
const String _superAdminInitialPassword = '123456';

// Дефолтный поставщик: создаётся при старте, если такого email ещё нет.
// Удобно для локальной разработки - всегда есть готовый supplier-аккаунт.
const String _defaultSupplierEmail = 'dima@gmail.com';
const String _defaultSupplierName = 'dima';
const String _defaultSupplierCompanyName = 'dima';
const String _defaultSupplierInitialPassword = '123456';
const Set<String> _allowedSupportChatStatuses = {'open', 'closed'};
const Set<String> _allowedModerationStatuses = {
  'pending',
  'approved',
  'rejected',
};
const String _cancelledOrderStatus = 'Отменен';
const Duration _orderCancellationWindow = Duration(hours: 1);
const Set<String> _acceptedOrderStatuses = {
  'принят',
  'принята',
  'принято',
  'приняты',
  'accepted',
  'received',
};
const String _supplierOrderStatusAssembling = 'Собирается';
const String _supplierOrderStatusInTransit = 'В пути';
const String _supplierOrderStatusDelivered = 'Доставлен';
const Set<String> _allowedAddressLabels = {'home', 'work', 'other'};
const int _addressLineMaxLength = 500;
const int _streetMaxLength = 100;
const int _zipMaxLength = 10;
const int _apartmentMaxLength = 20;
const int _postgresIntMaxValue = 2147483647;
const double _numeric10Scale2Bound = 100000000.0;
const double _numeric10Scale2MaxValue = 99999999.99;
final RegExp _zipPattern = RegExp(r'^\d{3,10}$');
final RegExp _apartmentPattern = RegExp(r'^[0-9A-Za-z\u0400-\u04FF /-]+$');
const Map<String, String> _utf8TextHeaders = {
  'content-type': 'text/plain; charset=utf-8',
};
final StreamController<Map<String, dynamic>> _supportEventsController =
    StreamController<Map<String, dynamic>>.broadcast();
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
