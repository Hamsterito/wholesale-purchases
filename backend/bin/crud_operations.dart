part of 'backend.dart';

void _registerMutationRoutes(Router router, Connection connection) {
  // Покупатель: адреса
  _registerBuyerAddressRoutes(router, connection);

  // Общие пользовательские роуты: профиль и пароль
  _registerSharedUserProfileRoutes(router, connection);

  // Загрузка/удаление аватарки пользователя
  _registerAvatarRoutes(router, connection);

  // Поставщик: товары и статусы заказов
  _registerSupplierProductRoutes(router, connection);

  // Модератор: товары и категории
  _registerModeratorProductRoutes(router, connection);
  _registerModeratorCategoryRoutes(router, connection);

  // Поддержка: отправка сообщений + закрытие чата модератором
  _registerSupportMessageRoute(router, connection);
  _registerModeratorSupportCloseRoute(router, connection);

  // Покупатель: заказы и отзывы
  _registerBuyerOrderRoutes(router, connection);
  _registerBuyerReviewRoutes(router, connection);

  // Аутентификация: регистрация, верификация, восстановление пароля
  _registerAuthRoutes(router, connection);

  // Двухфакторная аутентификация: enable/disable, login challenge, admin-disable
  _registerTwoFactorRoutes(router, connection);

  // Экспорт заказов: покупатель и поставщик
  _registerBuyerExportRoute(router, connection);
  _registerSupplierExportRoute(router, connection);

  // Вопросы и ответы поставщика, ответы поставщика на отзывы
  _registerBuyerQuestionRoute(router, connection);
  _registerSupplierQuestionAnswerRoute(router, connection);
  _registerSupplierReviewResponseRoutes(router, connection);
}

void _registerReadRoutes(Router router, Connection connection) {
  // Публичные read-роуты: ping, пользователи и адреса
  _registerPublicUserRoutes(router, connection);

  // Каталог: категории, дерево и список товаров
  _registerCatalogRoutes(router, connection);

  // Профиль поставщика и его товары для покупателя
  _registerSupplierPublicRoutes(router, connection);

  // Личный кабинет поставщика: товары, заказы, вопросы, отзывы
  _registerSupplierDashboardRoutes(router, connection);

  // Статистика поставщика
  _registerSupplierStatisticsRoutes(router, connection);

  // Модерация: список товаров и категорий
  _registerModeratorReadRoutes(router, connection);

  // Поддержка: thread/events/messages для пользователя и модератора
  _registerSupportReadRoutes(router, connection);

  // Заказы, отзывы и вопросы покупателя
  _registerBuyerReadRoutes(router, connection);

  // Логин
  _registerLoginRoute(router, connection);

  // Курсы валют
  _registerExchangeRatesRoutes(router, connection);
}
