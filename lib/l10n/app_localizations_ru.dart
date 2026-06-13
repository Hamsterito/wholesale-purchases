// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get common_ok => 'Хорошо';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_edit => 'Править';

  @override
  String get common_loading => 'Загрузка...';

  @override
  String get common_error => 'Ошибка';

  @override
  String get common_success => 'Успешно';

  @override
  String get common_no_data => 'Нет данных';

  @override
  String get common_try_again => 'Попробуйте снова';

  @override
  String get common_retry => 'Повторение';

  @override
  String get common_send => 'Отправить';

  @override
  String get common_back => 'Назад';

  @override
  String get common_next => 'Далее';

  @override
  String get common_close => 'Закрыть';

  @override
  String get common_add => 'Добавить';

  @override
  String get common_search => 'Поиск...';

  @override
  String get common_confirm => 'Подтвердить';

  @override
  String get common_unit_short => 'шт.';

  @override
  String get auth_login_title => 'Вход в аккаунт';

  @override
  String get auth_register_title => 'Регистрация';

  @override
  String get auth_forgot_password => 'Забыли пароль?';

  @override
  String get auth_reset_password_title => 'Сброс пароля';

  @override
  String get auth_email_label => 'Email';

  @override
  String get auth_password_label => 'Пароль';

  @override
  String get auth_name_label => 'Имя';

  @override
  String get auth_name_hint => 'Введите свое имя';

  @override
  String get auth_supplier_name_hint => 'Например, ООО Манса склад';

  @override
  String get auth_password_hint => 'Введите новый пароль';

  @override
  String get auth_password_confirm_hint => 'Подтвердите новый пароль';

  @override
  String get auth_current_password_hint => 'Введите текущий пароль';

  @override
  String get auth_password_repeat_hint => 'Введите пароль еще раз';

  @override
  String get auth_password_min_length => 'Не менее 6 символов';

  @override
  String get auth_logout => 'Выход';

  @override
  String get catalog_title => 'Каталог';

  @override
  String get catalog_search_hint => 'Поиск...';

  @override
  String get catalog_search_categories => 'Поиск категорий...';

  @override
  String get catalog_search_subcategories => 'Поиск подкатегорий...';

  @override
  String get catalog_no_products => 'Товары не найдены';

  @override
  String get cart_title => 'Корзина';

  @override
  String get cart_empty => 'Ваша корзина пуста';

  @override
  String get cart_clear_title => 'Нужно очистить корзину?';

  @override
  String get cart_clear_message => 'Все продукты будут удалены из корзины.';

  @override
  String get cart_clear_button => 'Очистить';

  @override
  String get cart_payment_confirm_title => 'Подтверждение оплаты';

  @override
  String get cart_payment_button => 'Оплатить';

  @override
  String get order_title => 'Заказы';

  @override
  String get order_history => 'История заказов';

  @override
  String get order_no_orders => 'Нет заказов';

  @override
  String get product_details => 'Детали продукта';

  @override
  String get product_reviews => 'Отзывы';

  @override
  String get product_questions => 'Вопросы';

  @override
  String get product_answer_button => 'Ответить';

  @override
  String get product_review_hint => 'Текст комментария';

  @override
  String get product_review_share => 'Поделитесь впечатлениями';

  @override
  String get profile_title => 'Профиль';

  @override
  String get profile_settings => 'Настройки';

  @override
  String get profile_personal_info => 'Личная информация';

  @override
  String get profile_change_password => 'Изменить пароль';

  @override
  String get profile_payment_cards => 'Платежные карты';

  @override
  String get profile_addresses => 'Адреса доставки';

  @override
  String get profile_edit_field_hint => 'Введите новое значение';

  @override
  String get supplier_products => 'Продукты';

  @override
  String get supplier_orders => 'Заказы';

  @override
  String get supplier_profile => 'Профиль поставщика';

  @override
  String get supplier_add_product => 'Добавление продукта';

  @override
  String get supplier_edit_product => 'Править';

  @override
  String get supplier_search_suppliers => 'Поиск по поставщикам';

  @override
  String get supplier_country_hint => 'Например, Казахстан';

  @override
  String get supplier_shelf_life_hint => 'Например, 12 месяцев';

  @override
  String get supplier_weight_hint => 'Например, 1450';

  @override
  String get supplier_calories_hint => 'Например, 120';

  @override
  String get supplier_category_search => 'Поиск категории';

  @override
  String get supplier_add_photo => 'Добавить';

  @override
  String get supplier_schedule_weekdays => 'Будни';

  @override
  String get supplier_schedule_weekend => 'Выходные дни';

  @override
  String get supplier_schedule_daily => 'Каждый день';

  @override
  String get moderator_title => 'Модерация';

  @override
  String get moderator_search_hint => 'Поиск: товар, поставщик, категория';

  @override
  String get moderator_search_users => 'Поиск по имени или email';

  @override
  String get moderator_delete_reason => 'Причина удаления для поставщика';

  @override
  String get moderator_close_reason => 'Причина закрытия (необязательно)';

  @override
  String get moderator_support_chats => 'Поддерживающие чаты';

  @override
  String get support_category_hint => 'Выберите категорию';

  @override
  String get support_subject_hint => 'Введите тему';

  @override
  String get template_save_title => 'Сохранить как шаблон';

  @override
  String get template_overwrite => 'Переписать';

  @override
  String get template_save_another => 'Сохранить под другим именем';

  @override
  String get template_rename_title => 'Переименование шаблона';

  @override
  String get template_name_label => 'Название шаблона';

  @override
  String get template_name_error => 'Название шаблона: от 1 до 50 символов';

  @override
  String get template_duplicate_exists => 'Название уже занято';

  @override
  String get template_apply_confirm => 'Замена';

  @override
  String get payment_card_expiry_hint => 'ММ/ГГ';

  @override
  String get validation_required => 'Это поле обязательно';

  @override
  String get validation_email_invalid => 'Неверный формат Email';

  @override
  String get validation_password_short => 'Пароль слишком короткий';

  @override
  String get validation_passwords_mismatch => 'Пароли несовместимы';

  @override
  String get error_network =>
      'Ошибка сети. Проверьте соединение и попробуйте снова';

  @override
  String get error_timeout => 'Более длительное время отклика сервера';

  @override
  String get error_unknown => 'Произошла неизвестная ошибка';

  @override
  String get error_auth_required => 'Требуется Авторизация';

  @override
  String get error_not_found => 'Не найден';

  @override
  String message_order_not_found(int orderId) {
    return 'ID $orderId существующий заказ не найден';
  }

  @override
  String message_order_confirmed(int orderId) {
    return 'Ваш #$orderId заказ подтвержден';
  }

  @override
  String message_order_delivered(int orderId) {
    return '#$orderId заказ доставлен';
  }

  @override
  String message_product_not_found(String productId) {
    return 'ID $productId существующий продукт не найден';
  }

  @override
  String get message_network_error =>
      'Ошибка сети. Проверьте соединение и попробуйте снова';

  @override
  String get message_timeout_error => 'Более длительное время отклика сервера';

  @override
  String message_validation_error(int details) {
    return 'Ошибка подтверждения: $details';
  }

  @override
  String get message_auth_required => 'Требуется Авторизация';

  @override
  String get message_parse_error => 'Сообщение не может быть проанализировано';

  @override
  String message_ai_generation_failed(int reason) {
    return 'Невозможно построить ответ AI: $reason';
  }

  @override
  String get format_date_pattern => 'DD.MM.YYYY HH:mm';

  @override
  String get format_number_thousands_separator => '\\u202F';

  @override
  String get format_number_decimal_separator => ',';

  @override
  String get common_more => 'Еще';

  @override
  String get common_less => 'Скрыть';

  @override
  String get auth_session_expired => 'Сеанс завершен. Войдите снова';

  @override
  String get product_similar => 'Организационные продукты';

  @override
  String get supplier_error_load_products => 'Не удалось загрузить продукты';

  @override
  String get supplier_error_load_orders => 'Не удалось загрузить заказы';

  @override
  String get supplier_login_required => 'Необходимо войти в аккаунт';

  @override
  String get supplier_product_sent_moderation => 'Товар отправлен на модерацию';

  @override
  String get supplier_changes_sent_moderation =>
      'Изменения направлены на модерацию';

  @override
  String get supplier_delete_product => 'Удалить продукт?';

  @override
  String get supplier_product => 'Продукт';

  @override
  String get supplier_removed_from_publication =>
      'Продукт взят из публицистики';

  @override
  String get supplier_product_deleted => 'Продукт уничтожен';

  @override
  String get supplier_error_delete_product => 'Не удалось удалить продукт';

  @override
  String get supplier_apprved => 'Утверждено';

  @override
  String get supplier_rejected => 'Не вставлен';

  @override
  String get supplier_pending => 'В умеренности';

  @override
  String get supplier_no_title => 'Без названия';

  @override
  String get supplier_no_description => 'Без описания';

  @override
  String get supplier_orders_empty_no_orders => 'Нет заказов';

  @override
  String get supplier_orders_empty_active => 'Нет активных заказов';

  @override
  String get supplier_orders_empty_history => 'В истории нет заказов';

  @override
  String get supplier_orders_empty_period => 'Нет заказов на выбранный период';

  @override
  String get supplier_status_change_step =>
      'Невозможно пройти в выбранном статусе';

  @override
  String get supplier_status_updated => 'Обновлен статус заказа';

  @override
  String get supplier_status_update_failed => 'Не удалось обновить статус';

  @override
  String get supplier_status_confirm_change =>
      'Подтверждение изменения статуса';

  @override
  String get supplier_order_prefix => 'Заказ';

  @override
  String get supplier_from => 'из';

  @override
  String get supplier_to => 'в';

  @override
  String get supplier_period_day => 'День';

  @override
  String get supplier_period_week => 'Неделя';

  @override
  String get supplier_period_month => 'Месяц';

  @override
  String get supplier_period_quarter => 'Квартал';

  @override
  String get supplier_active_orders_tab => 'Активный';

  @override
  String get supplier_history_orders_tab => 'История';

  @override
  String get supplier_filter_label => 'Фильтр по датам';

  @override
  String get supplier_export_excel => 'Экспорт в файл Excel';

  @override
  String get supplier_products_in_order => 'Продукты на заказ';

  @override
  String get supplier_top_products => 'Популярные товары';

  @override
  String get supplier_recent_orders => 'Последние заказы';

  @override
  String supplier_unanswered_questions(int count) {
    return 'Вопросов без ответа: $count';
  }

  @override
  String get template_add_to_cart => 'Добавить в корзину';

  @override
  String get review_quick_fast_delivery => 'Быстрая доставка';

  @override
  String get review_quick_good_price => 'Хорошая цена';

  @override
  String get review_quick_quality_packaging => 'Качественная упаковка';

  @override
  String get review_quick_fresh_product => 'Свежий товар';

  @override
  String get review_quick_polite_courier => 'Вежливый курьер';

  @override
  String get review_no_text => 'Без текста';

  @override
  String get wizard_optional => 'не обязательно';

  @override
  String get wizard_orders_cutoff_time =>
      'Время, когда прием заказов заканчивается';

  @override
  String get wizard_invalid_time => 'Неправильный формат времени';

  @override
  String get wizard_select_category => 'Выберите категорию из каталога';

  @override
  String get settings_enabled => 'Включено';

  @override
  String get settings_disabled => 'Выключено';

  @override
  String get price => 'Цена';

  @override
  String get checkout => 'Оформление заказа';

  @override
  String get supplier_status_assembling => 'Подготовка идет';

  @override
  String get supplier_status_in_transit => 'В пути';

  @override
  String get supplier_status_delivered => 'Доставлено';

  @override
  String get supplier_status_accepted => 'Получено';

  @override
  String get supplier_status_cancelled => 'Отменён';

  @override
  String get supplier_order_progress => 'Прогресс заказа';

  @override
  String supplier_current_status(String status) {
    return 'Текущий статус: $status';
  }

  @override
  String get supplier_order_confirmed_by_buyer =>
      'Заказ подтвержден покупателем';

  @override
  String get supplier_waiting_buyer_confirmation =>
      'Ожидает подтверждения покупателем';

  @override
  String get units_count_short => 'шт.';

  @override
  String get items_count_short => 'поз.';

  @override
  String get supplier_export_success => 'Файл загружен';

  @override
  String get supplier_order_items_empty => 'В заказе нет товаров';

  @override
  String supplier_export_error(int error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get answered_label => 'Ответ дан';

  @override
  String get supplier_order_total_label => 'Всего';

  @override
  String get supplier_delivery_address_label => 'Адрес доставки';

  @override
  String get supplier_order_status_label => 'Статус заказа';

  @override
  String get supplier_goods_positions_label => 'Товарные позиции';

  @override
  String get supplier_units_count_label => 'Количество единиц';

  @override
  String get supplier_confirmed_label => 'Подтверждено';

  @override
  String get supplier_address_not_specified => 'Не указано';

  @override
  String get qa_title => 'Вопросы и ответы';

  @override
  String get qa_questions_tab => 'Вопросы';

  @override
  String get qa_reviews_tab => 'Отзывы';

  @override
  String get qa_questions_without_answers =>
      'Вопросы, на которые уже даны ответы';

  @override
  String get qa_answered_questions => 'Вопросы с ответами';

  @override
  String get qa_no_questions => 'Нет вопросов';

  @override
  String get qa_no_reviews => 'Нет комментариев';

  @override
  String get qa_no_text => 'Без текста';

  @override
  String get qa_seller_answer => 'Ответ поставщика';

  @override
  String get qa_without_answer => 'Нет ответа';

  @override
  String get qa_answer_sent_success => 'Ответ отправлен успешно';

  @override
  String get qa_answer_updated_success => 'Ответ был успешно обновлен';

  @override
  String get qa_not_authorized => 'Вы не авторизованы';

  @override
  String get qa_refresh => 'Обновление';

  @override
  String get qa_retry => 'Повторение';

  @override
  String get qa_expand => 'Подробнее';

  @override
  String get qa_collapse => 'Скрыть';

  @override
  String get qa_respond => 'Ответить';

  @override
  String get qa_customers_no_questions => 'Товаришки еще не задавали вопросов';

  @override
  String get qa_customers_no_reviews => 'Товаришки пока не оставили отзывов';

  @override
  String get qa_no_answer => 'Нет ответа';

  @override
  String qa_error_with_details(int details) {
    return 'Ошибка: $details';
  }

  @override
  String get qa_answer_updated => 'Ответ обновлен';

  @override
  String get supplier_label => 'Поставщик';

  @override
  String get unknown_error => 'Неизвестная ошибка';

  @override
  String get profile_reviews_title => 'Ваши комментарии';

  @override
  String get profile_reviews_empty => 'пока нет комментариев';

  @override
  String get profile_reviews_pending_title => 'Ждите комментариев';

  @override
  String get profile_reviews_pending_subtitle =>
      'Дайте оценку покупкам-это поможет другим';

  @override
  String get profile_reviews_leave_review => 'Оставить комментарий';

  @override
  String profile_reviews_total_count(int count) {
    return '$count всего';
  }

  @override
  String get profile_reviews_section_title => 'Ваши комментарии';

  @override
  String get profile_reviews_section_subtitle_empty =>
      'Отзывы по всем покупкам';

  @override
  String profile_reviews_section_subtitle_total(int count) {
    return 'Всего: $count';
  }

  @override
  String get profile_reviews_rate_product => 'Дайте товару оценку';

  @override
  String get profile_reviews_add_details => 'Добавить детали';

  @override
  String get profile_reviews_edit_button => 'Править';

  @override
  String get profile_reviews_delete_button => 'Удалить';

  @override
  String get profile_reviews_sending => 'Отправка...';

  @override
  String get profile_reviews_save_button => 'Сохранить';

  @override
  String get profile_reviews_saved_success => 'Комментарий обновлен';

  @override
  String get profile_reviews_save_error => 'Комментарий не удалось сохранить';

  @override
  String get profile_reviews_login_required =>
      'Войдите, чтобы отредактировать отзыв';

  @override
  String get profile_reviews_rating_required => 'Дайте товару оценку';

  @override
  String get profile_reviews_submit_success => 'Спасибо за комментарий!';

  @override
  String get profile_reviews_submit_error => 'Не удалось отправить комментарий';

  @override
  String get profile_reviews_delete_confirm => 'Удалить комментарий?';

  @override
  String get profile_reviews_delete_success => 'Комментарий удален';

  @override
  String get profile_reviews_delete_error => 'Удалить комментарий не удалось';

  @override
  String get profile_reviews_close_dialog => 'Закрыть';

  @override
  String get profile_reviews_cancel_button => 'Отмена';

  @override
  String get profile_reviews_change_button => 'Изменить';

  @override
  String profile_reviews_order_label(int orderId) {
    return 'Заказ $orderId';
  }

  @override
  String get profile_review_hint => 'Текст комментария';

  @override
  String get review_sending => 'Отправляется...';

  @override
  String get review_your_text => 'Ваше мнение';

  @override
  String get review_rate_product => 'Дайте товару оценку';

  @override
  String get review_add_details => 'Добавить детали';

  @override
  String get review_save_button => 'Сохранить';

  @override
  String get review_sending_text => 'Отправляется...';

  @override
  String get review_save_draft => 'Сохранить';

  @override
  String get review_cancel_draft => 'Отмена';

  @override
  String get review_change_draft => 'Изменить';

  @override
  String get review_share_feedback => 'Поделитесь впечатлениями';

  @override
  String get review_edit_button => 'Править';

  @override
  String get review_delete_button => 'Удалить';

  @override
  String get review_cancel_button => 'Отмена';

  @override
  String get review_change_button => 'Изменить';

  @override
  String get review_leave_button => 'Оставить комментарий';

  @override
  String get review_submit_button => 'Отправить комментарий';

  @override
  String get review_delete_confirm => 'Удалить комментарий?';

  @override
  String get review_close_dialog => 'Закрыть';

  @override
  String get review_edit_draft => 'Править';

  @override
  String get review_delete_draft => 'Удалить';

  @override
  String get review_leave_draft => 'Оставить комментарий';

  @override
  String get review_submit_draft => 'Отправить комментарий';

  @override
  String get review_thank_you => 'Спасибо за комментарий!';

  @override
  String get review_no_questions_empty => 'пока нет комментариев';

  @override
  String get confirm_delete => 'Удалить';

  @override
  String get confirm_cancel => 'Отмена';

  @override
  String get cannot_be_undone => 'Это действие нельзя отменить';

  @override
  String get settings_appearance => 'Внешний вид';

  @override
  String get settings_dark_mode => 'Темная тема';

  @override
  String get settings_use_dark_theme => 'Использование темной темы';

  @override
  String get settings_language_region => 'Язык и регион';

  @override
  String get settings_language_label => 'Язык';

  @override
  String get settings_currency => 'Валюта';

  @override
  String settings_currency_name(int code) {
    return '$code';
  }

  @override
  String get settings_security => 'Безопасность';

  @override
  String get settings_change_password => 'Изменить пароль';

  @override
  String get settings_two_factor_auth => 'Двухфакторная аутентификация';

  @override
  String get settings_about => 'О приложении';

  @override
  String get settings_app_version => 'Версия приложения';

  @override
  String get nav_home => 'Главная';

  @override
  String get nav_statistics => 'Статистика';

  @override
  String get nav_moderation => 'Модерация';

  @override
  String get nav_chats => 'Чаты';

  @override
  String get nav_moderators => 'Модераторы';

  @override
  String get supplier_delete_product_confirm =>
      'Вы уверены, что хотите удалить этот продукт?';

  @override
  String get supplier_profile_title => 'Профиль поставщика';

  @override
  String get template_replace_cart => 'Замена корзины';

  @override
  String get template_replace_cart_confirm =>
      'Текущая корзина заменяется продуктами из шаблона. Продолжать?';

  @override
  String get zakazi_my_orders => 'Мои заказы';

  @override
  String get zakazi_no_orders => 'Нет заказов';

  @override
  String get zakazi_history_button => 'История заказов';

  @override
  String zakazi_history_button_count(int count) {
    return 'История заказов ($count)';
  }

  @override
  String zakazi_order_label(int orderId) {
    return 'Заказ $orderId';
  }

  @override
  String get zakazi_total_amount_label => 'Общая сумма:';

  @override
  String get zakazi_today => 'Сегодня';

  @override
  String get zakazi_yesterday => 'Вчера';

  @override
  String get zakazi_tomorrow => 'Завтра';

  @override
  String get zakazi_month_january => 'январь';

  @override
  String get zakazi_month_february => 'февраль';

  @override
  String get zakazi_month_march => 'март';

  @override
  String get zakazi_month_april => 'апрель';

  @override
  String get zakazi_month_may => 'май';

  @override
  String get zakazi_month_june => 'июнь';

  @override
  String get zakazi_month_july => 'июль';

  @override
  String get zakazi_month_august => 'август';

  @override
  String get zakazi_month_september => 'сентябрь';

  @override
  String get zakazi_month_october => 'октябрь';

  @override
  String get zakazi_month_november => 'ноябрь';

  @override
  String get zakazi_month_december => 'декабрь';

  @override
  String get zakazi_quantity_short => 'шт.';

  @override
  String get zakazi_accepted_label => 'Получено';

  @override
  String get zakazi_after_delivery => 'С доставкой';

  @override
  String get zakazi_can_accept_after_delivery =>
      'Можно получить после доставки';

  @override
  String zakazi_cancel_available(int time) {
    return 'Отмена доступна ещё $time';
  }

  @override
  String get zakazi_cancel_only_first_hour =>
      'Удаление возможно только в течение первого часа';

  @override
  String get zakazi_select_all => 'Выбор всего';

  @override
  String get zakazi_deselect_all => 'Снять выбор';

  @override
  String get zakazi_accepting => 'Получение';

  @override
  String get zakazi_accept_button => 'Получить';

  @override
  String get zakazi_mark_items_before_confirm =>
      'Отметьте все товары перед подтверждением заказа.';

  @override
  String get zakazi_confirm_acceptance => 'Подтверждение получения';

  @override
  String zakazi_order_amount(int orderId, int amount) {
    return 'Заказ $orderId $amount  в сумме ₸ ';
  }

  @override
  String get zakazi_cancel_order_title => 'Отменить заказ?';

  @override
  String get zakazi_cancel_order_message =>
      'Заказ отменяется, а товары возвращаются на склад.';

  @override
  String get zakazi_no => 'Нет';

  @override
  String get zakazi_cancel_button => 'Отменить';

  @override
  String get zakazi_cancelling => 'Отмена';

  @override
  String get zakazi_order_accepted => 'Заказ получен.';

  @override
  String get zakazi_accept_failed => 'Получить заказ не удалось. Повторить.';

  @override
  String get zakazi_cancel_failed => 'Отменить заказ не удалось. Повторить.';

  @override
  String get zakazi_order_cancelled => 'Заказ отменён.';

  @override
  String get cart_item_removed => 'Товар удалён';

  @override
  String get cart_undo_remove => 'Отменить';

  @override
  String get zakazi_session_expired => 'Сеанс завершен. Войдите снова.';

  @override
  String get cart_confirm_row_amount => 'Сумма';

  @override
  String get cart_confirm_row_units => 'Шт.';

  @override
  String get cart_confirm_row_payment => 'Оплата';

  @override
  String get cart_payment_method_cash => 'Наличность при получении';

  @override
  String get cart_payment_method_card => 'Карта';

  @override
  String get cart_payment_method_card_none => 'Карта не включена';

  @override
  String get cart_payment_confirm_choice => 'Подтверждение выбора';

  @override
  String get cart_payment_banner_cash => 'Оплата наличными при получении';

  @override
  String get cart_payment_banner_card_none =>
      'Оплата картой. Добавьте карту на следующем шаге.';

  @override
  String cart_payment_banner_card(int brand, int number) {
    return 'Оплата картой $brand $number';
  }

  @override
  String get cart_checkout_login_required => 'Войдите, чтобы выбрать оплату';

  @override
  String get cart_checkout_address_login_required =>
      'Войдите, чтобы выбрать адрес';

  @override
  String get cart_checkout_order_login_required =>
      'Войдите, чтобы оформить заказ';

  @override
  String get cart_checkout_address_load_error => 'Не удалось загрузить адреса';

  @override
  String get cart_address_picker_title => 'Адрес доставки';

  @override
  String get cart_address_empty_title => 'Адресов пока нет';

  @override
  String get cart_address_empty_subtitle =>
      'Добавьте адрес, чтобы продолжить оформление.';

  @override
  String get cart_address_none => 'Без адреса';

  @override
  String get cart_checkout_save_address_error => 'Адрес не удалось сохранить';

  @override
  String get cart_checkout_supplier_success => 'Заказ оформлен по поставщику';

  @override
  String get cart_checkout_all_success => 'Все заказы успешно оформлены';

  @override
  String cart_checkout_partial_success(int success, int fail) {
    return 'Оформлено: $success, с ошибкой: $fail';
  }

  @override
  String get cart_checkout_all_failed => 'Не удалось оформить заказы';

  @override
  String get cart_template_save => 'Сохранить как шаблон';

  @override
  String get cart_template_title => 'Образцы';

  @override
  String get cart_template_login_required =>
      'Чтобы использовать шаблоны, посетите';

  @override
  String get cart_template_apply_error => 'Не удалось применить образец';

  @override
  String get cart_template_apply_none =>
      'Образец не использовался: ни один продукт не доступен';

  @override
  String cart_template_apply_success(int name, int added) {
    return 'Корзина «$name\"заменено образцом: $added добавлен продукт';
  }

  @override
  String cart_template_apply_skipped(int skipped) {
    return ', $skipped проведено';
  }

  @override
  String cart_template_apply_adjusted(int adjusted) {
    return ', $adjusted исправлено';
  }

  @override
  String cart_template_skipped_title(int count, int plural) {
    return '$count $plural проведено';
  }

  @override
  String get cart_checkout_error_network => 'Нет связи с сервером';

  @override
  String get cart_checkout_error_data => 'Данные заказа неверны';

  @override
  String get cart_checkout_error_generic => 'Не удалось оформить заказ';

  @override
  String get cart_template_skip_product_missing => 'Товар недоступен';

  @override
  String get cart_template_skip_supplier_missing =>
      'Поставщик не предлагает этот товар';

  @override
  String get cart_template_rename_success => 'Модель переименована';

  @override
  String cart_template_delete_title(int name) {
    return 'Удаление шаблона $name?';
  }

  @override
  String get cart_template_delete_success => 'Образец удален';

  @override
  String get cart_template_limit_items =>
      'В образце должно быть не более 100 позиций.';

  @override
  String get cart_template_limit_templates =>
      'Достиг предела образцов: 20. удалите ненужный образец.';

  @override
  String get cart_template_save_success => 'Образец сохранился';

  @override
  String get cart_checkout_all_orders => 'Оформление всех заказов';

  @override
  String get cart_checkout_all_orders_title => 'Все заказы';

  @override
  String get cart_total_amount_title => 'Общая сумма заказа';

  @override
  String cart_total_summary(int units, int positions) {
    return 'Шт.: $units Позиция: $positions';
  }

  @override
  String cart_summary_more_items(int count) {
    return 'еще +в корзине$count';
  }

  @override
  String get cart_supplier_total_title => 'Комплект по поставщику';

  @override
  String get cart_checkout_order => 'Оформление заказа';

  @override
  String cart_supplier_info(int units, int positions) {
    return 'Шт.: $units * Позиция: $positions';
  }

  @override
  String cart_delivery_date(int date) {
    return 'Дата доставки: $date';
  }

  @override
  String cart_min_quantity(int count) {
    return 'Минимум: $count шт.';
  }

  @override
  String cart_quantity_suffix(int count) {
    return '$count шт.';
  }

  @override
  String cart_pay_all_details(int units) {
    return '· $units шт.';
  }

  @override
  String cart_summary_item(int name, int quantity) {
    return '$name - $quantity шт.';
  }

  @override
  String cart_template_default_name(int date) {
    return '$date шаблон даты';
  }

  @override
  String get common_more_details => 'Подробнее';

  @override
  String get common_undo => 'Отменить';

  @override
  String get cart_clear_cart_link => 'Очистка корзины';

  @override
  String get home_all_tab => 'Всего';

  @override
  String home_loading_error(int error) {
    return 'Ошибка загрузки продуктов: $error';
  }

  @override
  String get home_retry_button => 'Повторить';

  @override
  String get chat_empty_title => 'Нет сообщений';

  @override
  String get chat_retry_send => 'Повторить отправку';

  @override
  String get chat_yesterday => 'Вчера';

  @override
  String get chat_buyer_default => 'Получатель';

  @override
  String get chat_no_review_text => 'Нет текста комментария';

  @override
  String chat_empty_hint(int postfix) {
    return 'Напишите предыдущее сообщение$postfix';
  }

  @override
  String get chat_today => 'Сегодня';

  @override
  String get home_no_products => 'Продукты не найдены';

  @override
  String get home_title => 'Главная';

  @override
  String get home_search_hint => 'Поиск...';

  @override
  String get filters_sheet_title => 'Фильтры';

  @override
  String get filters_reset_button => 'Восстановление';

  @override
  String get filter_price_title => 'Цена за штуку';

  @override
  String get filter_price_from => 'с';

  @override
  String get filter_price_to => 'до';

  @override
  String get filter_sort_title => 'Сортировка';

  @override
  String get filter_sort_price => 'Цена';

  @override
  String get filter_sort_rating => 'Рейтинг';

  @override
  String get filter_order_title => 'Последовательность';

  @override
  String get filter_order_asc => 'Заданный';

  @override
  String get filter_order_desc => 'От большего к меньшему';

  @override
  String get filter_rating_title => 'Рейтинг';

  @override
  String get filter_rating_from => 'с';

  @override
  String filter_show_button(int count) {
    return 'Показать $count';
  }

  @override
  String get filter_discounted => 'Товары со скидкой';

  @override
  String get date_range_picker_title => 'Выберите диапазон дат';

  @override
  String get date_range_picker_clear => 'Очистить';

  @override
  String get date_range_picker_today => 'Сегодня';

  @override
  String get date_range_picker_week => 'Неделя';

  @override
  String get date_range_picker_month => 'Месяц';

  @override
  String get date_range_picker_quarter => 'Квартал';

  @override
  String get select_date_range => 'Выберите диапазон дат';

  @override
  String get month_january => 'январь';

  @override
  String get month_february => 'февраль';

  @override
  String get month_march => 'март';

  @override
  String get month_april => 'апрель';

  @override
  String get month_may => 'май';

  @override
  String get month_june => 'июнь';

  @override
  String get month_july => 'июль';

  @override
  String get month_august => 'август';

  @override
  String get month_september => 'сентябрь';

  @override
  String get month_october => 'октябрь';

  @override
  String get month_november => 'ноябрь';

  @override
  String get month_december => 'декабрь';

  @override
  String get templates_sheet_title => 'Шаблоны покупок';

  @override
  String get templates_sheet_no_templates => 'Нет сохраненных шаблонов';

  @override
  String get templates_sheet_collapse => 'Свернуть';

  @override
  String get templates_sheet_expand => 'Развернуть';

  @override
  String get templates_sheet_actions => 'Действия';

  @override
  String get templates_sheet_rename => 'Переименовать';

  @override
  String get templates_sheet_delete => 'Удалить';

  @override
  String get templates_sheet_add_to_cart => 'Добавить в корзину';

  @override
  String get templates_sheet_position_short => 'поз.';

  @override
  String get templates_sheet_unit_short => 'шт.';

  @override
  String get templates_sheet_hide => 'Скрыть';

  @override
  String product_card_quantity(int count) {
    return '$count шт.';
  }

  @override
  String get product_card_added_to_favorites => 'Выбрано';

  @override
  String get product_card_removed_from_favorites => 'Удалить';

  @override
  String get product_card_add_to_cart => 'Добавить в корзину';

  @override
  String get product_card_out_of_stock => 'В складе нет';

  @override
  String get product_card_quantity_title => 'Количество';

  @override
  String get product_card_min_quantity => 'Минимум';

  @override
  String get product_card_everyday => 'Каждый день';

  @override
  String get product_card_weekdays => 'Будни';

  @override
  String get product_card_weekend => 'Выходные дни';

  @override
  String get supplier_selected => 'Выбрано';

  @override
  String get supplier_select => 'Выбор';

  @override
  String get supplier_unit_short => 'шт.';

  @override
  String get supplier_delivery_default => 'Доставка';

  @override
  String get weekday_monday => 'Понедельник';

  @override
  String get weekday_tuesday => 'Вторник';

  @override
  String get weekday_wednesday => 'Среда';

  @override
  String get weekday_thursday => 'Четверг';

  @override
  String get weekday_friday => 'Пятница';

  @override
  String get weekday_saturday => 'Суббота';

  @override
  String get weekday_sunday => 'Воскресенье';

  @override
  String get weekday_mon_short => 'Пн';

  @override
  String get weekday_tue_short => 'Вт';

  @override
  String get weekday_wed_short => 'Ср';

  @override
  String get weekday_thu_short => 'Чт';

  @override
  String get weekday_fri_short => 'Пт';

  @override
  String get weekday_sat_short => 'Сб';

  @override
  String get weekday_sun_short => 'ВС';

  @override
  String get change_password_success_title => 'Пароль изменен';

  @override
  String get change_password_success_message =>
      'Ваш пароль был успешно обновлен.';

  @override
  String get change_password_done_button => 'Готово';

  @override
  String get order_history_empty => 'Список товаров пуст';

  @override
  String get favorites_tab_products => 'Товары';

  @override
  String get favorites_tab_companies => 'Компании';

  @override
  String get support_chat_title => 'Чат техподдержки';

  @override
  String get supplier_reset_button => 'Восстановление';

  @override
  String get supplier_products_edit => 'Править';

  @override
  String get supplier_products_add => 'Добавить товар';

  @override
  String get payment_card_delete_title => 'Удалить карту?';

  @override
  String get payment_card_delete_button => 'Удалить';

  @override
  String get address_add_button => 'Добавить адрес';

  @override
  String get moderation_approve_button => 'Утверждение';

  @override
  String get two_factor_disable_title => 'Отключить 2FA?';

  @override
  String get two_factor_disable_button => 'Отключить';

  @override
  String get moderator_management_title => 'Управление модераторами';

  @override
  String get moderator_delete_title => 'Удалить модератора?';

  @override
  String get moderator_add_button => 'Добавить';

  @override
  String get moderator_login_button => 'Вход';

  @override
  String get two_factor_copy_all => 'Копировать все';

  @override
  String get two_factor_save_file => 'Сохранить в файл';

  @override
  String get add_moderator_title => 'Добавить модератора';

  @override
  String get supplier_profile_reset => 'Восстановление';

  @override
  String supplier_profile_preview_show(int count) {
    return 'Показать $count';
  }

  @override
  String get create_chat_title => 'Создать Чат?';

  @override
  String get close_chat_title => 'Закрыть чат';

  @override
  String get suppliers_list_title => 'Поставщики';

  @override
  String get question_ask_button => 'Задать вопрос';

  @override
  String get no_button => 'Нет';

  @override
  String get cancel_order_title => 'Отменить заказ?';

  @override
  String get cancel_order_message =>
      'Заказ отменяется, а товары возвращаются на склад.';

  @override
  String get cancel_order_button => 'Отменить';

  @override
  String get accept_order_button => 'Получить';

  @override
  String get suppliers_not_found => 'Поставщики не найдены';

  @override
  String get close_chat_button => 'Закрытие';

  @override
  String get create_chat_confirm => 'Обновление';

  @override
  String get moderator_title_profile => 'Профиль модератора';

  @override
  String get suppliers_load_failed => 'Не удалось загрузить поставщиков';

  @override
  String get session_expired_login_again => 'Сеанс завершен, войдите снова';

  @override
  String get chat_open_failed => 'Не удалось открыть чат с поставщиком';

  @override
  String get chat_create_failed => 'Не удалось пообщаться с поставщиком';

  @override
  String get search_no_results =>
      'Запрос не был предоставлен без четверостишия';

  @override
  String search_no_results_for(int query) {
    return 'К запросам «$query\"без саответа не дано';
  }

  @override
  String get suppliers_catalog_access_denied =>
      'Каталог поставщиков доступен только модераторам и основным администраторам.';

  @override
  String get product_nutritional_info => 'Пищевая ценность';

  @override
  String get product_per_100g => 'В 100 граммах:';

  @override
  String get product_calories => 'Калории';

  @override
  String get product_proteins => 'Белки';

  @override
  String get product_fats => 'Жиры';

  @override
  String get product_carbohydrates => 'Углеводы';

  @override
  String get unit_kcal_short => 'к';

  @override
  String get unit_g_short => 'г';

  @override
  String product_qa_answer_from(String name) {
    return 'Ответ от $name';
  }

  @override
  String get qa_edit_answer => 'Изменить ответ';

  @override
  String product_added_to_cart_msg(String name, int qty) {
    return 'Добавлено в корзину: $name -$qty шт.';
  }

  @override
  String get product_added_to_favorites => 'Добавлено в избранное';

  @override
  String get rating_buyers_short => 'П';

  @override
  String rating_count_format(int count) {
    return 'Оценок ($count)';
  }

  @override
  String get rating_read_all => 'Читать все';

  @override
  String rating_count_label(int count) {
    return 'Оценок: $count';
  }

  @override
  String get rating_no_reviews =>
      'Пока нет отзывов. Станьте первым, кто оценит товар.';

  @override
  String get rating_buyer => 'Покупатель';

  @override
  String get rating_no_review_text => 'Без текста отзыва';

  @override
  String get qa_supplier_genitive => 'поставщика';

  @override
  String get auto_redaktirovatAdres => 'Редактировать адрес';

  @override
  String get auto_dobavitAdres => 'Добавить адрес';

  @override
  String get auto_adres => 'АДРЕС';

  @override
  String get auto_ulitsa => 'УЛИЦА';

  @override
  String get auto_pochtovyyIndeks => 'ПОЧТОВЫЙ ИНДЕКС';

  @override
  String get auto_kvartira => 'КВАРТИРА';

  @override
  String get auto_dom => 'Дом';

  @override
  String get auto_rabota => 'Работа';

  @override
  String get auto_drugoe => 'Другое';

  @override
  String get auto_sohranit => 'СОХРАНИТЬ';

  @override
  String get auto_sohranitAdres => 'СОХРАНИТЬ АДРЕС';

  @override
  String get auto_vvediteAdres => 'Введите адрес';

  @override
  String get auto_adresSlishkomKorotkiy => 'Адрес слишком короткий';

  @override
  String get auto_ulitsa_1 => 'Улица';

  @override
  String get auto_indeksDolzhenSoderzhat =>
      'Индекс должен содержать только цифры (3-10)';

  @override
  String get auto_kvartira_1 => 'Квартира';

  @override
  String get auto_nekorrektnyyFormatKvart => 'Некорректный формат квартиры';

  @override
  String get auto_vvediteImyaVladeltsaKa => 'Введите имя владельца карты';

  @override
  String get auto_imyaSlishkomKorotkoe => 'Имя слишком короткое';

  @override
  String get auto_imyaNeDolzhnoSoderzhat => 'Имя не должно содержать цифры';

  @override
  String get auto_vvediteNomerKarty => 'Введите номер карты';

  @override
  String get auto_nomerKartyDolzhenByt1 => 'Номер карты должен быть 16 цифр';

  @override
  String get auto_nevernyyNomerKarty => 'Неверный номер карты';

  @override
  String get auto_vvediteSrokDeystviya => 'Введите срок действия';

  @override
  String get auto_vvediteFormatMmgg => 'Введите формат ММ/ГГ';

  @override
  String get auto_mesyatsDolzhenByt0112 => 'Месяц должен быть 01-12';

  @override
  String get auto_srokDeystviyaIstyok => 'Срок действия истёк';

  @override
  String get auto_vvediteCvc => 'Введите CVC';

  @override
  String get auto_cvc3Tsifry => 'CVC: 3 цифры';

  @override
  String get auto_voyditeChtobyDobavitKa => 'Войдите, чтобы добавить карту';

  @override
  String get auto_proverteVvedyonnyeDanny => 'Проверьте введённые данные';

  @override
  String get auto_neUdalosSohranitKartu => 'Не удалось сохранить карту';

  @override
  String get auto_dobavitMetodOplaty => 'Добавить метод оплаты';

  @override
  String get auto_imyaVladeltsaKarty => 'ИМЯ ВЛАДЕЛЬЦА КАРТЫ';

  @override
  String get auto_nomerKarty => 'НОМЕР КАРТЫ';

  @override
  String get auto_srokDeystviya => 'СРОК ДЕЙСТВИЯ';

  @override
  String get auto_mmgg => 'ММ/ГГ';

  @override
  String get auto_dobavitMetodOplaty_1 => 'ДОБАВИТЬ МЕТОД ОПЛАТЫ';

  @override
  String get auto_vvediteTekushchiyParol => 'Введите текущий пароль';

  @override
  String get auto_minimum6Simvolov => 'Минимум 6 символов';

  @override
  String get auto_vvediteNovyyParol => 'Введите новый пароль';

  @override
  String get auto_novyyParolDolzhenOtlic =>
      'Новый пароль должен отличаться от текущего';

  @override
  String get auto_povtoriteNovyyParol => 'Повторите новый пароль';

  @override
  String get auto_paroliNeSovpadayut => 'Пароли не совпадают';

  @override
  String get auto_neUdalosIzmenitParol => 'Не удалось изменить пароль';

  @override
  String get auto_sessiyaIsteklaVoyditeS => 'Сессия истекла. Войдите снова.';

  @override
  String get auto_izmenitParol => 'Изменить пароль';

  @override
  String get auto_tekushchiyParol => 'Текущий пароль';

  @override
  String get auto_novyyParol => 'Новый пароль';

  @override
  String get auto_vvediteParolEshchyoRaz => 'Введите пароль ещё раз';

  @override
  String get auto_parolDolzhenSoderzhatM =>
      'Пароль должен содержать минимум 6 символов и отличаться от текущего.';

  @override
  String get auto_sohranitParol => 'СОХРАНИТЬ ПАРОЛЬ';

  @override
  String get auto_ivanIvanov => 'Иван Иванов';

  @override
  String get auto_lyublyuSladosti => 'Люблю сладости';

  @override
  String get auto_sdelatSnimok => 'Сделать снимок';

  @override
  String get auto_vybratIzGalerei => 'Выбрать из галереи';

  @override
  String get auto_udalitFoto => 'Удалить фото';

  @override
  String get auto_vyNeAvtorizovany => 'Вы не авторизованы';

  @override
  String get auto_razmerFaylaNeDolzhenP =>
      'Размер файла не должен превышать 5 МБ';

  @override
  String get auto_redProfil => 'Ред. Профиль';

  @override
  String get auto_fio => 'ФИО';

  @override
  String get auto_elPochta => 'ЭЛ. ПОЧТА';

  @override
  String get auto_nomer => 'НОМЕР';

  @override
  String get auto_opisanie => 'ОПИСАНИЕ';

  @override
  String get auto_nomerDolzhenBytVForma =>
      'Номер должен быть в формате +7-XXX-XXX-XXXX';

  @override
  String get auto_kakSdelatZakaz => 'Как сделать заказ?';

  @override
  String get auto_chtobySdelatZakazVyber =>
      'Чтобы сделать заказ, выберите товары из каталога, добавьте их в корзину и оформите заказ, указав адрес доставки и способ оплаты.';

  @override
  String get auto_kakieSposobyOplatyDost => 'Какие способы оплаты доступны?';

  @override
  String get auto_myPrinimaemOplatuNalic =>
      'Мы принимаем оплату наличными, банковскими картами (Visa, Mastercard), а также через PayPal.';

  @override
  String get auto_skolkoVremeniZanimaetD =>
      'Сколько времени занимает доставка?';

  @override
  String get auto_standartnayaDostavkaZan =>
      'Стандартная доставка занимает 1-3 рабочих дня. Экспресс-доставка доступна в течение 24 часов.';

  @override
  String get auto_moguLiYaOtmenitZakaz => 'Могу ли я отменить заказ?';

  @override
  String get auto_vyMozheteOtmenitZakaz =>
      'Вы можете отменить заказ в течение 30 минут после оформления. После этого заказ уже будет передан на склад для сборки.';

  @override
  String get auto_kakIzmenitAdresDostavk => 'Как изменить адрес доставки?';

  @override
  String get auto_profil => 'Профиль';

  @override
  String get auto_adresa => 'Адреса';

  @override
  String get auto_chtoDelatEsliTovarNe => 'Что делать если товар не подошел?';

  @override
  String get auto_vyMozheteVernutTovarV =>
      'Вы можете вернуть товар в течение 14 дней с момента получения. Свяжитесь с нашей службой поддержки для оформления возврата.';

  @override
  String get auto_kakSvyazatsyaSPodderzh => 'Как связаться с поддержкой?';

  @override
  String get auto_tehpodderzhka => 'Техподдержка';

  @override
  String get auto_estLiMinimalnayaSumma => 'Есть ли минимальная сумма заказа?';

  @override
  String get auto_minimalnayaSummaZakaza =>
      'Минимальная сумма заказа составляет 500 ₸. При заказе от 5000 ₸ доставка бесплатная.';

  @override
  String get auto_voprosyIOtvety => 'Вопросы и ответы';

  @override
  String get auto_nazad => 'Назад';

  @override
  String get auto_izbrannoe => 'Избранное';

  @override
  String get auto_vkladkaIzbrannyeTovary => 'Вкладка избранные товары';

  @override
  String get auto_vkladkaIzbrannyeKompani => 'Вкладка избранные компании';

  @override
  String get auto_pokaNetIzbrannyhTovaro => 'Пока нет избранных товаров';

  @override
  String get auto_netIzbrannyhKompaniy => 'Нет избранных компаний';

  @override
  String get auto_neUdalosZagruzitAdresa => 'Не удалось загрузить адреса';

  @override
  String get auto_nuzhnoVoytiVAkkaunt => 'Нужно войти в аккаунт';

  @override
  String get auto_neUdalosSohranitAdres => 'Не удалось сохранить адрес';

  @override
  String get auto_zakryt => 'Закрыть';

  @override
  String get auto_neUdalosUdalitAdres => 'Не удалось удалить адрес';

  @override
  String get auto_moiAdresa => 'Мои адреса';

  @override
  String get auto_adresovPokaNet => 'Адресов пока нет';

  @override
  String get auto_dobavteAdresChtobyOfor =>
      'Добавьте адрес, чтобы оформить заказ быстрее.';

  @override
  String get auto_bezAdresa => 'Без адреса';

  @override
  String get auto_redaktirovat => 'Редактировать';

  @override
  String get auto_udalit => 'Удалить';

  @override
  String get auto_udalitAdres => 'Удалить адрес?';

  @override
  String get auto_otmena => 'Отмена';

  @override
  String get auto_kartaDobavlena => 'Карта добавлена';

  @override
  String get auto_metodOplaty => 'Метод оплаты';

  @override
  String get auto_nalichnye => 'Наличные';

  @override
  String get auto_dobavitNovyy => 'Добавить новый';

  @override
  String get auto_netKartVisa => 'Нет карт Visa';

  @override
  String get auto_netKartMastercard => 'Нет карт Mastercard';

  @override
  String get auto_dobavteKartuVisaChtoby =>
      'Добавьте карту Visa, чтобы выбрать этот способ оплаты.';

  @override
  String get auto_dobavteKartuMastercard =>
      'Добавьте карту Mastercard, чтобы выбрать этот способ оплаты.';

  @override
  String get auto_vashiKartyVisa => 'Ваши карты Visa';

  @override
  String get auto_vashiKartyMastercard => 'Ваши карты Mastercard';

  @override
  String get auto_vashiKarty => 'Ваши карты';

  @override
  String get auto_oplataNalichnymi => 'Оплата наличными';

  @override
  String get auto_vyVybraliOplatuNalichn =>
      'Вы выбрали оплату наличными при получении.';

  @override
  String get auto_podklyucheniePaypalPoka =>
      'Подключение PayPal пока недоступно.\\nВыберите карту или наличные.';

  @override
  String get auto_netSposobaOplaty => 'Нет способа оплаты';

  @override
  String get auto_pozhaluystaVyberiteSpos =>
      'Пожалуйста, выберите способ\\nоплаты';

  @override
  String get auto_udalitKartu => 'Удалить карту';

  @override
  String get auto_kartaUdalena => 'Карта удалена';

  @override
  String get auto_neUkazano => 'Не указано';

  @override
  String get auto_vvediteImya => 'Введите имя';

  @override
  String get auto_vvediteEmail => 'Введите email';

  @override
  String get auto_nekorrektnyyEmail => 'Некорректный email';

  @override
  String get auto_vvediteNomerTelefona => 'Введите номер телефона';

  @override
  String get auto_nomerDolzhenBytVForma_1 =>
      'Номер должен быть в формате +7-000-000-0000';

  @override
  String get auto_imyaSohraneno => 'Имя сохранено';

  @override
  String get auto_emailSohranen => 'Email сохранен';

  @override
  String get auto_nomerSohranen => 'Номер сохранен';

  @override
  String get auto_vvediteNazvanieKompanii => 'Введите название компании';

  @override
  String get auto_nazvanieKompaniiSohrane => 'Название компании сохранено';

  @override
  String get auto_lichnayaInformatsiya => 'Личная информация';

  @override
  String get auto_nazvanieKompanii => 'НАЗВАНИЕ КОМПАНИИ';

  @override
  String get auto_vvediteNovoeZnachenie => 'Введите новое значение';

  @override
  String get auto_sohranit_1 => 'Сохранить';

  @override
  String get auto_nastroyki => 'Настройки';

  @override
  String get auto_vyyti => 'Выйти';

  @override
  String get auto_moiZakazy => 'Мои заказы';

  @override
  String get auto_istoriyaZakazov => 'История заказов';

  @override
  String get auto_sposobOplaty => 'Способ оплаты';

  @override
  String get auto_vashiOtzyvy => 'Ваши отзывы';

  @override
  String get auto_bystrayaDostavka => 'Быстрая доставка';

  @override
  String get auto_horoshayaTsena => 'Хорошая цена';

  @override
  String get auto_kachestvennayaUpakovka => 'Качественная упаковка';

  @override
  String get auto_svezhiyTovar => 'Свежий товар';

  @override
  String get auto_vezhlivyyKurer => 'Вежливый курьер';

  @override
  String get auto_voyditeChtobyUvidetOtz => 'Войдите, чтобы увидеть отзывы.';

  @override
  String get auto_neUdalosZagruzitOtzyvy => 'Не удалось загрузить отзывы.';

  @override
  String get auto_estPokupkiDlyaOtsenki => 'Есть покупки для оценки';

  @override
  String get auto_vseOtzyvyOPokupkah => 'Все отзывы о покупках';

  @override
  String get auto_pokaNetOtzyvov => 'Пока нет отзывов';

  @override
  String get auto_ozhidayutOtzyvov => 'Ожидают отзывов';

  @override
  String get auto_otsenitePokupkiEtoPomo =>
      'Оцените покупки - это помогает другим';

  @override
  String get auto_otpravlyaem => 'Отправляем...';

  @override
  String get auto_ostavitOtzyv => 'Оставить отзыв';

  @override
  String get auto_ostavteOtzyvPoslePriny =>
      'Оставьте отзыв после принятия заказа - он появится здесь.';

  @override
  String get auto_tekstOtzyva => 'Текст отзыва';

  @override
  String get auto_bezTekstaOtzyva => 'Без текста отзыва';

  @override
  String get auto_sohranyaem => 'Сохраняем...';

  @override
  String get auto_otseniteTovar => 'Оцените товар';

  @override
  String get auto_vashOtzyv => 'Ваш отзыв';

  @override
  String get auto_podelitesVpechatleniyami => 'Поделитесь впечатлениями';

  @override
  String get auto_izmenit => 'Изменить';

  @override
  String get auto_voyditeChtobyRedaktirov =>
      'Войдите, чтобы редактировать отзыв';

  @override
  String get auto_otzyvObnovlen => 'Отзыв обновлен';

  @override
  String get auto_neUdalosSohranitOtzyv => 'Не удалось сохранить отзыв';

  @override
  String get auto_postavteOtsenku => 'Поставьте оценку';

  @override
  String get auto_dobavteDetali => 'Добавьте детали';

  @override
  String get auto_otpravitOtzyv => 'Отправить отзыв';

  @override
  String get auto_voyditeChtobyOstavitOt => 'Войдите, чтобы оставить отзыв';

  @override
  String get auto_spasiboZaOtzyv => 'Спасибо за отзыв!';

  @override
  String get auto_neUdalosOtpravitOtzyv => 'Не удалось отправить отзыв';

  @override
  String get auto_voyditeChtobyUdalitOtz => 'Войдите, чтобы удалить отзыв';

  @override
  String get auto_otzyvUdalen => 'Отзыв удален';

  @override
  String get auto_neUdalosUdalitOtzyv => 'Не удалось удалить отзыв';

  @override
  String get auto_udalitOtzyv => 'Удалить отзыв?';

  @override
  String get auto_etoDeystvieNelzyaOtmen => 'Это действие нельзя отменить.';

  @override
  String get auto_rezervnyeKodyDvuhfaktor =>
      'Резервные коды двухфакторной аутентификации\\n';

  @override
  String get auto_sohraniteIhVNadyozhnom =>
      'Сохраните их в надёжном месте - каждый код можно использовать только один раз.\\n';

  @override
  String get auto_kodySkopirovanyVBufer => 'Коды скопированы в буфер обмена';

  @override
  String get auto_faylSKodamiSohranyon => 'Файл с кодами сохранён';

  @override
  String get auto_rezervnyeKody => 'Резервные коды';

  @override
  String get auto_rezervnyeKodyDvuhfaktor_1 =>
      'Резервные коды двухфакторной аутентификации';

  @override
  String get auto_sohraniteKodyVBezopasn =>
      'Сохраните коды в безопасном месте — они показываются один раз. Каждый код можно использовать только однократно для входа, если потерян доступ к почте.';

  @override
  String get auto_gotovo => 'Готово';

  @override
  String get auto_neUdalosOtpravitKodPo =>
      'Не удалось отправить код. Попробуйте ещё раз.';

  @override
  String get auto_dvuhfaktornayaAutentifik =>
      'Двухфакторная аутентификация отключена';

  @override
  String get auto_nevernyyKod => 'Неверный код';

  @override
  String get auto_oshibkaPodklyucheniyaK => 'Ошибка подключения к серверу';

  @override
  String get auto_kodOtpravlenPovtorno => 'Код отправлен повторно';

  @override
  String get auto_neUdalosOtpravitKodPo_1 =>
      'Не удалось отправить код повторно';

  @override
  String get auto_vyklyuchenie2fa => 'Выключение 2FA';

  @override
  String get auto_podtverzhdeniePoPochte => 'Подтверждение по почте';

  @override
  String get auto_vvediteKodPodtverzhdeni =>
      'Введите код подтверждения, отправленный на вашу почту, ';

  @override
  String get auto_chtobyVyklyuchitDvuhfak =>
      'чтобы выключить двухфакторную аутентификацию.';

  @override
  String get auto_povtoritOtpravku => 'Повторить отправку';

  @override
  String get auto_srokDeystviyaKodaIstyo =>
      'Срок действия кода истёк, отправьте повторно';

  @override
  String get auto_srokIstyok => 'СРОК ИСТЁК';

  @override
  String get auto_otpravitPovtorno => 'Отправить повторно';

  @override
  String get auto_podtverdit => 'Подтвердить';

  @override
  String get auto_vklyuchenie2fa => 'Включение 2FA';

  @override
  String get auto_chtobyVklyuchitDvuhfakt =>
      'чтобы включить двухфакторную аутентификацию.';

  @override
  String get auto_neUdalosZagruzitStatus =>
      'Не удалось загрузить статус двухфакторной аутентификации';

  @override
  String get auto_regeneratsiyaBackupkodov => 'Регенерация backup-кодов';

  @override
  String get auto_chtobyZamenitTekushchie =>
      'чтобы заменить текущие резервные коды.';

  @override
  String get auto_neUdalosSgenerirovatNo =>
      'Не удалось сгенерировать новые коды';

  @override
  String get auto_otzyvDoverennyhUstroyst => 'Отзыв доверенных устройств';

  @override
  String get auto_chtobyOtozvatVseRanee =>
      'чтобы отозвать все ранее запомненные устройства.';

  @override
  String get auto_doverennyeUstroystvaOto => 'Доверенные устройства отозваны';

  @override
  String get auto_neUdalosOtozvatUstroys => 'Не удалось отозвать устройства';

  @override
  String get auto_dvuhfaktornayaAutentifik_1 => 'Двухфакторная аутентификация';

  @override
  String get auto_povtorit => 'Повторить';

  @override
  String get auto_ostalosMaloRezervnyhKo =>
      'Осталось мало резервных кодов, сгенерируйте новые';

  @override
  String get auto_vklyuchenaPriVhodePotr =>
      'Включена. При входе потребуется код из почты.';

  @override
  String get auto_vyklyuchenaZashchititeA =>
      'Выключена. Защитите аккаунт дополнительным кодом.';

  @override
  String get auto_sgenerirovatNovyeBackup => 'Сгенерировать новые backup-коды';

  @override
  String get auto_staryeKodyBudutUdaleny => 'Старые коды будут удалены';

  @override
  String get auto_otozvatDoverennyeUstroy => 'Отозвать доверенные устройства';

  @override
  String get auto_naVsehUstroystvahPotre =>
      'На всех устройствах потребуется код заново';

  @override
  String get auto_neUdalosOpredelitPolzo =>
      'Не удалось определить пользователя';

  @override
  String get auto_neUdalosZagruzitChat => 'Не удалось загрузить чат';

  @override
  String get auto_chatZakrytSozdayteNovo =>
      'Чат закрыт. Создайте новое обращение.';

  @override
  String get auto_vvediteSoobshchenie => 'Введите сообщение';

  @override
  String get auto_neUdalosOtpravitSoobsh => 'Не удалось отправить сообщение';

  @override
  String get auto_chatSTehpodderzhkoy => 'Чат с техподдержкой';

  @override
  String get auto_aktivnogoChataNetSnach =>
      'Активного чата нет. Сначала отправьте обращение в техподдержку.';

  @override
  String get auto_chatNeNayden => 'Чат не найден.';

  @override
  String get auto_podderzhka => 'Поддержка';

  @override
  String get auto_chatZakryt => 'Чат закрыт';

  @override
  String get auto_chatOtkrytTehpodderzhka =>
      'Чат открыт. Техподдержка ответит в этом окне.';

  @override
  String get auto_operatoryOnlaynObychno =>
      'Операторы онлайн. Обычно отвечаем быстро.';

  @override
  String get auto_seychasOflaynOtvetimV =>
      'Сейчас офлайн. Ответим в рабочее время.';

  @override
  String get auto_opishiteProblemu => 'Опишите проблему';

  @override
  String get auto_problemaSZakazom => 'Проблема с заказом';

  @override
  String get auto_problemaSOplatoy => 'Проблема с оплатой';

  @override
  String get auto_tehnicheskieNepoladki => 'Технические неполадки';

  @override
  String get auto_voprosOTovare => 'Вопрос о товаре';

  @override
  String get auto_neUdalosZagruzitObrash => 'Не удалось загрузить обращение';

  @override
  String get auto_obrashchenieOtpravlenoV =>
      'Обращение отправлено в техподдержку';

  @override
  String get auto_soobshchenieOtpravleno => 'Сообщение отправлено';

  @override
  String get auto_neUdalosOtpravitObrash => 'Не удалось отправить обращение';

  @override
  String get auto_svyazhitesSNami => 'Свяжитесь с нами';

  @override
  String get auto_pnvs09002100Utc5 => 'Пн-Вс: 09:00 - 21:00 (UTC+5)';

  @override
  String get auto_prodolzhitObrashchenie => 'Продолжить обращение';

  @override
  String get auto_otpravitObrashchenie => 'Отправить обращение';

  @override
  String get auto_aktivnyyChatOtkryt => 'Активный чат открыт';

  @override
  String get auto_predydushcheeObrashcheni =>
      'Предыдущее обращение закрыто. Если вопрос актуален, отправьте новое.';

  @override
  String get auto_otkrytChatSTehpodderzh => 'Открыть чат с техподдержкой';

  @override
  String get auto_kategoriyaObrashcheniya => 'Категория обращения';

  @override
  String get auto_vyberiteKategoriyu => 'Выберите категорию';

  @override
  String get auto_temaObrashcheniya => 'Тема обращения';

  @override
  String get auto_vvediteTemu => 'Введите тему';

  @override
  String get auto_soobshchenie => 'Сообщение';

  @override
  String get auto_otpravit => 'Отправить';

  @override
  String get auto_dostavlen => 'доставлен';

  @override
  String get auto_dostavleno => 'доставлено';

  @override
  String get auto_vPuti => 'в пути';

  @override
  String get auto_sobira => 'собира';

  @override
  String get auto_prinyat => 'принят';

  @override
  String get auto_prinyata => 'принята';

  @override
  String get auto_prinyato => 'принято';

  @override
  String get auto_prinyaty => 'приняты';

  @override
  String get auto_otmen => 'отмен';

  @override
  String get auto_min => 'мин';

  @override
  String get auto_adresDostavki => 'Адрес доставки';

  @override
  String get auto_podtverditVybor => 'Подтвердить выбор';

  @override
  String get auto_dobavteAdresChtobyProd =>
      'Добавьте адрес, чтобы продолжить оформление.';

  @override
  String get auto_voyditeChtobyOformitZa => 'Войдите, чтобы оформить заказ';

  @override
  String get auto_pozitsiya => 'позиция';

  @override
  String get auto_pozitsii => 'позиции';

  @override
  String get auto_pozitsiy => 'позиций';

  @override
  String get auto_ochistitKorzinu => 'Очистить корзину';

  @override
  String get auto_napit => 'напит';

  @override
  String get auto_ovoshch => 'овощ';

  @override
  String get auto_frukt => 'фрукт';

  @override
  String get auto_hleb => 'хлеб';

  @override
  String get auto_pekar => 'пекар';

  @override
  String get auto_moloch => 'молоч';

  @override
  String get auto_myas => 'мяс';

  @override
  String get auto_ptits => 'птиц';

  @override
  String get auto_katalog => 'Каталог';

  @override
  String get auto_poiskKategoriy => 'Поиск категорий...';

  @override
  String get auto_netKategoriy => 'Нет категорий';

  @override
  String get auto_nichegoNeNaydeno => 'Ничего не найдено';

  @override
  String get auto_poiskPodkategoriy => 'Поиск подкатегорий...';

  @override
  String get auto_vEtoyKategoriiPokaNet => 'В этой категории пока нет товаров';

  @override
  String get auto_vse => 'все';

  @override
  String get auto_barlyy => 'барлығы';

  @override
  String get auto_skid => 'скид';

  @override
  String get auto_zaDen => 'За день';

  @override
  String get auto_nedelya => 'Неделя';

  @override
  String get auto_mesyats => 'Месяц';

  @override
  String get auto_kvartal => 'Квартал';

  @override
  String get auto_filtr => 'Фильтр';

  @override
  String get auto_eksportirovatVExcel => 'Экспортировать в .excel';

  @override
  String get auto_istoriyaPokaPustaya => 'История пока пустая';

  @override
  String get auto_netTovarov => 'Нет товаров';

  @override
  String get auto_status => 'Статус';

  @override
  String get auto_dataZakaza => 'Дата заказа';

  @override
  String get auto_kolichestvoTovarov => 'Количество товаров';

  @override
  String get auto_obshcheeKolvo => 'Общее кол-во';

  @override
  String get auto_polucheno => 'Получено';

  @override
  String get auto_tovaryVZakaze => 'Товары в заказе';

  @override
  String get auto_polucheno_1 => 'получено';

  @override
  String get auto_zaversheno => 'завершено';

  @override
  String get auto_trebuetsyaAvtorizatsiya => 'Требуется авторизация';

  @override
  String get auto_faylZagruzhen => 'Файл загружен';

  @override
  String get auto_netVNalichii => 'Нет в наличии';

  @override
  String get auto_oTovare => 'О товаре';

  @override
  String get auto_podrobnee => 'Подробнее';

  @override
  String get auto_postavshchik => 'Поставщик';

  @override
  String get auto_udalitIzIzbrannogo => 'Удалить из избранного';

  @override
  String get auto_dobavitVIzbrannoe => 'Добавить в избранное';

  @override
  String get auto_dobavlenoVIzbrannoe => 'Добавлено в избранное';

  @override
  String get auto_udalenoIzIzbrannogo => 'Удалено из избранного';

  @override
  String get auto_otzyvovPokaNet => 'Отзывов пока нет';

  @override
  String get auto_otsenitTovarMozhnoTolk =>
      'Оценить товар можно только после ее покупки';

  @override
  String get auto_voprosovPoTovaruEshche => 'Вопросов по товару еще не было';

  @override
  String get auto_budtePervym => 'Будьте первым!';

  @override
  String get auto_zadatVopros => 'Задать вопрос';

  @override
  String get auto_voprosov => 'вопросов';

  @override
  String get auto_harakteristiki => 'Характеристики';

  @override
  String get auto_opisanie_1 => 'Описание';

  @override
  String get auto_netDannyhOTovare => 'Нет данных о товаре';

  @override
  String get auto_opisanieNeUkazano => 'Описание не указано';

  @override
  String get auto_pokupatel => 'Покупатель';

  @override
  String get auto_bezTeksta => 'Без текста';

  @override
  String get auto_pereytiKoVsemOtzyvam => 'Перейти ко всем отзывам';

  @override
  String get auto_pereytiKoVsemVoprosam => 'Перейти ко всем вопросам';

  @override
  String get auto_voprosyOTovare => 'Вопросы о товаре';

  @override
  String get auto_oshibka => 'Ошибка';

  @override
  String get auto_netVoprosov => 'Нет вопросов';

  @override
  String get auto_budtePervymKtoZadastV => 'Будьте первым, кто задаст вопрос!';

  @override
  String get auto_tovar => 'Товар';

  @override
  String get auto_vashVopros => 'Ваш вопрос';

  @override
  String get auto_neUdalosZagruzitOtzyvy_1 => 'Не удалось загрузить отзывы';

  @override
  String get auto_otzyvy => 'Отзывы';

  @override
  String get auto_zdesPoyavyatsyaOtsenki =>
      'Здесь появятся оценки и мнения покупателей.';

  @override
  String get auto_svernut => 'Свернуть';

  @override
  String get auto_otvetProdavtsa => 'Ответ продавца';

  @override
  String get auto_vse_1 => 'Все';

  @override
  String get auto_postavshchikNeNayden => 'Поставщик не найден';

  @override
  String get auto_vremyaOzhidaniya => 'Время ожидания';

  @override
  String get auto_vremyaOzhidaniyaIsteklo =>
      'Время ожидания истекло. Проверьте соединение и повторите попытку.';

  @override
  String get auto_netPodklyucheniyaKInte => 'Нет подключения к интернету';

  @override
  String get auto_neUdalosZagruzitDannye =>
      'Не удалось загрузить данные. Попробуйте ещё раз.';

  @override
  String get auto_netTovarovOtEtogoPost => 'Нет товаров от этого поставщика';

  @override
  String get auto_tovaryNeNaydeny => 'Товары не найдены';

  @override
  String get auto_poisk => 'Поиск...';

  @override
  String get auto_proizoshlaOshibka => 'Произошла ошибка';

  @override
  String get auto_vernutsya => 'Вернуться';

  @override
  String get auto_filtry => 'Фильтры';

  @override
  String get auto_tsenaZaSht => 'Цена за шт.';

  @override
  String get auto_ot => 'от';

  @override
  String get auto_do => 'до';

  @override
  String get auto_sortirovka => 'Сортировка';

  @override
  String get auto_tsena => 'Цена';

  @override
  String get auto_reyting => 'Рейтинг';

  @override
  String get auto_poryadok => 'Порядок';

  @override
  String get auto_poVozrastaniyu => 'По возрастанию';

  @override
  String get auto_poUbyvaniyu => 'По убыванию';

  @override
  String get auto_appmessagedialogPodderzh =>
      'AppMessageDialog поддерживает максимум 3 действия';

  @override
  String get auto_poiskPoPostavshchikam => 'Поиск по поставщикам';

  @override
  String get auto_ochistit => 'Очистить';

  @override
  String get auto_neprochitannoeUvedomleni => 'непрочитанное уведомление';

  @override
  String get auto_neprochitannyhUvedomleni => 'непрочитанных уведомления';

  @override
  String get auto_neprochitannyhUvedomleni_1 => 'непрочитанных уведомлений';

  @override
  String get auto_zastreval => 'застревал';

  @override
  String get auto_dostavka => 'доставка';

  @override
  String get auto_budni => 'будни';

  @override
  String get auto_vyhodnye => 'выходные';

  @override
  String get auto_ezhednevno => 'ежедневно';

  @override
  String get auto_kazhdyyDen => 'каждый день';

  @override
  String get auto_pn => 'Пн';

  @override
  String get auto_pn_1 => 'пн';

  @override
  String get auto_vt => 'вт';

  @override
  String get auto_sr => 'ср';

  @override
  String get auto_cht => 'чт';

  @override
  String get auto_pt => 'пт';

  @override
  String get auto_sb => 'сб';

  @override
  String get auto_vs => 'вс';

  @override
  String get auto_ponedelnik => 'понедельник';

  @override
  String get auto_vtornik => 'вторник';

  @override
  String get auto_sreda => 'среда';

  @override
  String get auto_chetverg => 'четверг';

  @override
  String get auto_pyatnitsa => 'пятница';

  @override
  String get auto_subbota => 'суббота';

  @override
  String get auto_voskresene => 'воскресенье';

  @override
  String get auto_sht => 'шт';

  @override
  String get auto_izmenitOtvet => 'Изменить ответ';

  @override
  String get auto_otvetit => 'Ответить';

  @override
  String get auto_otvetitNaVopros => 'Ответить на вопрос';

  @override
  String get auto_vopros => 'Вопрос:';

  @override
  String get auto_vashOtvet => 'Ваш ответ';

  @override
  String get auto_otvetitNaOtzyv => 'Ответить на отзыв';

  @override
  String get auto_otzyv => 'Отзыв:';

  @override
  String get auto_vveditePochtuIParol => 'Введите почту и пароль';

  @override
  String get auto_serverNeVernulChalleng =>
      'Сервер не вернул challenge для 2FA';

  @override
  String get auto_proverteChtoPochtaIPa =>
      'Проверьте, что почта и пароль заполнены';

  @override
  String get auto_nevernayaPochtaIliParo => 'Неверная почта или пароль';

  @override
  String get auto_dostupZapreshchyon => 'Доступ запрещён';

  @override
  String get auto_neUdalosVypolnitVhodP =>
      'Не удалось выполнить вход. Попробуйте позже.';

  @override
  String get auto_vhodVypolnen => 'Вход выполнен';

  @override
  String get auto_voyti => 'Войти';

  @override
  String get auto_zayditeIliZaregistriruy => 'Зайдите или зарегистрируйтесь';

  @override
  String get auto_vSvoyAkkaunt => 'В свой аккаунт';

  @override
  String get auto_pochta => 'ПОЧТА';

  @override
  String get auto_parol => 'ПАРОЛЬ';

  @override
  String get auto_zapomnitMenya => 'Запомнить меня';

  @override
  String get auto_zabyliParol => 'Забыли пароль?';

  @override
  String get auto_voyti_1 => 'ВОЙТИ';

  @override
  String get auto_netAkkaunta => 'Нет аккаунта? ';

  @override
  String get auto_zaregistriruytes => 'Зарегистрируйтесь';

  @override
  String get auto_vvedite10simvolnyyBacku => 'Введите 10-символьный backup-код';

  @override
  String get auto_srokDeystviyaKodaIstyo_1 =>
      'Срок действия кода истёк, повторите вход';

  @override
  String get auto_podtverzhdenieVhoda => 'Подтверждение входа';

  @override
  String get auto_dvuhfaktornayanautentifik => 'Двухфакторная\\nаутентификация';

  @override
  String get auto_myOtpraviliKodNaVashu => 'Мы отправили код на вашу почту';

  @override
  String get auto_backupkod => 'BACKUP-КОД';

  @override
  String get auto_kodIzPochty => 'КОД ИЗ ПОЧТЫ';

  @override
  String get auto_otpravitSnova => 'Отправить снова';

  @override
  String get auto_vernutsyaKKoduIzPocht => 'Вернуться к коду из почты';

  @override
  String get auto_ispolzovatBackupkod => 'Использовать backup-код';

  @override
  String get auto_zapomnitUstroystvoNa30 => 'Запомнить устройство на 30 дней';

  @override
  String get auto_imyaDolzhnoBytNeKoroc =>
      'Имя должно быть не короче 2 символов';

  @override
  String get auto_vveditePochtu => 'Введите почту';

  @override
  String get auto_vvediteKorrektnuyuPocht => 'Введите корректную почту';

  @override
  String get auto_nomerDolzhenNachinatsya => 'Номер должен начинаться с +7';

  @override
  String get auto_vvediteParol => 'Введите пароль';

  @override
  String get auto_parolDolzhenBytNeKoro =>
      'Пароль должен быть не короче 6 символов';

  @override
  String get auto_povtoriteParol => 'Повторите пароль';

  @override
  String get auto_emailUzheZaregistrirova => 'Email уже зарегистрирован';

  @override
  String get auto_tronuto => 'тронуто';

  @override
  String get auto_proverteZapolneniePoley => 'Проверьте заполнение полей';

  @override
  String get auto_rol => 'РОЛЬ';

  @override
  String get auto_imya => 'ИМЯ';

  @override
  String get auto_nomerTelefona => 'НОМЕР ТЕЛЕФОНА';

  @override
  String get auto_naprimerTooSkladMansa => 'Например, ТОО Склад Манса';

  @override
  String get auto_dopolnitelnyeDannyeNeT =>
      'Дополнительные данные не требуются.';

  @override
  String get auto_povtoriteParol_1 => 'ПОВТОРИТЕ ПАРОЛЬ';

  @override
  String get auto_tronutoe => 'тронутое';

  @override
  String get auto_dannye => 'Данные';

  @override
  String get auto_kompaniyaIParol => 'Компания и пароль';

  @override
  String get auto_parol_1 => 'Пароль';

  @override
  String get auto_zaregistrirovatsya => 'ЗАРЕГИСТРИРОВАТЬСЯ';

  @override
  String get auto_dalee => 'ДАЛЕЕ';

  @override
  String get auto_registratsiyaProshlaUsp => 'Регистрация прошла успешно';

  @override
  String get auto_serverVernulOshibku => 'Сервер вернул ошибку';

  @override
  String get auto_neUdalosZavershitRegis => 'Не удалось завершить регистрацию';

  @override
  String get auto_serverVernulOshibkuPop =>
      'Сервер вернул ошибку. Попробуйте снова.';

  @override
  String get auto_oshibkaPodklyucheniya => 'Ошибка подключения';

  @override
  String get auto_registratsiya => 'Регистрация';

  @override
  String get auto_zaregistriruytesChtobyN => 'Зарегистрируйтесь чтобы начать';

  @override
  String get auto_nazad_1 => 'НАЗАД';

  @override
  String get auto_oshibkaServera => 'Ошибка сервера';

  @override
  String get auto_oshibkaSeti => 'Ошибка сети';

  @override
  String get auto_zabyliParol_1 => 'Забыли пароль';

  @override
  String get auto_napishiSvoyuPochtu => 'Напиши свою почту';

  @override
  String get auto_otpravitKod => 'ОТПРАВИТЬ КОД';

  @override
  String get auto_vvedite6znachnyyKod => 'Введите 6-значный код';

  @override
  String get auto_vosstanovlenieParolya => 'Восстановление пароля';

  @override
  String get auto_kod => 'КОД';

  @override
  String get auto_prodolzhit => 'ПРОДОЛЖИТЬ';

  @override
  String get auto_zapolniteVsePolya => 'Заполните все поля';

  @override
  String get auto_parolDolzhenSoderzhatM_1 =>
      'Пароль должен содержать минимум 6 символов';

  @override
  String get auto_parolUspeshnoIzmenyon => 'Пароль успешно изменён';

  @override
  String get auto_novyyParol_1 => 'НОВЫЙ ПАРОЛЬ';

  @override
  String get auto_podtverditeParol => 'ПОДТВЕРДИТЕ ПАРОЛЬ';

  @override
  String get auto_podtverditeNovyyParol => 'Подтвердите новый пароль';

  @override
  String get auto_emailPodtverzhdyonTeper =>
      'Email подтверждён. Теперь можно войти.';

  @override
  String get auto_oshibkaSetiPriPodtverz => 'Ошибка сети при подтверждении';

  @override
  String get auto_oshibkaSetiPriPovtorno =>
      'Ошибка сети при повторной отправке';

  @override
  String get auto_verifikatsiya => 'Верификация';

  @override
  String get auto_slishkomKorotkoe => 'Слишком короткое';

  @override
  String get auto_vvediteTelefon => 'Введите телефон';

  @override
  String get auto_nuzhno11Tsifr => 'Нужно 11 цифр';

  @override
  String get auto_dolzhenNachinatsyaS7 => 'Должен начинаться с 7';

  @override
  String get auto_neUdalosSozdatModerato => 'Не удалось создать модератора';

  @override
  String get auto_imya_1 => 'Имя';

  @override
  String get auto_telefon => 'Телефон';

  @override
  String get auto_pokazat => 'Показать';

  @override
  String get auto_skryt => 'Скрыть';

  @override
  String get auto_neUdalosZagruzitTovary => 'Не удалось загрузить товары';

  @override
  String get auto_odobreno => 'Одобрено';

  @override
  String get auto_otkloneno => 'Отклонено';

  @override
  String get auto_naModeratsii => 'На модерации';

  @override
  String get auto_odobritTovar => 'Одобрить товар';

  @override
  String get auto_otklonitTovar => 'Отклонить товар';

  @override
  String get auto_tovarOdobren => 'Товар одобрен';

  @override
  String get auto_tovarOtklonen => 'Товар отклонен';

  @override
  String get auto_oshibkaPriObnovleniiSt => 'Ошибка при обновлении статуса';

  @override
  String get auto_neUdalosOpredelitModer => 'Не удалось определить модератора';

  @override
  String get auto_udalitTovarZaNarusheni => 'Удалить товар за нарушение';

  @override
  String get auto_prichinaUdaleniyaDlyaP => 'Причина удаления для поставщика';

  @override
  String get auto_tovarUdalenPostavshchik =>
      'Товар удален, поставщик уведомлен';

  @override
  String get auto_tovarUdalen => 'Товар удален';

  @override
  String get auto_neUdalosUdalitTovar => 'Не удалось удалить товар';

  @override
  String get auto_prichinaOtkloneniya => 'Причина отклонения';

  @override
  String get auto_kommentariy => 'Комментарий';

  @override
  String get auto_bezKategorii => 'Без категории';

  @override
  String get auto_naProverke => 'На проверке';

  @override
  String get auto_poiskTovarPostavshchik =>
      'Поиск: товар, поставщик, категория';

  @override
  String get auto_netZayavok => 'Нет заявок';

  @override
  String get auto_poVashemuZaprosuNicheg =>
      'По вашему запросу ничего не найдено';

  @override
  String get auto_netPodhodyashchihTovaro => 'Нет подходящих товаров';

  @override
  String get auto_partiya => 'Партия';

  @override
  String get auto_udalitZaNarushenie => 'Удалить за нарушение';

  @override
  String get auto_otklonit => 'Отклонить';

  @override
  String get auto_neAvtorizovan => 'не авторизован';

  @override
  String get auto_dostup => 'доступ';

  @override
  String get auto_neUdalosZagruzitModera => 'Не удалось загрузить модераторов';

  @override
  String get auto_moderatorDobavlen => 'Модератор добавлен';

  @override
  String get auto_moderatorUdalyon => 'Модератор удалён';

  @override
  String get auto_dobavitModeratora => 'Добавить модератора';

  @override
  String get auto_dobavit => 'Добавить';

  @override
  String get auto_poiskPoImeniIliEmail => 'Поиск по имени или email';

  @override
  String get auto_moderatoryNeNaydeny => 'Модераторы не найдены';

  @override
  String get auto_nichegoNeNaydenoPoZap => 'Ничего не найдено по запросу';

  @override
  String get auto_dostupZapreshchyonVoydi => 'Доступ запрещён. Войдите снова.';

  @override
  String get auto_bezImeni => 'Без имени';

  @override
  String get auto_moderator => 'Модератор';

  @override
  String get auto_elPochta_1 => 'Эл. почта';

  @override
  String get auto_neUdalosZagruzitChaty =>
      'Не удалось загрузить чаты техподдержки';

  @override
  String get auto_otkryt => 'Открыт';

  @override
  String get auto_zakryt_1 => 'Закрыт';

  @override
  String get auto_otkrytye => 'Открытые';

  @override
  String get auto_istoriya => 'История';

  @override
  String get auto_zakrytyhChatovPokaNet => 'Закрытых чатов пока нет';

  @override
  String get auto_otkrytyhChatovSeychasN => 'Открытых чатов сейчас нет';

  @override
  String get auto_neUdalosZagruzitSoobsh => 'Не удалось загрузить сообщения';

  @override
  String get auto_neUdalosOpredelitSotru =>
      'Не удалось определить сотрудника техподдержки';

  @override
  String get auto_chatUzheZakryt => 'Чат уже закрыт';

  @override
  String get auto_prichinaZakrytiyaNeobya => 'Причина закрытия (необязательно)';

  @override
  String get auto_neUdalosZakrytChat => 'Не удалось закрыть чат';

  @override
  String get auto_otvetitPolzovatelyu => 'Ответить пользователю';

  @override
  String get auto_chatOtkryt => 'Чат открыт';

  @override
  String get auto_zakrytChat => 'Закрыть чат';

  @override
  String get auto_deystvieNelzyaOtmenit => 'Действие нельзя отменить.';

  @override
  String get auto_etoUdalitVseBackupkody =>
      'Это удалит все backup-коды и доверенные устройства пользователя. ';

  @override
  String get auto_deystvieDostupnoTolkoM =>
      'Действие доступно только модераторам';

  @override
  String get auto_neUdalosOtklyuchit2fa => 'Не удалось отключить 2FA';

  @override
  String get auto_otklyuchitDvuhfaktornuyu =>
      'Отключить двухфакторную аутентификацию';

  @override
  String get auto_dostav => 'достав';

  @override
  String get auto_oshibkaOperatsii => 'Ошибка операции';

  @override
  String get auto_tovarSnyatSPublikatsii => 'Товар снят с публикации.';

  @override
  String get auto_tovarSnyatSPublikatsii_1 => 'Товар снят с публикации';

  @override
  String get auto_tovarUdalyon => 'Товар удалён';

  @override
  String get auto_minPartiya => 'Мин. партия';

  @override
  String get auto_ostatok => 'Остаток';

  @override
  String get auto_pokaNetTovarov => 'Пока нет товаров';

  @override
  String get auto_dobavtePervyyTovarIOt =>
      'Добавьте первый товар и отправьте его на модерацию.';

  @override
  String get auto_dobavitTovar => 'Добавить товар';

  @override
  String get auto_ponedelnik_1 => 'Понедельник';

  @override
  String get auto_vtornik_1 => 'Вторник';

  @override
  String get auto_sreda_1 => 'Среда';

  @override
  String get auto_chetverg_1 => 'Четверг';

  @override
  String get auto_pyatnitsa_1 => 'Пятница';

  @override
  String get auto_subbota_1 => 'Суббота';

  @override
  String get auto_voskresene_1 => 'Воскресенье';

  @override
  String get auto_vt_1 => 'Вт';

  @override
  String get auto_sr_1 => 'Ср';

  @override
  String get auto_cht_1 => 'Чт';

  @override
  String get auto_pt_1 => 'Пт';

  @override
  String get auto_sb_1 => 'Сб';

  @override
  String get auto_vs_1 => 'Вс';

  @override
  String get auto_napitki => 'Напитки';

  @override
  String get auto_molochnayaProduktsiya => 'Молочная продукция';

  @override
  String get auto_ovoshchiIFrukty => 'Овощи и фрукты';

  @override
  String get auto_myasoIPtitsa => 'Мясо и птица';

  @override
  String get auto_bakaleya => 'Бакалея';

  @override
  String get auto_hlebIVypechka => 'Хлеб и выпечка';

  @override
  String get auto_zamorozka => 'Заморозка';

  @override
  String get auto_sneki => 'Снеки';

  @override
  String get auto_bytovayaHimiya => 'Бытовая химия';

  @override
  String get auto_tovaryDlyaDoma => 'Товары для дома';

  @override
  String get auto_stranaProizvoditelya => 'Страна производителя';

  @override
  String get auto_srokGodnosti => 'Срок годности';

  @override
  String get auto_vvediteNazvanieTovara => 'Введите название товара';

  @override
  String get auto_ukazhiteSrokGodnosti => 'Укажите срок годности';

  @override
  String get auto_vyberiteKategoriyuIzSp => 'Выберите категорию из списка';

  @override
  String get auto_vvediteKorrektnuyuTsenu => 'Введите корректную цену';

  @override
  String get auto_minimalnoeKolichestvoDo =>
      'Минимальное количество должно быть больше 0';

  @override
  String get auto_ukazhiteOstatokNaSklad => 'Укажите остаток на складе';

  @override
  String get auto_ostatokNeMozhetBytMen =>
      'Остаток не может быть меньше минимальной партии';

  @override
  String get auto_vvediteVremyaDostavkiV =>
      'Введите время доставки в формате ЧЧ:ММ';

  @override
  String get auto_ukazhiteGrafikDostavki => 'Укажите график доставки';

  @override
  String get auto_vvediteMinimalnyySrokD => 'Введите минимальный срок доставки';

  @override
  String get auto_maksimalnyySrokNeMozhe =>
      'Максимальный срок не может быть меньше минимального';

  @override
  String get auto_srokDostavkiSlishkomBo => 'Срок доставки слишком большой';

  @override
  String get auto_vvediteVremyaOtsechkiV =>
      'Введите время отсечки в формате ЧЧ:ММ';

  @override
  String get auto_kaloriiDolzhnyBytNeotr =>
      'Калории должны быть неотрицательным числом';

  @override
  String get auto_belkiDolzhnyBytNeotrit =>
      'Белки должны быть неотрицательным числом';

  @override
  String get auto_zhiryDolzhnyBytNeotrit =>
      'Жиры должны быть неотрицательным числом';

  @override
  String get auto_uglevodyDolzhnyBytNeot =>
      'Углеводы должны быть неотрицательным числом';

  @override
  String get auto_dobavteHotyaByOdnuFot => 'Добавьте хотя бы одну фотографию';

  @override
  String get auto_sohranitIzmeneniya => 'Сохранить изменения?';

  @override
  String get auto_sozdatTovar => 'Создать товар?';

  @override
  String get auto_izmeneniyaBudutOtpravle =>
      'Изменения будут отправлены на модерацию. Текущая версия товара останется активной до проверки.';

  @override
  String get auto_tovarBudetOtpravlenNa =>
      'Товар будет отправлен на модерацию. Покупатели увидят его после проверки.';

  @override
  String get auto_sozdat => 'Создать';

  @override
  String get auto_sozdanieTovara => 'Создание товара';

  @override
  String get auto_redaktirovanieTovara => 'Редактирование товара';

  @override
  String get auto_osnovnyeDannye => 'Основные данные';

  @override
  String get auto_zapolniteNazvanieOpisan =>
      'Заполните название, описание, страну и категорию товара.';

  @override
  String get auto_nazvanieTovara => 'Название товара';

  @override
  String get auto_naprimerKazahstan => 'Например, Казахстан';

  @override
  String get auto_naprimer12Mesyatsev => 'Например, 12 месяцев';

  @override
  String get auto_tsenaIUsloviya => 'Цена и условия';

  @override
  String get auto_minimalnyeKolichestvaI =>
      'Минимальные количества и доставка.';

  @override
  String get auto_tsenaZaEdinitsu => 'Цена за единицу (₸)';

  @override
  String get auto_naprimer1450 => 'Например, 1450';

  @override
  String get auto_minimalnoeKolichestvo => 'Минимальное количество';

  @override
  String get auto_vsegoKolichestvo => 'Всего количество';

  @override
  String get auto_naprimer120 => 'Например, 120';

  @override
  String get auto_sostavIHarakteristiki => 'Состав и характеристики';

  @override
  String get auto_neobyazatelnyeDannyeZap =>
      'Необязательные данные: заполняйте только то, что нужно.';

  @override
  String get auto_sostav => 'Состав';

  @override
  String get auto_kaloriiKkal100g => 'Калории (ккал/100г)';

  @override
  String get auto_belkiG100g => 'Белки (г/100г)';

  @override
  String get auto_zhiryG100g => 'Жиры (г/100г)';

  @override
  String get auto_uglevodyG100g => 'Углеводы (г/100г)';

  @override
  String get auto_harakteristikiTovara => 'Характеристики товара';

  @override
  String get auto_nazvanie => 'Название';

  @override
  String get auto_znachenie => 'Значение';

  @override
  String get auto_udalitHarakteristiku => 'Удалить характеристику';

  @override
  String get auto_dobavitHarakteristiku => 'Добавить характеристику';

  @override
  String get auto_fotografiiTovara => 'Фотографии товара';

  @override
  String get auto_dobavteNeskolkoFoto => 'Добавьте несколько фото';

  @override
  String get auto_ozhidaemayaDataDostavki => 'Ожидаемая дата доставки';

  @override
  String get auto_poGrafiku => 'По графику';

  @override
  String get auto_poSroku => 'По сроку';

  @override
  String get auto_pokupatelUviditOzhidaem =>
      'Покупатель увидит ожидаемую дату доставки.';

  @override
  String get auto_vyberiteDniNedeli => 'Выберите дни недели';

  @override
  String get auto_bystryyVybor => 'Быстрый выбор';

  @override
  String get auto_vremyaDostavki => 'Время доставки';

  @override
  String get auto_formatChchmm => 'Формат: ЧЧ:ММ';

  @override
  String get auto_nekorrektnoeVremya => 'Некорректное время';

  @override
  String get auto_minimumDney => 'Минимум дней';

  @override
  String get auto_maksimumDney => 'Максимум дней';

  @override
  String get auto_srokPriyomaZakazaNaSe => 'Срок приёма заказа на сегодня';

  @override
  String get auto_kategorii => 'Категории';

  @override
  String get auto_poiskKategorii => 'Поиск категории';

  @override
  String get auto_kategoriiNeNaydeny => 'Категории не найдены';

  @override
  String get auto_pokazatMenshe => 'Показать меньше';

  @override
  String get auto_foto => 'Фото';

  @override
  String get auto_kompaniya => 'Компания';

  @override
  String get auto_vyNeAvtorizovanyPozhal =>
      'Вы не авторизованы. Пожалуйста, войдите.';

  @override
  String get auto_neUdalosZagruzitStatis => 'Не удалось загрузить статистику';

  @override
  String get auto_neUdalosSformirovatAir => 'Не удалось сформировать AI-резюме';

  @override
  String get auto_statistika => 'Статистика';

  @override
  String get auto_analitikaProdazh => 'Аналитика продаж';

  @override
  String get auto_obnovit => 'Обновить';

  @override
  String get auto_vseVremya => 'Все время';

  @override
  String get auto_vybrat => 'Выбрать';

  @override
  String get auto_obshchayaVyruchka => 'Общая выручка';

  @override
  String get auto_vyruchkaZaMesyats => 'Выручка за месяц';

  @override
  String get auto_zaNedelyu => 'За неделю';

  @override
  String get auto_vsegoZakazov => 'Всего заказов';

  @override
  String get auto_obzor => 'Обзор';

  @override
  String get auto_sredniyChek => 'Средний чек';

  @override
  String get auto_dinamikaVyruchki => 'Динамика выручки';

  @override
  String get auto_netDannyh => 'Нет данных';

  @override
  String get auto_dostavleny => 'Доставлены';

  @override
  String get auto_otpravleny => 'Отправлены';

  @override
  String get auto_podtverzhdeny => 'Подтверждены';

  @override
  String get auto_ozhidayut => 'Ожидают';

  @override
  String get auto_otmeneny => 'Отменены';

  @override
  String get auto_statusyZakazov => 'Статусы заказов';

  @override
  String get auto_etotMesyats => 'Этот месяц';

  @override
  String get auto_proshlyyMesyats => 'Прошлый месяц';

  @override
  String get auto_srDostavka => 'Ср. доставка';

  @override
  String get auto_pokupateli => 'Покупатели';

  @override
  String get auto_vsego => 'Всего';

  @override
  String get auto_postoyannye => 'Постоянные';

  @override
  String get auto_novyeMes => 'Новые / мес.';

  @override
  String get auto_otpravlen => 'отправлен';

  @override
  String get auto_otmenyon => 'отменён';

  @override
  String get auto_ozhidaet => 'ожидает';

  @override
  String get auto_poslednieOtzyvy => 'Последние отзывы';

  @override
  String get auto_aianaliz => 'AI-анализ';

  @override
  String get auto_generiruyuAianaliz => 'Генерирую AI-анализ…';

  @override
  String get auto_obshchieHarakteristiki => 'Общие характеристики';

  @override
  String get auto_kalorii => 'Калории';

  @override
  String get auto_belki => 'Белки';

  @override
  String get auto_zhiry => 'Жиры';

  @override
  String get auto_uglevody => 'Углеводы';

  @override
  String get auto_pitanie => 'Питание';

  @override
  String get auto_zapolniteNazvanieIZnac =>
      'Заполните название и значение характеристики';

  @override
  String get auto_takayaHarakteristikaUzh =>
      'Такая характеристика уже добавлена';

  @override
  String get auto_tolkoChto => 'только что';

  @override
  String get auto_minutu => 'минуту';

  @override
  String get auto_minuty => 'минуты';

  @override
  String get auto_minut => 'минут';

  @override
  String get auto_chas => 'час';

  @override
  String get auto_chasa => 'часа';

  @override
  String get auto_chasov => 'часов';

  @override
  String get auto_den => 'день';

  @override
  String get auto_dnya => 'дня';

  @override
  String get auto_dney => 'дней';

  @override
  String get auto_segodnya => 'Сегодня';

  @override
  String get auto_zavtra => 'Завтра';

  @override
  String get auto_segodnya_1 => 'сегодня';

  @override
  String get auto_zavtra_1 => 'завтра';

  @override
  String get auto_dostavka_1 => 'Доставка';

  @override
  String get auto_dostavkaSegodnya => 'Доставка сегодня';

  @override
  String get auto_dostavkaZavtra => 'Доставка завтра';

  @override
  String get auto_ezhednevno_1 => 'Ежедневно';

  @override
  String get auto_budni_1 => 'Будни';

  @override
  String get auto_vyhodnye_1 => 'Выходные';

  @override
  String get auto_yanvarya => 'января';

  @override
  String get auto_fevralya => 'февраля';

  @override
  String get auto_marta => 'марта';

  @override
  String get auto_aprelya => 'апреля';

  @override
  String get auto_maya => 'мая';

  @override
  String get auto_iyunya => 'июня';

  @override
  String get auto_iyulya => 'июля';

  @override
  String get auto_avgusta => 'августа';

  @override
  String get auto_sentyabrya => 'сентября';

  @override
  String get auto_oktyabrya => 'октября';

  @override
  String get auto_noyabrya => 'ноября';

  @override
  String get auto_dekabrya => 'декабря';

  @override
  String get auto_may2026 => 'май 2026';

  @override
  String get auto_may => 'май';

  @override
  String get auto_may2026_1 => 'Май 2026';

  @override
  String get auto_yanv2026 => 'янв 2026';

  @override
  String get auto_yanv => 'янв.';

  @override
  String get auto_yanv_1 => 'янв';

  @override
  String get auto_yanv_2 => 'Янв';

  @override
  String get auto_yanv_3 => 'ЯНВ';

  @override
  String get auto_may2026_2 => 'май  2026';

  @override
  String get auto_may_1 => 'Май';

  @override
  String get auto_yanvar => 'январь';

  @override
  String get auto_fevral => 'февраль';

  @override
  String get auto_mart => 'март';

  @override
  String get auto_aprel => 'апрель';

  @override
  String get auto_iyun => 'июнь';

  @override
  String get auto_iyul => 'июль';

  @override
  String get auto_avgust => 'август';

  @override
  String get auto_sentyabr => 'сентябрь';

  @override
  String get auto_oktyabr => 'октябрь';

  @override
  String get auto_noyabr => 'ноябрь';

  @override
  String get auto_dekabr => 'декабрь';

  @override
  String get auto_fev => 'фев';

  @override
  String get auto_mar => 'мар';

  @override
  String get auto_apr => 'апр';

  @override
  String get auto_iyun_1 => 'июн';

  @override
  String get auto_iyul_1 => 'июл';

  @override
  String get auto_avg => 'авг';

  @override
  String get auto_sen => 'сен';

  @override
  String get auto_okt => 'окт';

  @override
  String get auto_noya => 'ноя';

  @override
  String get auto_dek => 'дек';

  @override
  String get auto_fev_1 => 'фев.';

  @override
  String get auto_mar_1 => 'мар.';

  @override
  String get auto_apr_1 => 'апр.';

  @override
  String get auto_may_2 => 'май.';

  @override
  String get auto_iyun_2 => 'июн.';

  @override
  String get auto_iyul_2 => 'июл.';

  @override
  String get auto_avg_1 => 'авг.';

  @override
  String get auto_sen_1 => 'сен.';

  @override
  String get auto_okt_1 => 'окт.';

  @override
  String get auto_noya_1 => 'ноя.';

  @override
  String get auto_dek_1 => 'дек.';

  @override
  String get auto_yanv_4 => 'Янв.';

  @override
  String get auto_otzyv_1 => 'отзыв';

  @override
  String get auto_otzyva => 'отзыва';

  @override
  String get auto_otzyvov => 'отзывов';

  @override
  String get auto_yo => 'ё';

  @override
  String get auto_e => 'е';

  @override
  String get auto_a => 'а';

  @override
  String get auto_b => 'б';

  @override
  String get auto_v => 'в';

  @override
  String get auto_g => 'г';

  @override
  String get auto_d => 'д';

  @override
  String get auto_zh => 'ж';

  @override
  String get auto_z => 'з';

  @override
  String get auto_i => 'и';

  @override
  String get auto_y => 'й';

  @override
  String get auto_k => 'к';

  @override
  String get auto_l => 'л';

  @override
  String get auto_m => 'м';

  @override
  String get auto_n => 'н';

  @override
  String get auto_o => 'о';

  @override
  String get auto_p => 'п';

  @override
  String get auto_r => 'р';

  @override
  String get auto_s => 'с';

  @override
  String get auto_t => 'т';

  @override
  String get auto_u => 'у';

  @override
  String get auto_f => 'ф';

  @override
  String get auto_h => 'х';

  @override
  String get auto_ts => 'ц';

  @override
  String get auto_ch => 'ч';

  @override
  String get auto_sh => 'ш';

  @override
  String get auto_shch => 'щ';

  @override
  String get auto_y_1 => 'ы';

  @override
  String get auto_e_1 => 'э';

  @override
  String get auto_yu => 'ю';

  @override
  String get auto_ya => 'я';

  @override
  String get auto_ks => 'кс';

  @override
  String get auto_dzh => 'дж';

  @override
  String get auto_optovyeZakupki => 'Оптовые закупки';

  @override
  String get auto_takzheMozhnoUkazatNov =>
      'Также можно указать новый адрес при оформлении заказа.';

  @override
  String get auto_vPrilozheniiPoElektro =>
      'в приложении, по электронной почте или по телефону горячей линии.';

  @override
  String get auto_oshibkaKonfiguratsiiApi => 'Ошибка конфигурации API';

  @override
  String get auto_tyAianalitikPostavshchi =>
      'Ты AI-аналитик поставщиков. ОБЯЗАТЕЛЬНО отвечай ТОЛЬКО на русском языке. ';

  @override
  String get auto_vseTvoiOtvetyDolzhnyB =>
      'Все твои ответы должны быть на 100% на русском. ';

  @override
  String get auto_nikogdaNeIspolzuyDrugi =>
      'Никогда не используй другие языки ни при каких обстоятельствах.';

  @override
  String get auto_zaprosZanyalSlishkomDo => 'Запрос занял слишком долго';

  @override
  String get auto_provertePodklyuchenieK => 'Проверьте подключение к интернету';

  @override
  String get auto_oshibkaServeraPoprobuem =>
      'Ошибка сервера. Попробуем другую модель';

  @override
  String get auto_oshibkaAiServisa => 'Ошибка AI сервиса';

  @override
  String get auto_oshibkaPriObrabotkeOtv => 'Ошибка при обработке ответа';

  @override
  String get auto_airezyumeUspeshnoSgener => 'AI-резюме успешно сгенерировано';

  @override
  String get auto_sobiraetsya => 'Собирается';

  @override
  String get auto_spisokTovarovNeDolzhen =>
      'Список товаров не должен быть пустым';

  @override
  String get auto_useridDolzhenBytPolozh => 'userId должен быть положительным';

  @override
  String get auto_neobhodimoPeredatHotya =>
      'Необходимо передать хотя бы одно поле для обновления';

  @override
  String get auto_tekushchiyINovyyParol => 'Текущий и новый пароль обязательны';

  @override
  String get auto_podtverzhdenieParolyaNe =>
      'Подтверждение пароля не совпадает';

  @override
  String get auto_useridIAddressidDolzhn =>
      'userId и addressId должны быть положительными';

  @override
  String get auto_orderidNeDolzhenBytPu => 'orderId не должен быть пустым';

  @override
  String get auto_productidNeDolzhenByt => 'productId не должен быть пустым';

  @override
  String get auto_reviewidNeDolzhenBytP => 'reviewId не должен быть пустым';

  @override
  String get auto_statusNeDolzhenBytPus => 'status не должен быть пустым';

  @override
  String get auto_moderatoridDolzhenBytP =>
      'moderatorId должен быть положительным';

  @override
  String get auto_reasonNeDolzhenBytPus => 'reason не должен быть пустым';

  @override
  String get auto_nameNeDolzhenBytPusty => 'name не должен быть пустым';

  @override
  String get auto_idDolzhenBytPolozhitel => 'id должен быть положительным';

  @override
  String get auto_chatidDolzhenBytPolozh => 'chatId должен быть положительным';

  @override
  String get auto_textNeDolzhenBytPusty => 'text не должен быть пустым';

  @override
  String get auto_polzovatel => 'пользователь';

  @override
  String get auto_moderator_1 => 'модератор';

  @override
  String get auto_nevernyyFormatOtvetaSe =>
      'Неверный формат ответа сервера: отсутствуют поля questions или total';

  @override
  String get auto_nevernyyFormatOtvetaSe_1 =>
      'Неверный формат ответа сервера: questions должен быть списком';

  @override
  String get auto_nevernyyFormatOtvetaSe_2 =>
      'Неверный формат ответа сервера: total должен быть числом';

  @override
  String get auto_voprosNeDolzhenBytPus => 'Вопрос не должен быть пустым';

  @override
  String get auto_voprosDolzhenSoderzhat =>
      'Вопрос должен содержать минимум 10 символов';

  @override
  String get auto_neUdalosOtvetit => 'Не удалось ответить';

  @override
  String get auto_questionidNeDolzhenByt => 'questionId не должен быть пустым';

  @override
  String get auto_supplieruseridDolzhenBy =>
      'supplierUserId должен быть положительным';

  @override
  String get auto_answertextNeDolzhenByt => 'answerText не должен быть пустым';

  @override
  String get auto_responsetextNeDolzhenB =>
      'responseText не должен быть пустым';

  @override
  String get auto_vklyucheny => 'включены';

  @override
  String get auto_otklyucheny => 'отключены';

  @override
  String get auto_oooOptovayaKompaniya => 'ООО Оптовая Компания';

  @override
  String get auto_dostavkaPoRossii => 'Доставка по России';

  @override
  String get auto_postavshchikKachestvenny =>
      'Поставщик качественных товаров оптом с 10-летним опытом';

  @override
  String get auto_gMoskvaUlPrimernayaD => 'г. Москва, ул. Примерная, д. 1';

  @override
  String get auto_oooTorgovyyDom => 'ООО Торговый Дом';

  @override
  String get auto_dostavkaPoRossiiISng => 'Доставка по России и СНГ';

  @override
  String get auto_nadyozhnyyPartnyor => 'Надёжный партнёр';

  @override
  String get auto_krupnyyOptovyyPostavshc =>
      'Крупный оптовый поставщик с широким ассортиментом';

  @override
  String get auto_gSanktpeterburgPrNevsk =>
      'г. Санкт-Петербург, пр. Невский, д. 50';

  @override
  String get auto_oooEkspressPostavki => 'ООО Экспресс Поставки';

  @override
  String get auto_ekspressdostavka24Chasa => 'Экспресс-доставка 24 часа';

  @override
  String get auto_spetsializiruemsyaNaBys =>
      'Специализируемся на быстрой доставке товаров оптом';

  @override
  String get auto_gEkaterinburgUlGlavnay =>
      'г. Екатеринбург, ул. Главная, д. 100';

  @override
  String get auto_standartnayaDostavka => 'Стандартная доставка';

  @override
  String get auto_nadyozhnyyPostavshchikO =>
      'Надёжный поставщик оптовых товаров';

  @override
  String get auto_rossiya => 'Россия';

  @override
  String get auto_tovar1OtPostavshchika => 'Товар 1 от поставщика 123';

  @override
  String get auto_kategoriya1 => 'Категория 1';

  @override
  String get auto_tovar2OtPostavshchika => 'Товар 2 от поставщика 123';

  @override
  String get auto_kategoriya2 => 'Категория 2';

  @override
  String get auto_tovar1OtPostavshchika_1 => 'Товар 1 от поставщика 456';

  @override
  String get auto_tovar1OtPostavshchika_2 => 'Товар 1 от поставщика 789';

  @override
  String get auto_tovar2OtPostavshchika_1 => 'Товар 2 от поставщика 789';

  @override
  String get auto_supplieridNeDolzhenByt => 'supplierId не должен быть пустым';

  @override
  String get auto_vremyaOzhidaniyaIsteklo_1 => 'Время ожидания истекло';

  @override
  String get auto_taymaut => 'Таймаут';

  @override
  String get auto_otpravleno => 'отправлено';

  @override
  String get auto_vPuti_1 => 'В пути';

  @override
  String get auto_prinyat_1 => 'Принят';

  @override
  String get auto_otmena_1 => 'отмена';

  @override
  String get auto_otmenen => 'отменен';

  @override
  String get auto_dostavlen_1 => 'Доставлен';

  @override
  String get auto_poluchil => 'Получил';

  @override
  String get auto_neAvtorizovan_1 => 'Не авторизован';

  @override
  String get auto_serverVernulNekorrektny => 'Сервер вернул некорректный ответ';

  @override
  String get auto_offsetNeDolzhenBytOtr =>
      'offset не должен быть отрицательным';

  @override
  String get auto_limitDolzhenBytPolozhi => 'limit должен быть положительным';

  @override
  String get auto_targetuseridDolzhenByt =>
      'targetUserId должен быть положительным';

  @override
  String get auto_apiproductresolverNeUda =>
      'ApiProductResolver: не удалось загрузить каталог';

  @override
  String get auto_serverVernulPustyeDann =>
      'Сервер вернул пустые данные пользователя';

  @override
  String get auto_nevernyyKodIliIstyokS =>
      'Неверный код или истёк срок действия';

  @override
  String get auto_deystvieNedostupnoDlya =>
      'Действие недоступно для вашей роли';

  @override
  String get auto_slishkomMnogoPopytokPo =>
      'Слишком много попыток, попробуйте позже';

  @override
  String get auto_ok => 'ОК';

  @override
  String get auto_itogo5Tovarov => 'Итого: 5 товаров';

  @override
  String get auto_1Tovar => '1 товар';

  @override
  String get auto_2Tovara => '2 товара';

  @override
  String get auto_5Tovarov => '5 товаров';

  @override
  String get auto_ili => ' или ';

  @override
  String get auto_tovar_1 => 'товар';

  @override
  String get auto_tovara => 'товара';

  @override
  String get auto_tovarov => 'товаров';

  @override
  String get auto_nm => 'өнім';

  @override
  String auto_zakazSIdOrderidNeNay(Object orderId) {
    return 'Заказ с ID $orderId не найден';
  }

  @override
  String auto_vashZakazOrderidPodtve(Object orderId) {
    return 'Ваш заказ #$orderId подтверждён';
  }

  @override
  String auto_zakazOrderidDostavlen(Object orderId) {
    return 'Заказ #$orderId доставлен';
  }

  @override
  String auto_tovarSIdProductidNeN(Object productId) {
    return 'Товар с ID $productId не найден';
  }

  @override
  String get auto_oshibkaSetiProvertePod =>
      'Ошибка сети. Проверьте подключение и попробуйте снова';

  @override
  String get auto_prevyshenoVremyaOzhidan =>
      'Превышено время ожидания ответа сервера';

  @override
  String auto_oshibkaValidatsiiDetail(Object details) {
    return 'Ошибка валидации: $details';
  }

  @override
  String get auto_neUdalosRazobratSoobsh => 'Не удалось разобрать сообщение';

  @override
  String auto_neUdalosSgenerirovatOt(Object reason) {
    return 'Не удалось сгенерировать ответ AI: $reason';
  }

  @override
  String get auto_tazazayaayayoyo =>
      '([,.;:!?])[ \\t]*([A-Za-zА-Яа-яЁёҚқҒғҮүҰұІіӘәҺһҢң])';

  @override
  String get auto_i_1 => ' и ';

  @override
  String get auto_zaprosVypolnen => 'Запрос выполнен';

  @override
  String get auto_nekorrektnyyOtvetApi => 'некорректный ответ API';

  @override
  String get auto_oshibkaPrilozheniya => 'Ошибка приложения';

  @override
  String get auto_neUdalosRazobratIsklyu => 'не удалось разобрать исключение';

  @override
  String get auto_nekorrektnoeSoobshchenie =>
      'некорректное сообщение поддержки';

  @override
  String get auto_jsonNeProshyolValidats => 'JSON не прошёл валидацию';

  @override
  String get auto_neUdalosRazobratJson => 'не удалось разобрать JSON';

  @override
  String get auto_uvedomlenie => 'Уведомление';

  @override
  String get auto_nekorrektnoeUvedomlenie => 'некорректное уведомление';

  @override
  String get auto_aigeneratsiya => 'AI-генерация';

  @override
  String get auto_nekorrektnyyOtvetAi => 'некорректный ответ AI';

  @override
  String get auto_oshibkaRazboraSoobshche => 'Ошибка разбора сообщения';

  @override
  String get auto_bezZagolovka => '(без заголовка)';

  @override
  String get auto_lyubyeSimvolyVklyuchaya => '<любые символы, включая \\';

  @override
  String get auto_poleIdPustoe => 'Поле id пустое';

  @override
  String get auto_poleIdNeSootvetstvuet =>
      'Поле id не соответствует формату UUID';

  @override
  String get auto_poleBodyPustoe => 'Поле body пустое';

  @override
  String get auto_poluchen => ', получен ';

  @override
  String get auto_poleTimestampNekorrektn =>
      'Поле timestamp некорректно или не сериализуется в ISO 8601';

  @override
  String get auto_neizvestnoeZnachenieTyp => 'Неизвестное значение type';

  @override
  String get auto_neizvestnoeZnachenieSev => 'Неизвестное значение severity';

  @override
  String get auto_poleIdDolzhnoBytNepus =>
      'Поле id должно быть непустой строкой';

  @override
  String get auto_poleTypeDolzhnoBytStr => 'Поле type должно быть строкой';

  @override
  String get auto_poleSeverityDolzhnoByt => 'Поле severity должно быть строкой';

  @override
  String get auto_poleBodyDolzhnoBytStr => 'Поле body должно быть строкой';

  @override
  String get auto_poleTitleDolzhnoBytSt => 'Поле title должно быть строкой';

  @override
  String get auto_poleTimestampNeSeriali =>
      'Поле timestamp не сериализуется в ISO 8601';

  @override
  String get auto_poleTimestampNeParsits =>
      'Поле timestamp не парсится как ISO 8601';

  @override
  String get auto_poleTimestampDolzhnoBy =>
      'Поле timestamp должно быть строкой ISO 8601 или DateTime';

  @override
  String get auto_poleLanguageDolzhnoByt => 'Поле language должно быть строкой';

  @override
  String get auto_rekomenduetsyaUkazyvat =>
      ' рекомендуется указывать metadata[';

  @override
  String get auto_propustiliIzzaThrottle => 'пропустили из-за throttle';

  @override
  String get auto_voobshcheNeDoshli => 'вообще не дошли';

  @override
  String get auto_notificationserviceUseri =>
      'NotificationService: userId не задан, инициализация пропущена';

  @override
  String get auto_notificationserviceOchis =>
      'NotificationService: очистка состояния при logout';

  @override
  String get auto_optimisticHoldAktivenP =>
      'Optimistic hold активен, пропускаем перезапись счётчиков';

  @override
  String get auto_useridIzmenilsyaVoVrem =>
      'userId изменился во время refresh, отменяем обновление';

  @override
  String get auto_neUdalosObnovitSchyotc =>
      'Не удалось обновить счётчики уведомлений после всех попыток, используем кэш';

  @override
  String get auto_keshUvedomleniyUstarel =>
      'Кэш уведомлений устарел, пропускаем загрузку';

  @override
  String get auto_polzovatelRazloginilsya =>
      'Пользователь разлогинился, останавливаем polling';

  @override
  String get auto_optimisticHoldIstyokVo =>
      'Optimistic hold истёк, возобновляем polling';

  @override
  String get auto_pollingPropushchenAktiv =>
      'Polling пропущен: активен optimistic hold';

  @override
  String get auto_retrywithbackoffNeozhida =>
      '_retryWithBackoff: неожиданное завершение цикла';

  @override
  String get auto_svodkaStatistikiZakeshi => 'Сводка статистики закэширована';

  @override
  String get auto_oshibkaPriKeshirovanii => 'Ошибка при кэшировании сводки';

  @override
  String get auto_oshibkaPriPolucheniiKe => 'Ошибка при получении кэша сводки';

  @override
  String get auto_aiRezyumeZakeshirovano => 'AI резюме закэшировано';

  @override
  String get auto_oshibkaPriKeshirovanii_1 =>
      'Ошибка при кэшировании AI резюме';

  @override
  String get auto_oshibkaPriPolucheniiKe_1 =>
      'Ошибка при получении кэша AI резюме';

  @override
  String get auto_keshStatistikiOchishche => 'Кэш статистики очищен';

  @override
  String get auto_oshibkaPriOchistkeKesh => 'Ошибка при очистке кэша';

  @override
  String get auto_neUdalosVosstanovitPos =>
      'Не удалось восстановить поставщика из хранилища';

  @override
  String get auto_oshibkaZagruzkiIzbranno =>
      'Ошибка загрузки избранного из хранилища';

  @override
  String get auto_oshibkaSohraneniyaIzbra =>
      'Ошибка сохранения избранного в хранилище';

  @override
  String get auto_purchasetemplateidNevali => 'PurchaseTemplate.id невалиден';

  @override
  String get auto_purchasetemplatenameNeva => 'PurchaseTemplate.name невалиден';

  @override
  String get auto_purchasetemplatecreatedat =>
      'PurchaseTemplate.createdAt невалиден';

  @override
  String get auto_purchasetemplateupdatedat =>
      'PurchaseTemplate.updatedAt невалиден';

  @override
  String get auto_purchasetemplateitemsNev =>
      'PurchaseTemplate.items невалиден';

  @override
  String get auto_purchasetemplatecreatedat_1 =>
      'PurchaseTemplate.createdAt не ISO-8601';

  @override
  String get auto_purchasetemplateupdatedat_1 =>
      'PurchaseTemplate.updatedAt не ISO-8601';

  @override
  String get auto_templateitemNeObekt => 'TemplateItem не объект';

  @override
  String get auto_templateitemproductidNev =>
      'TemplateItem.productId невалиден';

  @override
  String get auto_templateitemsupplieridNe =>
      'TemplateItem.supplierId невалиден';

  @override
  String get auto_templateitemquantityNeva => 'TemplateItem.quantity невалиден';

  @override
  String get auto_templateitemproductnameN =>
      'TemplateItem.productName невалиден';

  @override
  String get auto_templateitemproductimageu =>
      'TemplateItem.productImageUrl невалиден';

  @override
  String get auto_templateitemsuppliername =>
      'TemplateItem.supplierName невалиден';

  @override
  String get auto_templateitempriceperunit =>
      'TemplateItem.pricePerUnit невалиден';

  @override
  String get auto_templateitemminquantityN =>
      'TemplateItem.minQuantity невалиден';

  @override
  String get auto_templateitemmaxquantityN =>
      'TemplateItem.maxQuantity невалиден';

  @override
  String get auto_imyaShablonaOt1Do50 => 'Имя шаблона: от 1 до 50 символов';

  @override
  String get auto_shablonSTakimImenemUz =>
      'Шаблон с таким именем уже существует';

  @override
  String get auto_shablonNeMozhetBytPus => 'Шаблон не может быть пустым';

  @override
  String get auto_vShabloneMozhetBytNe =>
      'В шаблоне может быть не более 100 позиций.';

  @override
  String get auto_dostignutLimitShablonov =>
      'Достигнут лимит шаблонов: 20. Удалите ненужный шаблон.';

  @override
  String get auto_nikomu => 'никому';

  @override
  String get auto_loadforcurrentuserRassog =>
      'loadForCurrentUser: рассогласование авторизации ';

  @override
  String get auto_loadforcurrentuserNeUda =>
      'loadForCurrentUser: не удалось прочитать SharedPreferences';

  @override
  String get auto_clearcacheNeUdalosOchi =>
      'clearCache: не удалось очистить SharedPreferences';

  @override
  String get auto_persistNeUdalosZapisat =>
      '_persist: не удалось записать шаблоны в SharedPreferences';

  @override
  String get auto_napitokCocacolaGazirova =>
      'Напиток Coca-Cola газированный 1.5 л';

  @override
  String get auto_cocacolaSamyyPopulyarny =>
      'Coca-Cola - самый популярный газированный напиток в мире. Имеет резкий, но приятный вкус, хорошо утоляет жажду, рекомендуется пить охлажденным.';

  @override
  String get auto_gazirovannyeNapitki => 'Газированные напитки';

  @override
  String get auto_gazirovannayaVodaSahar =>
      'Газированная вода, сахар, краситель (сахарный колер [IV]), регулятор кислотности (ортофосфорная кислота), натуральные ароматизаторы, кофеин.';

  @override
  String get auto_kazahstan => 'Казахстан';

  @override
  String get auto_torgovayaMarka => 'Торговая марка';

  @override
  String get auto_lineyka => 'Линейка';

  @override
  String get auto_klassicheskaya => 'Классическая';

  @override
  String get auto_mansa => 'Манса';

  @override
  String get auto_dostavkaMezhgorod => 'Доставка межгород';

  @override
  String get auto_chetverg1700 => 'Четверг 17:00';

  @override
  String get auto_vs21Sentyabrya => 'Вс 21 сентября';

  @override
  String get auto_sb23Sentyabrya1200 => 'Сб 23 сентября 12:00';

  @override
  String get auto_kakoytoKrutoyPostavshch => 'Какой-то крутой поставщик';

  @override
  String get auto_sb20Sentyabrya => 'Сб 20 сентября';

  @override
  String get auto_kazahskiyTenge => 'Казахский тенге';

  @override
  String get auto_rossiyskiyRubl => 'Российский рубль';

  @override
  String get auto_russkiy => 'Русский';

  @override
  String get auto_aza => 'Қазақ';

  @override
  String get auto_azasha => 'Қазақша';

  @override
  String get auto_netDostupnyhPostavshchi => 'Нет доступных поставщиков';

  @override
  String get auto_oshibkaZapuska => 'Ошибка запуска';

  @override
  String get auto_oshibkaZapuskaPrilozhen => 'Ошибка запуска приложения';

  @override
  String get auto_poprobuytePerezapustitP =>
      'Попробуйте перезапустить приложение';

  @override
  String get auto_pereezzhal => 'переезжал';
}
