import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// Кнопка подтверждения в диалогах
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get common_ok;

  /// Кнопка отмены действия
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get common_cancel;

  /// Кнопка Сохранить изменения
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get common_save;

  /// Кнопка удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get common_delete;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get common_edit;

  /// Уведомление о загрузке данных
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get common_loading;

  /// Тема ошибки
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get common_error;

  /// Уведомление об успешном выполнении
  ///
  /// In ru, this message translates to:
  /// **'Успешно'**
  String get common_success;

  /// Уведомление об отсутствии данных
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get common_no_data;

  /// Кнопка повторного действия
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте снова'**
  String get common_try_again;

  /// Кнопка повтора действия
  ///
  /// In ru, this message translates to:
  /// **'Повторение'**
  String get common_retry;

  /// Кнопка отправки данных
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get common_send;

  /// Кнопка возврата к предыдущему экрану
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get common_back;

  /// Кнопка перехода к следующему шагу
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get common_next;

  /// Кнопка закрытия диалога или экрана
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get common_close;

  /// Кнопка добавить элемент
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get common_add;

  /// Заполнитель поля поиска
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get common_search;

  /// Кнопка подтверждения действия
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get common_confirm;

  /// Сокращение единицы измерения (шт.)
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get common_unit_short;

  /// Заголовок страницы входа
  ///
  /// In ru, this message translates to:
  /// **'Вход в аккаунт'**
  String get auth_login_title;

  /// Заголовок страницы регистрации
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get auth_register_title;

  /// Ссылка для сброса пароля
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get auth_forgot_password;

  /// Заголовок страницы сброса пароля
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get auth_reset_password_title;

  /// Знак поля ввода Email
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get auth_email_label;

  /// Символ поля ввода пароля
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get auth_password_label;

  /// Имя символ поля ввода
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get auth_name_label;

  /// Совет поля ввода имени
  ///
  /// In ru, this message translates to:
  /// **'Введите свое имя'**
  String get auth_name_hint;

  /// Совет поля ввода названия компании-поставщика
  ///
  /// In ru, this message translates to:
  /// **'Например, ООО Манса склад'**
  String get auth_supplier_name_hint;

  /// Совет по вводу нового пароля
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get auth_password_hint;

  /// Подсказка поля подтверждения пароля
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите новый пароль'**
  String get auth_password_confirm_hint;

  /// Совет по текущему полю ввода пароля
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get auth_current_password_hint;

  /// Совет по повторному вводу пароля
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль еще раз'**
  String get auth_password_repeat_hint;

  /// Совет по минимальной длине пароля
  ///
  /// In ru, this message translates to:
  /// **'Не менее 6 символов'**
  String get auth_password_min_length;

  /// Кнопка выхода из аккаунта
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get auth_logout;

  /// Заголовок страницы каталога
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get catalog_title;

  /// Подсказка поля поиска в каталоге
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get catalog_search_hint;

  /// Совет по поиску категорий
  ///
  /// In ru, this message translates to:
  /// **'Поиск категорий...'**
  String get catalog_search_categories;

  /// Совет по поиску категорий
  ///
  /// In ru, this message translates to:
  /// **'Поиск подкатегорий...'**
  String get catalog_search_subcategories;

  /// Уведомление об отсутствии продуктов
  ///
  /// In ru, this message translates to:
  /// **'Товары не найдены'**
  String get catalog_no_products;

  /// Тема страницы корзины
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get cart_title;

  /// Уведомление о пустой корзине
  ///
  /// In ru, this message translates to:
  /// **'Ваша корзина пуста'**
  String get cart_empty;

  /// Тема диалога очистки корзины
  ///
  /// In ru, this message translates to:
  /// **'Нужно очистить корзину?'**
  String get cart_clear_title;

  /// Сообщение в диалоге очистки корзины
  ///
  /// In ru, this message translates to:
  /// **'Все продукты будут удалены из корзины.'**
  String get cart_clear_message;

  /// Кнопка очистки корзины
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get cart_clear_button;

  /// Тема диалога подтверждения платежа
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение оплаты'**
  String get cart_payment_confirm_title;

  /// Кнопка оплаты Заказа
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get cart_payment_button;

  /// Заголовок страницы заказов
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get order_title;

  /// Тема истории заказов
  ///
  /// In ru, this message translates to:
  /// **'История заказов'**
  String get order_history;

  /// Уведомление об отсутствии заказов
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов'**
  String get order_no_orders;

  /// Заголовок страницы сведений о продукте
  ///
  /// In ru, this message translates to:
  /// **'Детали продукта'**
  String get product_details;

  /// Тема раздела комментариев
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get product_reviews;

  /// Тема раздела вопросов
  ///
  /// In ru, this message translates to:
  /// **'Вопросы'**
  String get product_questions;

  /// Кнопка ответа на вопрос
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get product_answer_button;

  /// Совет поля ввода мнений
  ///
  /// In ru, this message translates to:
  /// **'Текст комментария'**
  String get product_review_hint;

  /// Совет поля мнений
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь впечатлениями'**
  String get product_review_share;

  /// Заголовок страницы профиля
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile_title;

  /// Тема настроек профиля
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profile_settings;

  /// Тема раздела личная информация
  ///
  /// In ru, this message translates to:
  /// **'Личная информация'**
  String get profile_personal_info;

  /// Заголовок страницы изменения пароля
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get profile_change_password;

  /// Тема раздела платежные карты
  ///
  /// In ru, this message translates to:
  /// **'Платежные карты'**
  String get profile_payment_cards;

  /// Тема раздела адреса доставки
  ///
  /// In ru, this message translates to:
  /// **'Адреса доставки'**
  String get profile_addresses;

  /// Совет поля редактирования профиля
  ///
  /// In ru, this message translates to:
  /// **'Введите новое значение'**
  String get profile_edit_field_hint;

  /// Заголовок страницы продуктов поставщика
  ///
  /// In ru, this message translates to:
  /// **'Продукты'**
  String get supplier_products;

  /// Заголовок страницы заказов поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get supplier_orders;

  /// Заголовок профиля поставщика
  ///
  /// In ru, this message translates to:
  /// **'Профиль поставщика'**
  String get supplier_profile;

  /// Кнопка Добавить продукт
  ///
  /// In ru, this message translates to:
  /// **'Добавление продукта'**
  String get supplier_add_product;

  /// Кнопка редактирования продукта
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get supplier_edit_product;

  /// Совет по поиску поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Поиск по поставщикам'**
  String get supplier_search_suppliers;

  /// Подсказка поля страны-производителя
  ///
  /// In ru, this message translates to:
  /// **'Например, Казахстан'**
  String get supplier_country_hint;

  /// Совет по срокам годности
  ///
  /// In ru, this message translates to:
  /// **'Например, 12 месяцев'**
  String get supplier_shelf_life_hint;

  /// Совет по весу продукта
  ///
  /// In ru, this message translates to:
  /// **'Например, 1450'**
  String get supplier_weight_hint;

  /// Совет по калориям
  ///
  /// In ru, this message translates to:
  /// **'Например, 120'**
  String get supplier_calories_hint;

  /// Совет по поиску категорий
  ///
  /// In ru, this message translates to:
  /// **'Поиск категории'**
  String get supplier_category_search;

  /// Кнопка Добавить Фото
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get supplier_add_photo;

  /// Знак выбора рабочих дней
  ///
  /// In ru, this message translates to:
  /// **'Будни'**
  String get supplier_schedule_weekdays;

  /// Знак выбора выходных
  ///
  /// In ru, this message translates to:
  /// **'Выходные дни'**
  String get supplier_schedule_weekend;

  /// Знак ежедневного расписания
  ///
  /// In ru, this message translates to:
  /// **'Каждый день'**
  String get supplier_schedule_daily;

  /// Тема профиля модератора
  ///
  /// In ru, this message translates to:
  /// **'Модерация'**
  String get moderator_title;

  /// Совет по поиску в умеренности
  ///
  /// In ru, this message translates to:
  /// **'Поиск: товар, поставщик, категория'**
  String get moderator_search_hint;

  /// Совет по поиску пользователей
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени или email'**
  String get moderator_search_users;

  /// Причина удаления продукта
  ///
  /// In ru, this message translates to:
  /// **'Причина удаления для поставщика'**
  String get moderator_delete_reason;

  /// Причина закрытия чата
  ///
  /// In ru, this message translates to:
  /// **'Причина закрытия (необязательно)'**
  String get moderator_close_reason;

  /// Заголовок страницы чата поддержки
  ///
  /// In ru, this message translates to:
  /// **'Поддерживающие чаты'**
  String get moderator_support_chats;

  /// Совет по выбору категории заявки
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get support_category_hint;

  /// Консультация по теме обращения
  ///
  /// In ru, this message translates to:
  /// **'Введите тему'**
  String get support_subject_hint;

  /// Тема диалога сохранения шаблона
  ///
  /// In ru, this message translates to:
  /// **'Сохранить как шаблон'**
  String get template_save_title;

  /// Кнопка перезаписи существующего шаблона
  ///
  /// In ru, this message translates to:
  /// **'Переписать'**
  String get template_overwrite;

  /// Кнопка сохранения с другим именем
  ///
  /// In ru, this message translates to:
  /// **'Сохранить под другим именем'**
  String get template_save_another;

  /// Заголовок диалога переименования шаблона
  ///
  /// In ru, this message translates to:
  /// **'Переименование шаблона'**
  String get template_rename_title;

  /// Название модели метка поля ввода
  ///
  /// In ru, this message translates to:
  /// **'Название шаблона'**
  String get template_name_label;

  /// Ошибка имени модели
  ///
  /// In ru, this message translates to:
  /// **'Название шаблона: от 1 до 50 символов'**
  String get template_name_error;

  /// Название модели дубликат
  ///
  /// In ru, this message translates to:
  /// **'Название уже занято'**
  String get template_duplicate_exists;

  /// Кнопка подтверждения использования шаблона
  ///
  /// In ru, this message translates to:
  /// **'Замена'**
  String get template_apply_confirm;

  /// Подсказка поля даты истечения срока действия карты
  ///
  /// In ru, this message translates to:
  /// **'ММ/ГГ'**
  String get payment_card_expiry_hint;

  /// Уведомление об обязательном поле
  ///
  /// In ru, this message translates to:
  /// **'Это поле обязательно'**
  String get validation_required;

  /// Сообщение о некорректности формата Email
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат Email'**
  String get validation_email_invalid;

  /// Слишком короткое сообщение пароля
  ///
  /// In ru, this message translates to:
  /// **'Пароль слишком короткий'**
  String get validation_password_short;

  /// Уведомление о несоответствии паролей
  ///
  /// In ru, this message translates to:
  /// **'Пароли несовместимы'**
  String get validation_passwords_mismatch;

  /// Сообщение об ошибке сети
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте соединение и попробуйте снова'**
  String get error_network;

  /// Сообщение об ошибке таймаута
  ///
  /// In ru, this message translates to:
  /// **'Более длительное время отклика сервера'**
  String get error_timeout;

  /// Неизвестное сообщение об ошибке
  ///
  /// In ru, this message translates to:
  /// **'Произошла неизвестная ошибка'**
  String get error_unknown;

  /// Уведомление о необходимости авторизации
  ///
  /// In ru, this message translates to:
  /// **'Требуется Авторизация'**
  String get error_auth_required;

  /// Уведомление об отсутствии запрошенного ресурса
  ///
  /// In ru, this message translates to:
  /// **'Не найден'**
  String get error_not_found;

  /// Образец уведомления о не найденном заказе
  ///
  /// In ru, this message translates to:
  /// **'ID {orderId} существующий заказ не найден'**
  String message_order_not_found(int orderId);

  /// Образец уведомления о подтверждении заказа
  ///
  /// In ru, this message translates to:
  /// **'Ваш #{orderId} заказ подтвержден'**
  String message_order_confirmed(int orderId);

  /// Образец уведомления о доставке заказа
  ///
  /// In ru, this message translates to:
  /// **'#{orderId} заказ доставлен'**
  String message_order_delivered(int orderId);

  /// Образец уведомления о незаработанном продукте
  ///
  /// In ru, this message translates to:
  /// **'ID {productId} существующий продукт не найден'**
  String message_product_not_found(String productId);

  /// Шаблон сообщения об ошибке сети
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте соединение и попробуйте снова'**
  String get message_network_error;

  /// Шаблон сообщения об ошибке таймаута
  ///
  /// In ru, this message translates to:
  /// **'Более длительное время отклика сервера'**
  String get message_timeout_error;

  /// Шаблон сообщения об ошибке подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подтверждения: {details}'**
  String message_validation_error(int details);

  /// Образец уведомления о необходимости авторизации
  ///
  /// In ru, this message translates to:
  /// **'Требуется Авторизация'**
  String get message_auth_required;

  /// Шаблон сообщения об ошибке анализа
  ///
  /// In ru, this message translates to:
  /// **'Сообщение не может быть проанализировано'**
  String get message_parse_error;

  /// Шаблон сообщения об ошибке генерации AI
  ///
  /// In ru, this message translates to:
  /// **'Невозможно построить ответ AI: {reason}'**
  String message_ai_generation_failed(int reason);

  /// Формат отображения даты и времени
  ///
  /// In ru, this message translates to:
  /// **'DD.MM.YYYY HH:mm'**
  String get format_date_pattern;

  /// Разделитель тысяч (узкий неразрывный пробел)
  ///
  /// In ru, this message translates to:
  /// **'\\u202F'**
  String get format_number_thousands_separator;

  /// Делитель дробной части
  ///
  /// In ru, this message translates to:
  /// **','**
  String get format_number_decimal_separator;

  /// Кнопка открытия текста
  ///
  /// In ru, this message translates to:
  /// **'Еще'**
  String get common_more;

  /// Кнопка для скрытия текста
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get common_less;

  /// Уведомление об окончании сеанса
  ///
  /// In ru, this message translates to:
  /// **'Сеанс завершен. Войдите снова'**
  String get auth_session_expired;

  /// Тема секции организационных продуктов
  ///
  /// In ru, this message translates to:
  /// **'Организационные продукты'**
  String get product_similar;

  /// Ошибка загрузки продуктов
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить продукты'**
  String get supplier_error_load_products;

  /// Ошибка загрузки заказов
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить заказы'**
  String get supplier_error_load_orders;

  /// Уведомление о необходимости входа
  ///
  /// In ru, this message translates to:
  /// **'Необходимо войти в аккаунт'**
  String get supplier_login_required;

  /// Уведомление о отправке продукта на модерацию
  ///
  /// In ru, this message translates to:
  /// **'Товар отправлен на модерацию'**
  String get supplier_product_sent_moderation;

  /// Уведомление о внесении изменений в модерацию
  ///
  /// In ru, this message translates to:
  /// **'Изменения направлены на модерацию'**
  String get supplier_changes_sent_moderation;

  /// Тема диалога удаления продукта
  ///
  /// In ru, this message translates to:
  /// **'Удалить продукт?'**
  String get supplier_delete_product;

  /// Наименование субъекта продукции
  ///
  /// In ru, this message translates to:
  /// **'Продукт'**
  String get supplier_product;

  /// Извещение о снятии продукции с публицистики
  ///
  /// In ru, this message translates to:
  /// **'Продукт взят из публицистики'**
  String get supplier_removed_from_publication;

  /// Уведомление об уничтожении продукта
  ///
  /// In ru, this message translates to:
  /// **'Продукт уничтожен'**
  String get supplier_product_deleted;

  /// Сообщение об ошибке удаления продукта
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить продукт'**
  String get supplier_error_delete_product;

  /// Утвержденный статус продукта
  ///
  /// In ru, this message translates to:
  /// **'Утверждено'**
  String get supplier_apprved;

  /// Статус продукта без вставки
  ///
  /// In ru, this message translates to:
  /// **'Не вставлен'**
  String get supplier_rejected;

  /// Статус продукта в умеренности
  ///
  /// In ru, this message translates to:
  /// **'В умеренности'**
  String get supplier_pending;

  /// Текст для безымянного продукта
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get supplier_no_title;

  /// Текст для продукта без описания
  ///
  /// In ru, this message translates to:
  /// **'Без описания'**
  String get supplier_no_description;

  /// Уведомление об отсутствии заказов
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов'**
  String get supplier_orders_empty_no_orders;

  /// Уведомление об отсутствии активных заказов
  ///
  /// In ru, this message translates to:
  /// **'Нет активных заказов'**
  String get supplier_orders_empty_active;

  /// Уведомление об отсутствии заказов в истории
  ///
  /// In ru, this message translates to:
  /// **'В истории нет заказов'**
  String get supplier_orders_empty_history;

  /// Уведомление об отсутствии заказов на период
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов на выбранный период'**
  String get supplier_orders_empty_period;

  /// Сообщение об ошибке изменения статуса
  ///
  /// In ru, this message translates to:
  /// **'Невозможно пройти в выбранном статусе'**
  String get supplier_status_change_step;

  /// Уведомление об обновлении статуса
  ///
  /// In ru, this message translates to:
  /// **'Обновлен статус заказа'**
  String get supplier_status_updated;

  /// Сообщение об ошибке обновления статуса
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить статус'**
  String get supplier_status_update_failed;

  /// Тема диалога изменения статуса
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение изменения статуса'**
  String get supplier_status_confirm_change;

  /// Префикс для номера заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ'**
  String get supplier_order_prefix;

  /// Предлог статуса (иске)
  ///
  /// In ru, this message translates to:
  /// **'из'**
  String get supplier_from;

  /// Предлог статуса (я)
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get supplier_to;

  /// Подпис солнечного периода
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get supplier_period_day;

  /// Подпис периода недели
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get supplier_period_week;

  /// Подпис лунного периода
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get supplier_period_month;

  /// Подпис периода девяноста
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get supplier_period_quarter;

  /// Имя вкладки "активные заказы"
  ///
  /// In ru, this message translates to:
  /// **'Активный'**
  String get supplier_active_orders_tab;

  /// Название вкладки история заказов
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get supplier_history_orders_tab;

  /// Подпис фильтра по датам
  ///
  /// In ru, this message translates to:
  /// **'Фильтр по датам'**
  String get supplier_filter_label;

  /// Кнопка экспорта в файл Excel
  ///
  /// In ru, this message translates to:
  /// **'Экспорт в файл Excel'**
  String get supplier_export_excel;

  /// Тема секции продукции на заказ
  ///
  /// In ru, this message translates to:
  /// **'Продукты на заказ'**
  String get supplier_products_in_order;

  /// Тема секции продуктов группы
  ///
  /// In ru, this message translates to:
  /// **'Популярные товары'**
  String get supplier_top_products;

  /// Тема секции конечных заказов
  ///
  /// In ru, this message translates to:
  /// **'Последние заказы'**
  String get supplier_recent_orders;

  /// Расчет вопросов без ответа
  ///
  /// In ru, this message translates to:
  /// **'Вопросов без ответа: {count}'**
  String supplier_unanswered_questions(int count);

  /// Текст кнопки Добавить в корзину
  ///
  /// In ru, this message translates to:
  /// **'Добавить в корзину'**
  String get template_add_to_cart;

  /// Быстрая доставка тег
  ///
  /// In ru, this message translates to:
  /// **'Быстрая доставка'**
  String get review_quick_fast_delivery;

  /// Хорошая ценник
  ///
  /// In ru, this message translates to:
  /// **'Хорошая цена'**
  String get review_quick_good_price;

  /// Тег качественной упаковки
  ///
  /// In ru, this message translates to:
  /// **'Качественная упаковка'**
  String get review_quick_quality_packaging;

  /// Тег продукта свежий
  ///
  /// In ru, this message translates to:
  /// **'Свежий товар'**
  String get review_quick_fresh_product;

  /// Ахсан глагол курьер фамилия
  ///
  /// In ru, this message translates to:
  /// **'Вежливый курьер'**
  String get review_quick_polite_courier;

  /// Текст пустого поля по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Без текста'**
  String get review_no_text;

  /// подписка на обязательность поля
  ///
  /// In ru, this message translates to:
  /// **'не обязательно'**
  String get wizard_optional;

  /// Совет по времени закрытия заказов
  ///
  /// In ru, this message translates to:
  /// **'Время, когда прием заказов заканчивается'**
  String get wizard_orders_cutoff_time;

  /// Сообщение об ошибке формата времени
  ///
  /// In ru, this message translates to:
  /// **'Неправильный формат времени'**
  String get wizard_invalid_time;

  /// Совет по выбору категории
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию из каталога'**
  String get wizard_select_category;

  /// Добавлена грива подписка
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get settings_enabled;

  /// Стертая грива подписка
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get settings_disabled;

  /// Название поля цены
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get price;

  /// Название страницы кладки
  ///
  /// In ru, this message translates to:
  /// **'Оформление заказа'**
  String get checkout;

  /// Статус при подготовке заказа
  ///
  /// In ru, this message translates to:
  /// **'Подготовка идет'**
  String get supplier_status_assembling;

  /// Статус в заказе
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get supplier_status_in_transit;

  /// Заказ доставлен статус
  ///
  /// In ru, this message translates to:
  /// **'Доставлено'**
  String get supplier_status_delivered;

  /// Заказ получен статус
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get supplier_status_accepted;

  /// Заказ отменён статус
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get supplier_status_cancelled;

  /// Тема прогресса заказа
  ///
  /// In ru, this message translates to:
  /// **'Прогресс заказа'**
  String get supplier_order_progress;

  /// Текущий статус о подписке
  ///
  /// In ru, this message translates to:
  /// **'Текущий статус: {status}'**
  String supplier_current_status(String status);

  /// Заказ подтвержденное уведомление
  ///
  /// In ru, this message translates to:
  /// **'Заказ подтвержден покупателем'**
  String get supplier_order_confirmed_by_buyer;

  /// Уведомление ожидания подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Ожидает подтверждения покупателем'**
  String get supplier_waiting_buyer_confirmation;

  /// Сокращение фрагмента категории
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get units_count_short;

  /// Сокращение числа позиций
  ///
  /// In ru, this message translates to:
  /// **'поз.'**
  String get items_count_short;

  /// Успешное уведомление об экспорте
  ///
  /// In ru, this message translates to:
  /// **'Файл загружен'**
  String get supplier_export_success;

  /// Уведомление об отсутствии товаров в заказе
  ///
  /// In ru, this message translates to:
  /// **'В заказе нет товаров'**
  String get supplier_order_items_empty;

  /// Сообщение об ошибке экспорта
  ///
  /// In ru, this message translates to:
  /// **'Ошибка экспорта: {error}'**
  String supplier_export_error(int error);

  /// Метка статуса ответа дан
  ///
  /// In ru, this message translates to:
  /// **'Ответ дан'**
  String get answered_label;

  /// Подпись общей суммы заказа
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get supplier_order_total_label;

  /// Подпись адреса доставки
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get supplier_delivery_address_label;

  /// Подпись статуса заказа
  ///
  /// In ru, this message translates to:
  /// **'Статус заказа'**
  String get supplier_order_status_label;

  /// Подпись товарных позиций
  ///
  /// In ru, this message translates to:
  /// **'Товарные позиции'**
  String get supplier_goods_positions_label;

  /// Подпись количества единиц
  ///
  /// In ru, this message translates to:
  /// **'Количество единиц'**
  String get supplier_units_count_label;

  /// Подпись подтверждённого статуса
  ///
  /// In ru, this message translates to:
  /// **'Подтверждено'**
  String get supplier_confirmed_label;

  /// Когда адрес не указан
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get supplier_address_not_specified;

  /// Тема страницы вопросов и ответов
  ///
  /// In ru, this message translates to:
  /// **'Вопросы и ответы'**
  String get qa_title;

  /// Название вкладки "вопросы"
  ///
  /// In ru, this message translates to:
  /// **'Вопросы'**
  String get qa_questions_tab;

  /// Название вкладки комментариев
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get qa_reviews_tab;

  /// Тема секции вопросов с ответами
  ///
  /// In ru, this message translates to:
  /// **'Вопросы, на которые уже даны ответы'**
  String get qa_questions_without_answers;

  /// Ответы на вопросы подписывайтесь
  ///
  /// In ru, this message translates to:
  /// **'Вопросы с ответами'**
  String get qa_answered_questions;

  /// Уведомление об отсутствии вопросов
  ///
  /// In ru, this message translates to:
  /// **'Нет вопросов'**
  String get qa_no_questions;

  /// Сообщение об отсутствии комментариев
  ///
  /// In ru, this message translates to:
  /// **'Нет комментариев'**
  String get qa_no_reviews;

  /// Текст пустого поля по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Без текста'**
  String get qa_no_text;

  /// Поставщик ответ подписка
  ///
  /// In ru, this message translates to:
  /// **'Ответ поставщика'**
  String get qa_seller_answer;

  /// Метка вопроса без ответа
  ///
  /// In ru, this message translates to:
  /// **'Нет ответа'**
  String get qa_without_answer;

  /// Уведомление о моменте отправки ответа
  ///
  /// In ru, this message translates to:
  /// **'Ответ отправлен успешно'**
  String get qa_answer_sent_success;

  /// Ответ уведомление о моменте обновления
  ///
  /// In ru, this message translates to:
  /// **'Ответ был успешно обновлен'**
  String get qa_answer_updated_success;

  /// Сообщение о неавторизованном пользователе
  ///
  /// In ru, this message translates to:
  /// **'Вы не авторизованы'**
  String get qa_not_authorized;

  /// Кнопка обновления подписка
  ///
  /// In ru, this message translates to:
  /// **'Обновление'**
  String get qa_refresh;

  /// Кнопка повтора подписка
  ///
  /// In ru, this message translates to:
  /// **'Повторение'**
  String get qa_retry;

  /// Кнопка открывания текста подписывайся
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get qa_expand;

  /// Кнопка скрытия текста подписка
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get qa_collapse;

  /// Кнопка ответа подписывайся
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get qa_respond;

  /// Уведомление о том, что товарные знаки не задали вопрос
  ///
  /// In ru, this message translates to:
  /// **'Товаришки еще не задавали вопросов'**
  String get qa_customers_no_questions;

  /// Сообщение о том, что товар не оставил отзыв
  ///
  /// In ru, this message translates to:
  /// **'Товаришки пока не оставили отзывов'**
  String get qa_customers_no_reviews;

  /// Когда нет ответа
  ///
  /// In ru, this message translates to:
  /// **'Нет ответа'**
  String get qa_no_answer;

  /// Сообщение об ошибке с подробностями
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {details}'**
  String qa_error_with_details(int details);

  /// Ответ уведомление об обновлении
  ///
  /// In ru, this message translates to:
  /// **'Ответ обновлен'**
  String get qa_answer_updated;

  /// Метка перед поставщиком
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get supplier_label;

  /// Неизвестное сообщение об ошибке
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ошибка'**
  String get unknown_error;

  /// Заголовок страницы комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ваши комментарии'**
  String get profile_reviews_title;

  /// Сообщение об отсутствии комментариев
  ///
  /// In ru, this message translates to:
  /// **'пока нет комментариев'**
  String get profile_reviews_empty;

  /// Тема ожидаемой секции комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ждите комментариев'**
  String get profile_reviews_pending_title;

  /// Подзаголовок секции ожидаемых отзывов
  ///
  /// In ru, this message translates to:
  /// **'Дайте оценку покупкам-это поможет другим'**
  String get profile_reviews_pending_subtitle;

  /// Кнопка Оставить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Оставить комментарий'**
  String get profile_reviews_leave_review;

  /// Расчет отзывов
  ///
  /// In ru, this message translates to:
  /// **'{count} всего'**
  String profile_reviews_total_count(int count);

  /// Тема секции комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ваши комментарии'**
  String get profile_reviews_section_title;

  /// Комментарии к разделу пустые подзаголовки
  ///
  /// In ru, this message translates to:
  /// **'Отзывы по всем покупкам'**
  String get profile_reviews_section_subtitle_empty;

  /// Расчет отзывов в подзаголовке
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String profile_reviews_section_subtitle_total(int count);

  /// Ценообразование товара подписывайся
  ///
  /// In ru, this message translates to:
  /// **'Дайте товару оценку'**
  String get profile_reviews_rate_product;

  /// Т қосу добавить записи подписка
  ///
  /// In ru, this message translates to:
  /// **'Добавить детали'**
  String get profile_reviews_add_details;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get profile_reviews_edit_button;

  /// Кнопка удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get profile_reviews_delete_button;

  /// Посылка
  ///
  /// In ru, this message translates to:
  /// **'Отправка...'**
  String get profile_reviews_sending;

  /// Кнопка сохранения
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get profile_reviews_save_button;

  /// Сообщение об успешном сохранении
  ///
  /// In ru, this message translates to:
  /// **'Комментарий обновлен'**
  String get profile_reviews_saved_success;

  /// Сообщение об ошибке сохранения
  ///
  /// In ru, this message translates to:
  /// **'Комментарий не удалось сохранить'**
  String get profile_reviews_save_error;

  /// Уведомление о необходимости авторизации
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы отредактировать отзыв'**
  String get profile_reviews_login_required;

  /// Уведомление о необходимости оценки
  ///
  /// In ru, this message translates to:
  /// **'Дайте товару оценку'**
  String get profile_reviews_rating_required;

  /// Успешное отправление сообщения
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за комментарий!'**
  String get profile_reviews_submit_success;

  /// Сообщение об ошибке отправки
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить комментарий'**
  String get profile_reviews_submit_error;

  /// Подтверждение удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить комментарий?'**
  String get profile_reviews_delete_confirm;

  /// Сообщение об успешном удалении
  ///
  /// In ru, this message translates to:
  /// **'Комментарий удален'**
  String get profile_reviews_delete_success;

  /// Сообщение об ошибке удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить комментарий не удалось'**
  String get profile_reviews_delete_error;

  /// Кнопка закрытия диалога
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get profile_reviews_close_dialog;

  /// Кнопка отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get profile_reviews_cancel_button;

  /// Кнопка переключения
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get profile_reviews_change_button;

  /// Метка заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ {orderId}'**
  String profile_reviews_order_label(int orderId);

  /// Совет поля ввода мнений
  ///
  /// In ru, this message translates to:
  /// **'Текст комментария'**
  String get profile_review_hint;

  /// Отправка
  ///
  /// In ru, this message translates to:
  /// **'Отправляется...'**
  String get review_sending;

  /// Заголовок поля комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ваше мнение'**
  String get review_your_text;

  /// Оценка товара
  ///
  /// In ru, this message translates to:
  /// **'Дайте товару оценку'**
  String get review_rate_product;

  /// Добавить детали
  ///
  /// In ru, this message translates to:
  /// **'Добавить детали'**
  String get review_add_details;

  /// Кнопка сохранения
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get review_save_button;

  /// Отправка
  ///
  /// In ru, this message translates to:
  /// **'Отправляется...'**
  String get review_sending_text;

  /// Кнопка сохранения
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get review_save_draft;

  /// Кнопка отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get review_cancel_draft;

  /// Кнопка изменения
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get review_change_draft;

  /// Совет поля мнений
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь впечатлениями'**
  String get review_share_feedback;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get review_edit_button;

  /// Кнопка удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get review_delete_button;

  /// Кнопка отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get review_cancel_button;

  /// Кнопка переключения
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get review_change_button;

  /// Кнопка Оставить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Оставить комментарий'**
  String get review_leave_button;

  /// Кнопка отправить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Отправить комментарий'**
  String get review_submit_button;

  /// Подтверждение удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить комментарий?'**
  String get review_delete_confirm;

  /// Кнопка закрытия диалога
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get review_close_dialog;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get review_edit_draft;

  /// Кнопка удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get review_delete_draft;

  /// Кнопка Оставить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Оставить комментарий'**
  String get review_leave_draft;

  /// Кнопка отправить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Отправить комментарий'**
  String get review_submit_draft;

  /// Сообщение Спасибо за комментарий
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за комментарий!'**
  String get review_thank_you;

  /// Сообщение об отсутствии комментариев
  ///
  /// In ru, this message translates to:
  /// **'пока нет комментариев'**
  String get review_no_questions_empty;

  /// Удалить кнопка подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get confirm_delete;

  /// Кнопка подтверждения отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get confirm_cancel;

  /// Предупреждение о невозможности отменить действие
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить'**
  String get cannot_be_undone;

  /// Раздел настройки внешнего вида
  ///
  /// In ru, this message translates to:
  /// **'Внешний вид'**
  String get settings_appearance;

  /// Название темной темы
  ///
  /// In ru, this message translates to:
  /// **'Темная тема'**
  String get settings_dark_mode;

  /// Описание переключателя темной темы
  ///
  /// In ru, this message translates to:
  /// **'Использование темной темы'**
  String get settings_use_dark_theme;

  /// Раздел настроек языка и региона
  ///
  /// In ru, this message translates to:
  /// **'Язык и регион'**
  String get settings_language_region;

  /// Знак выбора языка
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settings_language_label;

  /// Символ выбора валюты
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get settings_currency;

  /// Наименование валюты по коду
  ///
  /// In ru, this message translates to:
  /// **'{code}'**
  String settings_currency_name(int code);

  /// Раздел настроек безопасности
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get settings_security;

  /// Кнопка смены пароля
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get settings_change_password;

  /// Параметр двухфакторной аутентификации
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация'**
  String get settings_two_factor_auth;

  /// Раздел информации о приложении
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settings_about;

  /// Значок версии приложения
  ///
  /// In ru, this message translates to:
  /// **'Версия приложения'**
  String get settings_app_version;

  /// Навигация: Домашняя страница
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get nav_home;

  /// Навигация: статистика
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get nav_statistics;

  /// Навигация: модерация
  ///
  /// In ru, this message translates to:
  /// **'Модерация'**
  String get nav_moderation;

  /// Навигация: чаты поддержки
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get nav_chats;

  /// Навигация: список модераторов
  ///
  /// In ru, this message translates to:
  /// **'Модераторы'**
  String get nav_moderators;

  /// Подтверждение удаления продукта
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить этот продукт?'**
  String get supplier_delete_product_confirm;

  /// Заголовок профиля поставщика
  ///
  /// In ru, this message translates to:
  /// **'Профиль поставщика'**
  String get supplier_profile_title;

  /// Тема диалога переключения корзины
  ///
  /// In ru, this message translates to:
  /// **'Замена корзины'**
  String get template_replace_cart;

  /// Подтверждение замены корзины образцом
  ///
  /// In ru, this message translates to:
  /// **'Текущая корзина заменяется продуктами из шаблона. Продолжать?'**
  String get template_replace_cart_confirm;

  /// Заголовок страницы Мои заказы
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get zakazi_my_orders;

  /// Уведомление об отсутствии заказов
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов'**
  String get zakazi_no_orders;

  /// Кнопка история заказов
  ///
  /// In ru, this message translates to:
  /// **'История заказов'**
  String get zakazi_history_button;

  /// Кнопка история заказов в цифрах
  ///
  /// In ru, this message translates to:
  /// **'История заказов ({count})'**
  String zakazi_history_button_count(int count);

  /// Метка заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ {orderId}'**
  String zakazi_order_label(int orderId);

  /// Общая сумма подписывайтесь
  ///
  /// In ru, this message translates to:
  /// **'Общая сумма:'**
  String get zakazi_total_amount_label;

  /// Дата сегодня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get zakazi_today;

  /// Дата вчера
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get zakazi_yesterday;

  /// Дата завтра
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get zakazi_tomorrow;

  /// Январь месяц
  ///
  /// In ru, this message translates to:
  /// **'январь'**
  String get zakazi_month_january;

  /// Февраль месяц
  ///
  /// In ru, this message translates to:
  /// **'февраль'**
  String get zakazi_month_february;

  /// Месяц марта
  ///
  /// In ru, this message translates to:
  /// **'март'**
  String get zakazi_month_march;

  /// Апрель месяц
  ///
  /// In ru, this message translates to:
  /// **'апрель'**
  String get zakazi_month_april;

  /// Май месяц
  ///
  /// In ru, this message translates to:
  /// **'май'**
  String get zakazi_month_may;

  /// Июнь месяц
  ///
  /// In ru, this message translates to:
  /// **'июнь'**
  String get zakazi_month_june;

  /// Месяц июля
  ///
  /// In ru, this message translates to:
  /// **'июль'**
  String get zakazi_month_july;

  /// Месяц августа
  ///
  /// In ru, this message translates to:
  /// **'август'**
  String get zakazi_month_august;

  /// Сентябрь месяц
  ///
  /// In ru, this message translates to:
  /// **'сентябрь'**
  String get zakazi_month_september;

  /// Месяц октября
  ///
  /// In ru, this message translates to:
  /// **'октябрь'**
  String get zakazi_month_october;

  /// Ноябрь месяц
  ///
  /// In ru, this message translates to:
  /// **'ноябрь'**
  String get zakazi_month_november;

  /// Месяц декабря
  ///
  /// In ru, this message translates to:
  /// **'декабрь'**
  String get zakazi_month_december;

  /// Сокращение категории
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get zakazi_quantity_short;

  /// Полученный статус подпишись
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get zakazi_accepted_label;

  /// С доставкой подпишись
  ///
  /// In ru, this message translates to:
  /// **'С доставкой'**
  String get zakazi_after_delivery;

  /// Уведомление о том, что вы можете получить после доставки
  ///
  /// In ru, this message translates to:
  /// **'Можно получить после доставки'**
  String get zakazi_can_accept_after_delivery;

  /// Оставшееся время для отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена доступна ещё {time}'**
  String zakazi_cancel_available(int time);

  /// Удалить только в течение первого часа
  ///
  /// In ru, this message translates to:
  /// **'Удаление возможно только в течение первого часа'**
  String get zakazi_cancel_only_first_hour;

  /// Кнопка Выбрать все
  ///
  /// In ru, this message translates to:
  /// **'Выбор всего'**
  String get zakazi_select_all;

  /// Кнопка снять выбор
  ///
  /// In ru, this message translates to:
  /// **'Снять выбор'**
  String get zakazi_deselect_all;

  /// Процесс получения заказа
  ///
  /// In ru, this message translates to:
  /// **'Получение'**
  String get zakazi_accepting;

  /// Кнопка получения
  ///
  /// In ru, this message translates to:
  /// **'Получить'**
  String get zakazi_accept_button;

  /// Маркировка товаров перед подтверждением заказа
  ///
  /// In ru, this message translates to:
  /// **'Отметьте все товары перед подтверждением заказа.'**
  String get zakazi_mark_items_before_confirm;

  /// Тема диалога подтверждения получения
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение получения'**
  String get zakazi_confirm_acceptance;

  /// Сумма заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ {orderId} {amount}  в сумме ₸ '**
  String zakazi_order_amount(int orderId, int amount);

  /// Тема диалога удаления заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ?'**
  String get zakazi_cancel_order_title;

  /// Уведомление об отмене заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ отменяется, а товары возвращаются на склад.'**
  String get zakazi_cancel_order_message;

  /// Нет ответ
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get zakazi_no;

  /// Кнопка отмены заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get zakazi_cancel_button;

  /// Процесс отмены заказа
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get zakazi_cancelling;

  /// Уведомление о получении заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ получен.'**
  String get zakazi_order_accepted;

  /// Ошибка получения заказа
  ///
  /// In ru, this message translates to:
  /// **'Получить заказ не удалось. Повторить.'**
  String get zakazi_accept_failed;

  /// Ошибка отмены заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ не удалось. Повторить.'**
  String get zakazi_cancel_failed;

  /// Уведомление об отмене заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ отменён.'**
  String get zakazi_order_cancelled;

  /// Уведомление об удалении товара из корзины
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get cart_item_removed;

  /// Кнопка отмены удаления товара
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get cart_undo_remove;

  /// Уведомление об окончании сеанса
  ///
  /// In ru, this message translates to:
  /// **'Сеанс завершен. Войдите снова.'**
  String get zakazi_session_expired;

  /// Символ суммы в диалоге оплаты
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get cart_confirm_row_amount;

  /// Отметка количества в диалоге оплаты
  ///
  /// In ru, this message translates to:
  /// **'Шт.'**
  String get cart_confirm_row_units;

  /// Символ способа оплаты в диалоге оплаты
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get cart_confirm_row_payment;

  /// Способ оплаты наличными
  ///
  /// In ru, this message translates to:
  /// **'Наличность при получении'**
  String get cart_payment_method_cash;

  /// Способ оплаты картой
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get cart_payment_method_card;

  /// Уведомление об отсутствии подключенной карты
  ///
  /// In ru, this message translates to:
  /// **'Карта не включена'**
  String get cart_payment_method_card_none;

  /// Кнопка подтверждения способа оплаты
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение выбора'**
  String get cart_payment_confirm_choice;

  /// Баннер наличной оплаты
  ///
  /// In ru, this message translates to:
  /// **'Оплата наличными при получении'**
  String get cart_payment_banner_cash;

  /// Баннер оплаты картой без выбранной карты
  ///
  /// In ru, this message translates to:
  /// **'Оплата картой. Добавьте карту на следующем шаге.'**
  String get cart_payment_banner_card_none;

  /// Баннер оплаты реальной картой
  ///
  /// In ru, this message translates to:
  /// **'Оплата картой {brand} {number}'**
  String cart_payment_banner_card(int brand, int number);

  /// Требование авторизации для выбора платежа
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы выбрать оплату'**
  String get cart_checkout_login_required;

  /// Требование авторизации для выбора адреса
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы выбрать адрес'**
  String get cart_checkout_address_login_required;

  /// Требование авторизации для оформления заказа
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы оформить заказ'**
  String get cart_checkout_order_login_required;

  /// Ошибка загрузки адресов
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить адреса'**
  String get cart_checkout_address_load_error;

  /// Тема выбора адреса
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get cart_address_picker_title;

  /// Заголовок списка пустых адресов
  ///
  /// In ru, this message translates to:
  /// **'Адресов пока нет'**
  String get cart_address_empty_title;

  /// Совет при отсутствии адреса
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес, чтобы продолжить оформление.'**
  String get cart_address_empty_subtitle;

  /// Признак отсутствия адреса
  ///
  /// In ru, this message translates to:
  /// **'Без адреса'**
  String get cart_address_none;

  /// Ошибка сохранения адреса
  ///
  /// In ru, this message translates to:
  /// **'Адрес не удалось сохранить'**
  String get cart_checkout_save_address_error;

  /// Успешное оформление заказа по одному поставщику
  ///
  /// In ru, this message translates to:
  /// **'Заказ оформлен по поставщику'**
  String get cart_checkout_supplier_success;

  /// Успешное оформление всех заказов
  ///
  /// In ru, this message translates to:
  /// **'Все заказы успешно оформлены'**
  String get cart_checkout_all_success;

  /// Частичная успешность оформления заказов
  ///
  /// In ru, this message translates to:
  /// **'Оформлено: {success}, с ошибкой: {fail}'**
  String cart_checkout_partial_success(int success, int fail);

  /// Полный провал оформления заказов
  ///
  /// In ru, this message translates to:
  /// **'Не удалось оформить заказы'**
  String get cart_checkout_all_failed;

  /// Кнопка Сохранить корзину как шаблон
  ///
  /// In ru, this message translates to:
  /// **'Сохранить как шаблон'**
  String get cart_template_save;

  /// Заголовок списка шаблонов
  ///
  /// In ru, this message translates to:
  /// **'Образцы'**
  String get cart_template_title;

  /// Требование авторизации для использования шаблонов
  ///
  /// In ru, this message translates to:
  /// **'Чтобы использовать шаблоны, посетите'**
  String get cart_template_login_required;

  /// Ошибка использования шаблона
  ///
  /// In ru, this message translates to:
  /// **'Не удалось применить образец'**
  String get cart_template_apply_error;

  /// Когда ни одна продукция в образце не найдена в каталоге
  ///
  /// In ru, this message translates to:
  /// **'Образец не использовался: ни один продукт не доступен'**
  String get cart_template_apply_none;

  /// Успешное использование шаблона
  ///
  /// In ru, this message translates to:
  /// **'Корзина «{name}\"заменено образцом: {added} добавлен продукт'**
  String cart_template_apply_success(int name, int added);

  /// Часть успеха использования шаблона (пропущенные)
  ///
  /// In ru, this message translates to:
  /// **', {skipped} проведено'**
  String cart_template_apply_skipped(int skipped);

  /// Часть успеха использования шаблона (исправленные)
  ///
  /// In ru, this message translates to:
  /// **', {adjusted} исправлено'**
  String cart_template_apply_adjusted(int adjusted);

  /// Тема списка реализованных продуктов
  ///
  /// In ru, this message translates to:
  /// **'{count} {plural} проведено'**
  String cart_template_skipped_title(int count, int plural);

  /// Ошибка сети при оформлении заказа
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером'**
  String get cart_checkout_error_network;

  /// Ошибка проверки данных заказа
  ///
  /// In ru, this message translates to:
  /// **'Данные заказа неверны'**
  String get cart_checkout_error_data;

  /// Распространенная ошибка при оформлении заказа
  ///
  /// In ru, this message translates to:
  /// **'Не удалось оформить заказ'**
  String get cart_checkout_error_generic;

  /// Причина недоступности товара
  ///
  /// In ru, this message translates to:
  /// **'Товар недоступен'**
  String get cart_template_skip_product_missing;

  /// Причина непредставления товара поставщиком
  ///
  /// In ru, this message translates to:
  /// **'Поставщик не предлагает этот товар'**
  String get cart_template_skip_supplier_missing;

  /// Удачное переименование шаблона
  ///
  /// In ru, this message translates to:
  /// **'Модель переименована'**
  String get cart_template_rename_success;

  /// Тема диалога удаления шаблона
  ///
  /// In ru, this message translates to:
  /// **'Удаление шаблона {name}?'**
  String cart_template_delete_title(int name);

  /// Успешное удаление шаблона
  ///
  /// In ru, this message translates to:
  /// **'Образец удален'**
  String get cart_template_delete_success;

  /// Примечание о лимите позиций типа
  ///
  /// In ru, this message translates to:
  /// **'В образце должно быть не более 100 позиций.'**
  String get cart_template_limit_items;

  /// Примечание о лимите количества образцов
  ///
  /// In ru, this message translates to:
  /// **'Достиг предела образцов: 20. удалите ненужный образец.'**
  String get cart_template_limit_templates;

  /// Успешное сохранение образца
  ///
  /// In ru, this message translates to:
  /// **'Образец сохранился'**
  String get cart_template_save_success;

  /// Кнопка для оформления всех заказов
  ///
  /// In ru, this message translates to:
  /// **'Оформление всех заказов'**
  String get cart_checkout_all_orders;

  /// Тема диалога оплаты для всех заказов
  ///
  /// In ru, this message translates to:
  /// **'Все заказы'**
  String get cart_checkout_all_orders_title;

  /// Тема общей суммы заказа
  ///
  /// In ru, this message translates to:
  /// **'Общая сумма заказа'**
  String get cart_total_amount_title;

  /// Сумма количества товаров и позиций
  ///
  /// In ru, this message translates to:
  /// **'Шт.: {units} Позиция: {positions}'**
  String cart_total_summary(int units, int positions);

  /// Уведомление о дополнительных товарах в корзине
  ///
  /// In ru, this message translates to:
  /// **'еще +в корзине{count}'**
  String cart_summary_more_items(int count);

  /// Итоговая сумма по поставщику тема
  ///
  /// In ru, this message translates to:
  /// **'Комплект по поставщику'**
  String get cart_supplier_total_title;

  /// Кнопка оформления заказа по поставщику
  ///
  /// In ru, this message translates to:
  /// **'Оформление заказа'**
  String get cart_checkout_order;

  /// Информация о количестве товаров и позиций поставщика
  ///
  /// In ru, this message translates to:
  /// **'Шт.: {units} * Позиция: {positions}'**
  String cart_supplier_info(int units, int positions);

  /// Знак даты поставки товара
  ///
  /// In ru, this message translates to:
  /// **'Дата доставки: {date}'**
  String cart_delivery_date(int date);

  /// Минимальное количество заказанного товара
  ///
  /// In ru, this message translates to:
  /// **'Минимум: {count} шт.'**
  String cart_min_quantity(int count);

  /// Суффикс количества товара
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String cart_quantity_suffix(int count);

  /// Количество на кнопке оформления всего заказа
  ///
  /// In ru, this message translates to:
  /// **'· {units} шт.'**
  String cart_pay_all_details(int units);

  /// Товарная строка в наборе корзин
  ///
  /// In ru, this message translates to:
  /// **'{name} - {quantity} шт.'**
  String cart_summary_item(int name, int quantity);

  /// Имя шаблона по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'{date} шаблон даты'**
  String cart_template_default_name(int date);

  /// Кнопка просмотра деталей
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get common_more_details;

  /// Кнопка отмены действия
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get common_undo;

  /// Ссылка для очистки корзины
  ///
  /// In ru, this message translates to:
  /// **'Очистка корзины'**
  String get cart_clear_cart_link;

  /// Название вкладки "Все продукты"
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get home_all_tab;

  /// Сообщение об ошибке загрузки продуктов
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки продуктов: {error}'**
  String home_loading_error(int error);

  /// Кнопка повтора
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get home_retry_button;

  /// Заголовок пустого чата
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений'**
  String get chat_empty_title;

  /// Кнопка повтора отправки
  ///
  /// In ru, this message translates to:
  /// **'Повторить отправку'**
  String get chat_retry_send;

  /// Подпись вчера в чате
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get chat_yesterday;

  /// Имя получателя по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Получатель'**
  String get chat_buyer_default;

  /// Текст комментария по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Нет текста комментария'**
  String get chat_no_review_text;

  /// Совет в пустом чате
  ///
  /// In ru, this message translates to:
  /// **'Напишите предыдущее сообщение{postfix}'**
  String chat_empty_hint(int postfix);

  /// Подпис сегодняшнего дня в чате
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get chat_today;

  /// Уведомление об отсутствии продуктов
  ///
  /// In ru, this message translates to:
  /// **'Продукты не найдены'**
  String get home_no_products;

  /// Тема вашей домашней страницы
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home_title;

  /// Подсказка поля поиска
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get home_search_hint;

  /// Зеленая тема фильтров
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get filters_sheet_title;

  /// Кнопка сброса фильтров
  ///
  /// In ru, this message translates to:
  /// **'Восстановление'**
  String get filters_reset_button;

  /// Секция фильтра ценообразования
  ///
  /// In ru, this message translates to:
  /// **'Цена за штуку'**
  String get filter_price_title;

  /// Ценовой минимум
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get filter_price_from;

  /// Ценовой максимум
  ///
  /// In ru, this message translates to:
  /// **'до'**
  String get filter_price_to;

  /// Сортировочная секция
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get filter_sort_title;

  /// Сортировка по цене
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get filter_sort_price;

  /// Сортировка по рейтингу
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get filter_sort_rating;

  /// Секция последовательности сортировки
  ///
  /// In ru, this message translates to:
  /// **'Последовательность'**
  String get filter_order_title;

  /// От меньшего до большего
  ///
  /// In ru, this message translates to:
  /// **'Заданный'**
  String get filter_order_asc;

  /// От большего к меньшему
  ///
  /// In ru, this message translates to:
  /// **'От большего к меньшему'**
  String get filter_order_desc;

  /// Секция фильтра рейтинга
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get filter_rating_title;

  /// Рейтинг минимум
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get filter_rating_from;

  /// Кнопка отображения отфильтрованных продуктов
  ///
  /// In ru, this message translates to:
  /// **'Показать {count}'**
  String filter_show_button(int count);

  /// Фильтр товаров со скидкой
  ///
  /// In ru, this message translates to:
  /// **'Товары со скидкой'**
  String get filter_discounted;

  /// Тема диалога выбора диапазона дат
  ///
  /// In ru, this message translates to:
  /// **'Выберите диапазон дат'**
  String get date_range_picker_title;

  /// Кнопка очистки выбранного диапазона
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get date_range_picker_clear;

  /// Быстрый фильтр на сегодня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get date_range_picker_today;

  /// Быстрый фильтр на неделю
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get date_range_picker_week;

  /// Быстрый фильтр на месяц
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get date_range_picker_month;

  /// Быстрый фильтр на квартал
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get date_range_picker_quarter;

  /// Когда диапазон дат не выбран
  ///
  /// In ru, this message translates to:
  /// **'Выберите диапазон дат'**
  String get select_date_range;

  /// Месяц января
  ///
  /// In ru, this message translates to:
  /// **'январь'**
  String get month_january;

  /// Месяц февраля
  ///
  /// In ru, this message translates to:
  /// **'февраль'**
  String get month_february;

  /// Месяц марта
  ///
  /// In ru, this message translates to:
  /// **'март'**
  String get month_march;

  /// Месяц апреля
  ///
  /// In ru, this message translates to:
  /// **'апрель'**
  String get month_april;

  /// Месяц мая
  ///
  /// In ru, this message translates to:
  /// **'май'**
  String get month_may;

  /// Месяц июня
  ///
  /// In ru, this message translates to:
  /// **'июнь'**
  String get month_june;

  /// Месяц июля
  ///
  /// In ru, this message translates to:
  /// **'июль'**
  String get month_july;

  /// Месяц августа
  ///
  /// In ru, this message translates to:
  /// **'август'**
  String get month_august;

  /// Месяц сентября
  ///
  /// In ru, this message translates to:
  /// **'сентябрь'**
  String get month_september;

  /// Месяц октября
  ///
  /// In ru, this message translates to:
  /// **'октябрь'**
  String get month_october;

  /// Месяц ноября
  ///
  /// In ru, this message translates to:
  /// **'ноябрь'**
  String get month_november;

  /// Месяц декабря
  ///
  /// In ru, this message translates to:
  /// **'декабрь'**
  String get month_december;

  /// Тема списка шаблонов покупок
  ///
  /// In ru, this message translates to:
  /// **'Шаблоны покупок'**
  String get templates_sheet_title;

  /// Уведомление об отсутствии шаблонов
  ///
  /// In ru, this message translates to:
  /// **'Нет сохраненных шаблонов'**
  String get templates_sheet_no_templates;

  /// Свернуть шаблоны
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get templates_sheet_collapse;

  /// Развернуть шаблоны
  ///
  /// In ru, this message translates to:
  /// **'Развернуть'**
  String get templates_sheet_expand;

  /// Меню действий шаблона
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get templates_sheet_actions;

  /// Действие переименования в меню
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get templates_sheet_rename;

  /// Действие удаления в меню
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get templates_sheet_delete;

  /// Кнопка добавить шаблон в корзину
  ///
  /// In ru, this message translates to:
  /// **'Добавить в корзину'**
  String get templates_sheet_add_to_cart;

  /// Сокращение позиции
  ///
  /// In ru, this message translates to:
  /// **'поз.'**
  String get templates_sheet_position_short;

  /// Сокращение единицы
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get templates_sheet_unit_short;

  /// Скрыть шаблоны
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get templates_sheet_hide;

  /// Количество товаров
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String product_card_quantity(int count);

  /// Уведомление об избрании
  ///
  /// In ru, this message translates to:
  /// **'Выбрано'**
  String get product_card_added_to_favorites;

  /// Уведомление об удалении
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get product_card_removed_from_favorites;

  /// Добавить сообщение в корзину
  ///
  /// In ru, this message translates to:
  /// **'Добавить в корзину'**
  String get product_card_add_to_cart;

  /// Сообщение об отсутствии в складе
  ///
  /// In ru, this message translates to:
  /// **'В складе нет'**
  String get product_card_out_of_stock;

  /// Тема диалога кол-во
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get product_card_quantity_title;

  /// Минимальное количество
  ///
  /// In ru, this message translates to:
  /// **'Минимум'**
  String get product_card_min_quantity;

  /// Доставка каждый день
  ///
  /// In ru, this message translates to:
  /// **'Каждый день'**
  String get product_card_everyday;

  /// Доставка в будние дни
  ///
  /// In ru, this message translates to:
  /// **'Будни'**
  String get product_card_weekdays;

  /// Доставка по выходным
  ///
  /// In ru, this message translates to:
  /// **'Выходные дни'**
  String get product_card_weekend;

  /// Выбранный символ поставщика
  ///
  /// In ru, this message translates to:
  /// **'Выбрано'**
  String get supplier_selected;

  /// Кнопка выбора поставщика
  ///
  /// In ru, this message translates to:
  /// **'Выбор'**
  String get supplier_select;

  /// Сокращение единицы измерения
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get supplier_unit_short;

  /// Доставка текст по умолчан
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get supplier_delivery_default;

  /// Понедельник имя
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get weekday_monday;

  /// Вторник имя
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get weekday_tuesday;

  /// Среда имя
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get weekday_wednesday;

  /// Имя страницы
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get weekday_thursday;

  /// Имя Жума
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get weekday_friday;

  /// Название субботы
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get weekday_saturday;

  /// Воскресенье имя
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get weekday_sunday;

  /// Сокращенный понедельник
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekday_mon_short;

  /// Сокращенный вторник
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekday_tue_short;

  /// Сокращенная среда
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekday_wed_short;

  /// Сокращенный четверг
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekday_thu_short;

  /// Сокращенная пятница
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekday_fri_short;

  /// Сокращенная суббота
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekday_sat_short;

  /// Воскресенье сокращено
  ///
  /// In ru, this message translates to:
  /// **'ВС'**
  String get weekday_sun_short;

  /// Заголовок успешного белого сообщения об изменении пароля
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменен'**
  String get change_password_success_title;

  /// Успешное белое сообщение об изменении пароля
  ///
  /// In ru, this message translates to:
  /// **'Ваш пароль был успешно обновлен.'**
  String get change_password_success_message;

  /// Кнопка подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get change_password_done_button;

  /// Уведомление об отсутствии товаров
  ///
  /// In ru, this message translates to:
  /// **'Список товаров пуст'**
  String get order_history_empty;

  /// Вкладка товары в выбранном
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get favorites_tab_products;

  /// Выбран в компании вкладка
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get favorites_tab_companies;

  /// Тема чата техподдержки
  ///
  /// In ru, this message translates to:
  /// **'Чат техподдержки'**
  String get support_chat_title;

  /// Кнопка сброса
  ///
  /// In ru, this message translates to:
  /// **'Восстановление'**
  String get supplier_reset_button;

  /// Кнопка редактирования товара
  ///
  /// In ru, this message translates to:
  /// **'Править'**
  String get supplier_products_edit;

  /// Кнопка добавить товар
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар'**
  String get supplier_products_add;

  /// Заголовок диалога удаления карты
  ///
  /// In ru, this message translates to:
  /// **'Удалить карту?'**
  String get payment_card_delete_title;

  /// Кнопка удаления карты
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get payment_card_delete_button;

  /// Кнопка Добавить адрес
  ///
  /// In ru, this message translates to:
  /// **'Добавить адрес'**
  String get address_add_button;

  /// Кнопка крепления
  ///
  /// In ru, this message translates to:
  /// **'Утверждение'**
  String get moderation_approve_button;

  /// Тема диалога отключения 2FA
  ///
  /// In ru, this message translates to:
  /// **'Отключить 2FA?'**
  String get two_factor_disable_title;

  /// Кнопка отключения 2FA
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get two_factor_disable_button;

  /// Заголовок страницы управления модераторами
  ///
  /// In ru, this message translates to:
  /// **'Управление модераторами'**
  String get moderator_management_title;

  /// Тема диалога удаления модератора
  ///
  /// In ru, this message translates to:
  /// **'Удалить модератора?'**
  String get moderator_delete_title;

  /// Кнопка Добавить модератора
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get moderator_add_button;

  /// Кнопка входа
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get moderator_login_button;

  /// Кнопка копирования всех кодов
  ///
  /// In ru, this message translates to:
  /// **'Копировать все'**
  String get two_factor_copy_all;

  /// Кнопка Сохранить коды в файл
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в файл'**
  String get two_factor_save_file;

  /// Тема диалога добавления модератора
  ///
  /// In ru, this message translates to:
  /// **'Добавить модератора'**
  String get add_moderator_title;

  /// Кнопка сброса фильтров
  ///
  /// In ru, this message translates to:
  /// **'Восстановление'**
  String get supplier_profile_reset;

  /// Превью показать кнопка
  ///
  /// In ru, this message translates to:
  /// **'Показать {count}'**
  String supplier_profile_preview_show(int count);

  /// Тема диалога создания чата
  ///
  /// In ru, this message translates to:
  /// **'Создать Чат?'**
  String get create_chat_title;

  /// Тема диалога закрытия чата
  ///
  /// In ru, this message translates to:
  /// **'Закрыть чат'**
  String get close_chat_title;

  /// Заголовок списка поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Поставщики'**
  String get suppliers_list_title;

  /// Кнопка Задать вопрос
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get question_ask_button;

  /// Нет кнопка
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no_button;

  /// Тема диалога удаления заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ?'**
  String get cancel_order_title;

  /// Уведомление об отмене заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ отменяется, а товары возвращаются на склад.'**
  String get cancel_order_message;

  /// Кнопка отмены заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get cancel_order_button;

  /// Кнопка получения заказа
  ///
  /// In ru, this message translates to:
  /// **'Получить'**
  String get accept_order_button;

  /// Уведомление об отсутствии поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Поставщики не найдены'**
  String get suppliers_not_found;

  /// Кнопка закрытия чата
  ///
  /// In ru, this message translates to:
  /// **'Закрытие'**
  String get close_chat_button;

  /// Кнопка обновления чата
  ///
  /// In ru, this message translates to:
  /// **'Обновление'**
  String get create_chat_confirm;

  /// Тема профиля модератора
  ///
  /// In ru, this message translates to:
  /// **'Профиль модератора'**
  String get moderator_title_profile;

  /// Сообщение об ошибке загрузки поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить поставщиков'**
  String get suppliers_load_failed;

  /// Уведомление о необходимости повторного входа
  ///
  /// In ru, this message translates to:
  /// **'Сеанс завершен, войдите снова'**
  String get session_expired_login_again;

  /// Сообщение об ошибке открытия чата
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат с поставщиком'**
  String get chat_open_failed;

  /// Сообщение об ошибке чата
  ///
  /// In ru, this message translates to:
  /// **'Не удалось пообщаться с поставщиком'**
  String get chat_create_failed;

  /// Сообщение об отсутствии результатов поиска
  ///
  /// In ru, this message translates to:
  /// **'Запрос не был предоставлен без четверостишия'**
  String get search_no_results;

  /// Нет результатов поиска для запроса
  ///
  /// In ru, this message translates to:
  /// **'К запросам «{query}\"без саответа не дано'**
  String search_no_results_for(int query);

  /// No description provided for @suppliers_catalog_access_denied.
  ///
  /// In ru, this message translates to:
  /// **'Каталог поставщиков доступен только модераторам и основным администраторам.'**
  String get suppliers_catalog_access_denied;

  /// Title for nutritional info
  ///
  /// In ru, this message translates to:
  /// **'Пищевая ценность'**
  String get product_nutritional_info;

  /// Subtitle for nutritional info
  ///
  /// In ru, this message translates to:
  /// **'В 100 граммах:'**
  String get product_per_100g;

  /// Calories label
  ///
  /// In ru, this message translates to:
  /// **'Калории'**
  String get product_calories;

  /// Proteins label
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get product_proteins;

  /// Fats label
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get product_fats;

  /// Carbs label
  ///
  /// In ru, this message translates to:
  /// **'Углеводы'**
  String get product_carbohydrates;

  /// Short for kilocalories
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get unit_kcal_short;

  /// Short for grams
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get unit_g_short;

  /// Prefix for supplier answer
  ///
  /// In ru, this message translates to:
  /// **'Ответ от {name}'**
  String product_qa_answer_from(String name);

  /// Button to edit answer
  ///
  /// In ru, this message translates to:
  /// **'Изменить ответ'**
  String get qa_edit_answer;

  /// Toast message for cart
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в корзину: {name} -{qty} шт.'**
  String product_added_to_cart_msg(String name, int qty);

  /// Toast message for favorites
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get product_added_to_favorites;

  /// Short for buyer initial
  ///
  /// In ru, this message translates to:
  /// **'П'**
  String get rating_buyers_short;

  /// Rating count with parentheses
  ///
  /// In ru, this message translates to:
  /// **'Оценок ({count})'**
  String rating_count_format(int count);

  /// Read all reviews button
  ///
  /// In ru, this message translates to:
  /// **'Читать все'**
  String get rating_read_all;

  /// Rating count with colon
  ///
  /// In ru, this message translates to:
  /// **'Оценок: {count}'**
  String rating_count_label(int count);

  /// Empty state for reviews
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов. Станьте первым, кто оценит товар.'**
  String get rating_no_reviews;

  /// Default reviewer name
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get rating_buyer;

  /// Fallback text for empty review
  ///
  /// In ru, this message translates to:
  /// **'Без текста отзыва'**
  String get rating_no_review_text;

  /// Genitive case of supplier
  ///
  /// In ru, this message translates to:
  /// **'поставщика'**
  String get qa_supplier_genitive;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get auto_nazad;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get auto_podtverdit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get auto_postavshchik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get auto_pokupatel;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get auto_voyti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПОЧТА'**
  String get auto_pochta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПАРОЛЬ'**
  String get auto_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ВОЙТИ'**
  String get auto_voyti_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрируйтесь'**
  String get auto_zaregistriruytes;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'тронуто'**
  String get auto_tronuto;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'РОЛЬ'**
  String get auto_rol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ИМЯ'**
  String get auto_imya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'тронутое'**
  String get auto_tronutoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get auto_dannye;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get auto_parol_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ЗАРЕГИСТРИРОВАТЬСЯ'**
  String get auto_zaregistrirovatsya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ДАЛЕЕ'**
  String get auto_dalee;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get auto_registratsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НАЗАД'**
  String get auto_nazad_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'КОД'**
  String get auto_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПРОДОЛЖИТЬ'**
  String get auto_prodolzhit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Верификация'**
  String get auto_verifikatsiya;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get profile_user_fallback;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get role_buyer;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get role_supplier;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Модератор'**
  String get role_moderator;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get role_super_admin;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Мои товары'**
  String get supplier_my_products;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get supplier_my_orders;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get supplier_stats;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Модерация товаров'**
  String get mod_product_moderation;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Чаты поддержки'**
  String get mod_support_chats;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Управление модераторами'**
  String get mod_mod_management;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Чаты поддержки'**
  String get support_chats_title;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Создать чат'**
  String get create_chat_button;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Одобрить товар'**
  String get moderation_approve_product;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Отклонить товар'**
  String get moderation_reject_product;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Причина отклонения'**
  String get moderation_reject_hint;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get moderation_comment_hint;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Товар одобрен'**
  String get moderation_product_approved;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Товар отклонен'**
  String get moderation_product_rejected;

  /// Auto-added missing key
  ///
  /// In ru, this message translates to:
  /// **'Ошибка обновления'**
  String get moderation_update_error;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите почту и пароль'**
  String get auto_vvedite_pochtu_i_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сервер не вернул challenge для 2FA'**
  String get auto_server_ne_vernul_challenge_dlya_2fa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проверьте, что почта и пароль заполнены'**
  String get auto_proverte_chto_pochta_i_parol_zapoln;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверная почта или пароль'**
  String get auto_nevernaya_pochta_ili_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доступ запрещён'**
  String get auto_dostup_zapreshchen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить вход. Попробуйте позже.'**
  String get auto_ne_udalos_vypolnit_vkhod_poprobuyte;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения к серверу: \$e'**
  String get auto_oshibka_podklyucheniya_k_serveru_e;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вход выполнен'**
  String get auto_vkhod_vypolnen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать, \$name!'**
  String get auto_dobro_pozhalovat_name;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Зайдите или зарегистрируйтесь'**
  String get auto_zaydite_ili_zaregistriruytes;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'В свой аккаунт'**
  String get auto_v_svoy_akkaunt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Запомнить меня'**
  String get auto_zapomnit_menya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get auto_zabyli_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта? '**
  String get auto_net_akkaunta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите 10-символьный backup-код'**
  String get auto_vvedite_10_simvolnyy_backup_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите \$_emailOtpLength-значный код'**
  String get auto_vvedite_emailotplength_znachnyy_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get auto_nevernyy_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения к серверу'**
  String get auto_oshibka_podklyucheniya_k_serveru;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Срок действия кода истёк, повторите вход'**
  String get auto_srok_deystviya_koda_istek_povtorite;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен повторно'**
  String get auto_kod_otpravlen_povtorno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код повторно'**
  String get auto_ne_udalos_otpravit_kod_povtorno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение входа'**
  String get auto_podtverzhdenie_vkhoda;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная\\nаутентификация'**
  String get auto_dvukhfaktornaya_nautentifikatsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили код на вашу почту'**
  String get auto_my_otpravili_kod_na_vashu_pochtu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'BACKUP-КОД'**
  String get auto_backup_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'КОД ИЗ ПОЧТЫ'**
  String get auto_kod_iz_pochty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить снова'**
  String get auto_otpravit_snova;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к коду из почты'**
  String get auto_vernutsya_k_kodu_iz_pochty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Использовать backup-код'**
  String get auto_ispolzovat_backup_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Запомнить устройство на 30 дней'**
  String get auto_zapomnit_ustroystvo_na_30_dney;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get auto_vvedite_imya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Имя должно быть не короче 2 символов'**
  String get auto_imya_dolzhno_byt_ne_koroche_2_simvo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите почту'**
  String get auto_vvedite_pochtu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите корректную почту'**
  String get auto_vvedite_korrektnuyu_pochtu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get auto_vvedite_nomer_telefona;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер должен быть в формате +7-000-000-0000'**
  String get auto_nomer_dolzhen_byt_v_formate_7_000_0;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер должен начинаться с +7'**
  String get auto_nomer_dolzhen_nachinatsya_s_7;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите название компании'**
  String get auto_vvedite_nazvanie_kompanii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get auto_vvedite_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен быть не короче 6 символов'**
  String get auto_parol_dolzhen_byt_ne_koroche_6_simv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get auto_povtorite_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get auto_paroli_ne_sovpadayut;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Email уже зарегистрирован'**
  String get auto_email_uzhe_zaregistrirovan;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проверьте заполнение полей'**
  String get auto_proverte_zapolnenie_poley;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НОМЕР ТЕЛЕФОНА'**
  String get auto_nomer_telefona;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НАЗВАНИЕ КОМПАНИИ'**
  String get auto_nazvanie_kompanii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Например, ТОО Склад Манса'**
  String get auto_naprimer_too_sklad_mansa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Дополнительные данные не требуются.'**
  String get auto_dopolnitelnye_dannye_ne_trebuyutsya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПОВТОРИТЕ ПАРОЛЬ'**
  String get auto_povtorite_parol_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Компания и пароль'**
  String get auto_kompaniya_i_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из 2'**
  String auto_shag_visiblestep_1_iz_2(String step);

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Регистрация прошла успешно'**
  String get auto_registratsiya_proshla_uspeshno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сервер вернул ошибку'**
  String get auto_server_vernul_oshibku;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить регистрацию'**
  String get auto_ne_udalos_zavershit_registratsiyu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сервер вернул ошибку. Попробуйте снова.'**
  String get auto_server_vernul_oshibku_poprobuyte_sn;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения'**
  String get auto_oshibka_podklyucheniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрируйтесь чтобы начать'**
  String get auto_zaregistriruytes_chtoby_nachat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get auto_vvedite_email;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера'**
  String get auto_oshibka_servera;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get auto_oshibka_seti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль'**
  String get auto_zabyli_parol_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Напиши свою почту'**
  String get auto_napishi_svoyu_pochtu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ЭЛ. ПОЧТА'**
  String get auto_el_pochta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ОТПРАВИТЬ КОД'**
  String get auto_otpravit_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите 6-значный код'**
  String get auto_vvedite_6znachnyy_kod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Восстановление пароля'**
  String get auto_vosstanovlenie_parolya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Заполните все поля'**
  String get auto_zapolnite_vse_polya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать минимум 6 символов'**
  String get auto_parol_dolzhen_soderzhat_minimum_6_s;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароль успешно изменён'**
  String get auto_parol_uspeshno_izmenn;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get auto_novyy_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get auto_vvedite_novyy_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НОВЫЙ ПАРОЛЬ'**
  String get auto_novyy_parol_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПОДТВЕРДИТЕ ПАРОЛЬ'**
  String get auto_podtverdite_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите новый пароль'**
  String get auto_podtverdite_novyy_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ ПАРОЛЬ'**
  String get auto_sohranit_parol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Email подтверждён. Теперь можно войти.'**
  String get auto_email_podtverzhdn_teper_mozhno_voyt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети при подтверждении'**
  String get auto_oshibka_seti_pri_podtverzhdenii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети при повторной отправке'**
  String get auto_oshibka_seti_pri_povtornoy_otpravke;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка конфигурации API'**
  String get auto_oshibka_konfiguratsii_api;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать AI-резюме'**
  String get auto_ne_udalos_sformirovat_airezyume;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ты AI-аналитик поставщиков. ОБЯЗАТЕЛЬНО отвечай ТОЛЬКО на русском языке. '**
  String get auto_ty_aianalitik_postavschikov_obyazat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Все твои ответы должны быть на 100% на русском. '**
  String get auto_vse_tvoi_otvety_dolzhny_byt_na_100;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Никогда не используй другие языки ни при каких обстоятельствах.'**
  String get auto_nikogda_ne_ispolzuy_drugie_yazyki_n;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Запрос занял слишком долго'**
  String get auto_zapros_zanyal_slishkom_dolgo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету'**
  String get auto_proverte_podklyuchenie_k_internetu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера. Попробуем другую модель'**
  String get auto_oshibka_servera_poprobuem_druguyu_m;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка AI сервиса'**
  String get auto_oshibka_ai_servisa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get auto_oshibka_pri_obrabotke_otveta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'AI-резюме успешно сгенерировано'**
  String get auto_airezyume_uspeshno_sgenerirovano;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Собирается'**
  String get auto_sobiraetsya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Список товаров не должен быть пустым'**
  String get auto_spisok_tovarov_ne_dolzhen_byt_pusty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'userId должен быть положительным'**
  String get auto_userid_dolzhen_byt_polozhitelnym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Необходимо передать хотя бы одно поле для обновления'**
  String get auto_neobhodimo_peredat_hotya_by_odno_po;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Текущий и новый пароль обязательны'**
  String get auto_tekuschiy_i_novyy_parol_obyazatelny;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль должен отличаться от текущего'**
  String get auto_novyy_parol_dolzhen_otlichatsya_ot;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение пароля не совпадает'**
  String get auto_podtverzhdenie_parolya_ne_sovpadaet;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'userId и addressId должны быть положительными'**
  String get auto_userid_i_addressid_dolzhny_byt_polo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'orderId не должен быть пустым'**
  String get auto_orderid_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'productId не должен быть пустым'**
  String get auto_productid_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'reviewId не должен быть пустым'**
  String get auto_reviewid_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'status не должен быть пустым'**
  String get auto_status_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'moderatorId должен быть положительным'**
  String get auto_moderatorid_dolzhen_byt_polozhiteln;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'reason не должен быть пустым'**
  String get auto_reason_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'name не должен быть пустым'**
  String get auto_name_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'id должен быть положительным'**
  String get auto_id_dolzhen_byt_polozhitelnym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'chatId должен быть положительным'**
  String get auto_chatid_dolzhen_byt_polozhitelnym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'text не должен быть пустым'**
  String get auto_text_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'пользователь'**
  String get auto_polzovatel;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'модератор'**
  String get auto_moderator;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат ответа сервера: отсутствуют поля questions или total'**
  String get auto_nevernyy_format_otveta_servera_otsu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат ответа сервера: questions должен быть списком'**
  String get auto_nevernyy_format_otveta_servera_ques;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат ответа сервера: total должен быть числом'**
  String get auto_nevernyy_format_otveta_servera_tota;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопрос не должен быть пустым'**
  String get auto_vopros_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопрос должен содержать минимум 10 символов'**
  String get auto_vopros_dolzhen_soderzhat_minimum_10;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось ответить'**
  String get auto_ne_udalos_otvetit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'questionId не должен быть пустым'**
  String get auto_questionid_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'supplierUserId должен быть положительным'**
  String get auto_supplieruserid_dolzhen_byt_polozhit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'answerText не должен быть пустым'**
  String get auto_answertext_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'responseText не должен быть пустым'**
  String get auto_responsetext_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ООО Оптовая Компания'**
  String get auto_ooo_optovaya_kompaniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доставка по России'**
  String get auto_dostavka_po_rossii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Быстрая доставка'**
  String get auto_bystraya_dostavka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик качественных товаров оптом с 10-летним опытом'**
  String get auto_postavschik_kachestvennyh_tovarov_o;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'г. Москва, ул. Примерная, д. 1'**
  String get auto_g_moskva_ul_primernaya_d_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ООО Торговый Дом'**
  String get auto_ooo_torgovyy_dom;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доставка по России и СНГ'**
  String get auto_dostavka_po_rossii_i_sng;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Надёжный партнёр'**
  String get auto_nadzhnyy_partnr;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Крупный оптовый поставщик с широким ассортиментом'**
  String get auto_krupnyy_optovyy_postavschik_s_shiro;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'г. Санкт-Петербург, пр. Невский, д. 50'**
  String get auto_g_sanktpeterburg_pr_nevskiy_d_50;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ООО Экспресс Поставки'**
  String get auto_ooo_ekspress_postavki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Экспресс-доставка 24 часа'**
  String get auto_ekspressdostavka_24_chasa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Специализируемся на быстрой доставке товаров оптом'**
  String get auto_spetsializiruemsya_na_bystroy_dosta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'г. Екатеринбург, ул. Главная, д. 100'**
  String get auto_g_ekaterinburg_ul_glavnaya_d_100;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Стандартная доставка'**
  String get auto_standartnaya_dostavka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Надёжный поставщик оптовых товаров'**
  String get auto_nadzhnyy_postavschik_optovyh_tovaro;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Россия'**
  String get auto_rossiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар 1 от поставщика 123'**
  String get auto_tovar_1_ot_postavschika_123;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Категория 1'**
  String get auto_kategoriya_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар 2 от поставщика 123'**
  String get auto_tovar_2_ot_postavschika_123;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Категория 2'**
  String get auto_kategoriya_2;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар 1 от поставщика 456'**
  String get auto_tovar_1_ot_postavschika_456;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар 1 от поставщика 789'**
  String get auto_tovar_1_ot_postavschika_789;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар 2 от поставщика 789'**
  String get auto_tovar_2_ot_postavschika_789;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'supplierId не должен быть пустым'**
  String get auto_supplierid_ne_dolzhen_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло'**
  String get auto_vremya_ozhidaniya_isteklo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик не найден'**
  String get auto_postavschik_ne_nayden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Таймаут'**
  String get auto_taymaut;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'в пути'**
  String get auto_v_puti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отправлен'**
  String get auto_otpravlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отправлено'**
  String get auto_otpravleno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get auto_v_puti_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get auto_prinyat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'доставлен'**
  String get auto_dostavlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'получено'**
  String get auto_polucheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'принят'**
  String get auto_prinyat_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'принята'**
  String get auto_prinyata;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'принято'**
  String get auto_prinyato;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'приняты'**
  String get auto_prinyaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'завершено'**
  String get auto_zaversheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отмена'**
  String get auto_otmena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отменён'**
  String get auto_otmenn;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отменен'**
  String get auto_otmenen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доставлен'**
  String get auto_dostavlen_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Получил'**
  String get auto_poluchil;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не авторизован'**
  String get auto_ne_avtorizovan;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сервер вернул некорректный ответ'**
  String get auto_server_vernul_nekorrektnyy_otvet;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'offset не должен быть отрицательным'**
  String get auto_offset_ne_dolzhen_byt_otritsatelnym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'limit должен быть положительным'**
  String get auto_limit_dolzhen_byt_polozhitelnym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'targetUserId должен быть положительным'**
  String get auto_targetuserid_dolzhen_byt_polozhitel;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ApiProductResolver: не удалось загрузить каталог'**
  String get auto_apiproductresolver_ne_udalos_zagruz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сервер вернул пустые данные пользователя'**
  String get auto_server_vernul_pustye_dannye_polzova;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный код или истёк срок действия'**
  String get auto_nevernyy_kod_ili_istk_srok_deystviy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Требуется авторизация'**
  String get auto_trebuetsya_avtorizatsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Действие недоступно для вашей роли'**
  String get auto_deystvie_nedostupno_dlya_vashey_rol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Срок действия кода истёк, повторите вход'**
  String get auto_srok_deystviya_koda_istk_povtorite;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток, попробуйте позже'**
  String get auto_slishkom_mnogo_popytok_poprobuyte_p;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'товар'**
  String get auto_tovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'товара'**
  String get auto_tovara;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'товаров'**
  String get auto_tovarov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'өнім'**
  String get auto_nm;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте подключение и попробуйте снова'**
  String get auto_oshibka_seti_proverte_podklyuchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания ответа сервера'**
  String get auto_prevysheno_vremya_ozhidaniya_otveta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось разобрать сообщение'**
  String get auto_ne_udalos_razobrat_soobschenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Запрос выполнен'**
  String get auto_zapros_vypolnen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'некорректный ответ API'**
  String get auto_nekorrektnyy_otvet_api;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка приложения'**
  String get auto_oshibka_prilozheniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'не удалось разобрать исключение'**
  String get auto_ne_udalos_razobrat_isklyuchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'некорректное сообщение поддержки'**
  String get auto_nekorrektnoe_soobschenie_podderzhki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'JSON не прошёл валидацию'**
  String get auto_json_ne_proshl_validatsiyu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'не удалось разобрать JSON'**
  String get auto_ne_udalos_razobrat_json;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Уведомление'**
  String get auto_uvedomlenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'некорректное уведомление'**
  String get auto_nekorrektnoe_uvedomlenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'AI-генерация'**
  String get auto_aigeneratsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'некорректный ответ AI'**
  String get auto_nekorrektnyy_otvet_ai;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка разбора сообщения'**
  String get auto_oshibka_razbora_soobscheniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'(без заголовка)'**
  String get auto_bez_zagolovka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'<любые символы, включая \">'**
  String get auto_lyubye_simvoly_vklyuchaya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле id пустое'**
  String get auto_pole_id_pustoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле id не соответствует формату UUID'**
  String get auto_pole_id_ne_sootvetstvuet_formatu_uu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле body пустое'**
  String get auto_pole_body_pustoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле timestamp некорректно или не сериализуется в ISO 8601'**
  String get auto_pole_timestamp_nekorrektno_ili_ne_s;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неизвестное значение type'**
  String get auto_neizvestnoe_znachenie_type;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неизвестное значение severity'**
  String get auto_neizvestnoe_znachenie_severity;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле id должно быть непустой строкой'**
  String get auto_pole_id_dolzhno_byt_nepustoy_stroko;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле type должно быть строкой'**
  String get auto_pole_type_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле severity должно быть строкой'**
  String get auto_pole_severity_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле body должно быть строкой'**
  String get auto_pole_body_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле title должно быть строкой'**
  String get auto_pole_title_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле timestamp не сериализуется в ISO 8601'**
  String get auto_pole_timestamp_ne_serializuetsya_v;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле timestamp не парсится как ISO 8601'**
  String get auto_pole_timestamp_ne_parsitsya_kak_iso;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле timestamp должно быть строкой ISO 8601 или DateTime'**
  String get auto_pole_timestamp_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поле language должно быть строкой'**
  String get auto_pole_language_dolzhno_byt_strokoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Для типа \"error\" рекомендуется указывать поле code'**
  String get auto_dlya_tipa_error_rekomenduetsya_ukaz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Для типа \"ai_generated\" рекомендуется указывать metadata[\"model\"]'**
  String get auto_dlya_tipa_aigenerated_rekomenduetsy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'пропустили из-за throttle'**
  String get auto_propustili_izza_throttle;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'вообще не дошли'**
  String get auto_voobsche_ne_doshli;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'NotificationService: userId не задан, инициализация пропущена'**
  String get auto_notificationservice_userid_ne_zadan;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'NotificationService: очистка состояния при logout'**
  String get auto_notificationservice_ochistka_sostoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Optimistic hold активен, пропускаем перезапись счётчиков'**
  String get auto_optimistic_hold_aktiven_propuskaem;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'userId изменился во время refresh, отменяем обновление'**
  String get auto_userid_izmenilsya_vo_vremya_refresh;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить счётчики уведомлений после всех попыток, используем кэш'**
  String get auto_ne_udalos_obnovit_schtchiki_uvedoml;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Кэш уведомлений устарел, пропускаем загрузку'**
  String get auto_kesh_uvedomleniy_ustarel_propuskaem;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пользователь разлогинился, останавливаем polling'**
  String get auto_polzovatel_razloginilsya_ostanavliv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Optimistic hold истёк, возобновляем polling'**
  String get auto_optimistic_hold_istk_vozobnovlyaem;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Polling пропущен: активен optimistic hold'**
  String get auto_polling_propuschen_aktiven_optimist;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'_retryWithBackoff: неожиданное завершение цикла'**
  String get auto_retrywithbackoff_neozhidannoe_zaver;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сводка статистики закэширована'**
  String get auto_svodka_statistiki_zakeshirovana;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при кэшировании сводки'**
  String get auto_oshibka_pri_keshirovanii_svodki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при получении кэша сводки'**
  String get auto_oshibka_pri_poluchenii_kesha_svodki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'AI резюме закэшировано'**
  String get auto_ai_rezyume_zakeshirovano;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при кэшировании AI резюме'**
  String get auto_oshibka_pri_keshirovanii_ai_rezyume;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при получении кэша AI резюме'**
  String get auto_oshibka_pri_poluchenii_kesha_ai_rez;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Кэш статистики очищен'**
  String get auto_kesh_statistiki_ochischen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при очистке кэша'**
  String get auto_oshibka_pri_ochistke_kesha;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить поставщика из хранилища'**
  String get auto_ne_udalos_vosstanovit_postavschika;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки избранного из хранилища'**
  String get auto_oshibka_zagruzki_izbrannogo_iz_hran;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сохранения избранного в хранилище'**
  String get auto_oshibka_sohraneniya_izbrannogo_v_hr;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.id невалиден'**
  String get auto_purchasetemplateid_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.name невалиден'**
  String get auto_purchasetemplatename_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.createdAt невалиден'**
  String get auto_purchasetemplatecreatedat_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.updatedAt невалиден'**
  String get auto_purchasetemplateupdatedat_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.items невалиден'**
  String get auto_purchasetemplateitems_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.createdAt не ISO-8601'**
  String get auto_purchasetemplatecreatedat_ne_iso860;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'PurchaseTemplate.updatedAt не ISO-8601'**
  String get auto_purchasetemplateupdatedat_ne_iso860;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem не объект'**
  String get auto_templateitem_ne_obekt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.productId невалиден'**
  String get auto_templateitemproductid_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.supplierId невалиден'**
  String get auto_templateitemsupplierid_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.quantity невалиден'**
  String get auto_templateitemquantity_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.productName невалиден'**
  String get auto_templateitemproductname_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.productImageUrl невалиден'**
  String get auto_templateitemproductimageurl_nevalid;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.supplierName невалиден'**
  String get auto_templateitemsuppliername_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.pricePerUnit невалиден'**
  String get auto_templateitempriceperunit_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.minQuantity невалиден'**
  String get auto_templateitemminquantity_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'TemplateItem.maxQuantity невалиден'**
  String get auto_templateitemmaxquantity_nevaliden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Имя шаблона: от 1 до 50 символов'**
  String get auto_imya_shablona_ot_1_do_50_simvolov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Шаблон с таким именем уже существует'**
  String get auto_shablon_s_takim_imenem_uzhe_susches;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Шаблон не может быть пустым'**
  String get auto_shablon_ne_mozhet_byt_pustym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'В шаблоне может быть не более 100 позиций.'**
  String get auto_v_shablone_mozhet_byt_ne_bolee_100;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Достигнут лимит шаблонов: 20. Удалите ненужный шаблон.'**
  String get auto_dostignut_limit_shablonov_20_udalit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'никому'**
  String get auto_nikomu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'loadForCurrentUser: рассогласование авторизации '**
  String get auto_loadforcurrentuser_rassoglasovanie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'loadForCurrentUser: не удалось прочитать SharedPreferences'**
  String get auto_loadforcurrentuser_ne_udalos_prochi;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'clearCache: не удалось очистить SharedPreferences'**
  String get auto_clearcache_ne_udalos_ochistit_share;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'_persist: не удалось записать шаблоны в SharedPreferences'**
  String get auto_persist_ne_udalos_zapisat_shablony;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Общие характеристики'**
  String get util_general_characteristics;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Калории'**
  String get util_calories;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get util_protein;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get util_fat;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Углеводы'**
  String get util_carbohydrates;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'ккал'**
  String get util_kcal;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'г/100 г'**
  String get util_grams_per_100g;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Питание'**
  String get util_nutrition;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get util_composition;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'только что'**
  String get util_just_now;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'назад'**
  String get util_ago;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'минуту'**
  String get util_minute_one;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'минуты'**
  String get util_minute_few;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'минут'**
  String get util_minute_many;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'час'**
  String get util_hour_one;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'часа'**
  String get util_hour_few;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'часов'**
  String get util_hour_many;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'день'**
  String get util_day_one;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'дня'**
  String get util_day_few;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'дней'**
  String get util_day_many;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get util_delivery;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get util_today;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get util_tomorrow;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get util_today_lower;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'завтра'**
  String get util_tomorrow_lower;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Доставка сегодня'**
  String get util_delivery_today;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Доставка завтра'**
  String get util_delivery_tomorrow;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Ежедневно'**
  String get util_daily;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Будни'**
  String get util_weekdays;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Выходные'**
  String get util_weekends;

  /// Текст развоза с временем
  ///
  /// In ru, this message translates to:
  /// **'Развоз в {time}'**
  String util_delivery_at(String time);

  /// Заказы до времени отсечки
  ///
  /// In ru, this message translates to:
  /// **'Заказы до {time} уезжают сегодня'**
  String util_orders_before(String time);

  /// Доставка с датой
  ///
  /// In ru, this message translates to:
  /// **'Доставка {date}'**
  String util_delivery_date(String date);

  /// Доставка с диапазоном дат
  ///
  /// In ru, this message translates to:
  /// **'Доставка {range}'**
  String util_delivery_range(String range);

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get util_weekday_mon;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get util_weekday_tue;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get util_weekday_wed;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get util_weekday_thu;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get util_weekday_fri;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get util_weekday_sat;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get util_weekday_sun;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get util_weekday_monday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get util_weekday_tuesday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get util_weekday_wednesday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get util_weekday_thursday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get util_weekday_friday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get util_weekday_saturday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get util_weekday_sunday;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'будни'**
  String get util_weekday_keyword_weekdays;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'выходные'**
  String get util_weekday_keyword_weekends;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'ежедневно'**
  String get util_weekday_keyword_daily;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'каждый день'**
  String get util_weekday_keyword_every_day;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get util_month_gen_1;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get util_month_gen_2;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get util_month_gen_3;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get util_month_gen_4;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get util_month_gen_5;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get util_month_gen_6;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get util_month_gen_7;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get util_month_gen_8;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get util_month_gen_9;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get util_month_gen_10;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get util_month_gen_11;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get util_month_gen_12;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get util_month_display_1;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get util_month_display_2;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get util_month_display_3;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get util_month_display_4;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get util_month_display_5;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get util_month_display_6;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get util_month_display_7;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get util_month_display_8;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get util_month_display_9;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get util_month_display_10;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get util_month_display_11;

  /// Авто-утилиты
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get util_month_display_12;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить товары'**
  String get auto_ne_udalos_zagruzit_tovary;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Одобрено'**
  String get auto_odobreno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get auto_otkloneno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'На модерации'**
  String get auto_na_moderatsii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Одобрить товар'**
  String get auto_odobrit_tovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отклонить товар'**
  String get auto_otklonit_tovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар одобрен'**
  String get auto_tovar_odobren;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар отклонен'**
  String get auto_tovar_otklonen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обновлении статуса'**
  String get auto_oshibka_pri_obnovlenii_statusa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить модератора'**
  String get auto_ne_udalos_opredelit_moderatora;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар за нарушение'**
  String get auto_udalit_tovar_za_narushenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Причина удаления для поставщика'**
  String get auto_prichina_udaleniya_dlya_postavschik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get auto_udalit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар удален, поставщик уведомлен'**
  String get auto_tovar_udalen_postavschik_uvedomlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар удален'**
  String get auto_tovar_udalen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить товар'**
  String get auto_ne_udalos_udalit_tovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get auto_otpravit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Причина отклонения'**
  String get auto_prichina_otkloneniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get auto_kommentariy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Без категории'**
  String get auto_bez_kategorii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get auto_na_proverke;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get auto_vse;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поиск: товар, поставщик, категория'**
  String get auto_poisk_tovar_postavschik_kategoriya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get auto_ochistit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет заявок'**
  String get auto_net_zayavok;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'По вашему запросу ничего не найдено'**
  String get auto_po_vashemu_zaprosu_nichego_ne_nayde;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет подходящих товаров'**
  String get auto_net_podhodyaschih_tovarov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get auto_tsena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Партия'**
  String get auto_partiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить за нарушение'**
  String get auto_udalit_za_narushenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get auto_otklonit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'О товаре'**
  String get auto_o_tovare;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get auto_podrobnee;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Действие нельзя отменить.'**
  String get auto_deystvie_nelzya_otmenit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Это удалит все backup-коды и доверенные устройства пользователя. '**
  String get auto_eto_udalit_vse_backupkody_i_doveren;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация отключена'**
  String get auto_dvuhfaktornaya_autentifikatsiya_otk;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Действие доступно только модераторам'**
  String get auto_deystvie_dostupno_tolko_moderatoram;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отключить 2FA'**
  String get auto_ne_udalos_otklyuchit_2fa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отключить двухфакторную аутентификацию'**
  String get auto_otklyuchit_dvuhfaktornuyu_autentifi;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Напиток Coca-Cola газированный 1.5 л'**
  String get auto_napitok_cocacola_gazirovannyy_15_l;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Coca-Cola - самый популярный газированный напиток в мире. Имеет резкий, но приятный вкус, хорошо утоляет жажду, рекомендуется пить охлажденным.'**
  String get auto_cocacola_samyy_populyarnyy_gazirova;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Напитки'**
  String get auto_napitki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Газированные напитки'**
  String get auto_gazirovannye_napitki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Газированная вода, сахар, краситель (сахарный колер [IV]), регулятор кислотности (ортофосфорная кислота), натуральные ароматизаторы, кофеин.'**
  String get auto_gazirovannaya_voda_sahar_krasitel_s;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Страна производителя'**
  String get auto_strana_proizvoditelya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Казахстан'**
  String get auto_kazahstan;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Торговая марка'**
  String get auto_torgovaya_marka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Линейка'**
  String get auto_lineyka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Классическая'**
  String get auto_klassicheskaya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Склад \"Манса\"'**
  String get auto_sklad_mansa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'завтра'**
  String get auto_zavtra;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доставка межгород'**
  String get auto_dostavka_mezhgorod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Четверг 17:00'**
  String get auto_chetverg_1700;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вс 21 сентября'**
  String get auto_vs_21_sentyabrya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сб 23 сентября 12:00'**
  String get auto_sb_23_sentyabrya_1200;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Какой-то крутой поставщик'**
  String get auto_kakoyto_krutoy_postavschik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сб 20 сентября'**
  String get auto_sb_20_sentyabrya;

  /// Auto-extracted from lib\models\currency.dart
  ///
  /// In ru, this message translates to:
  /// **'Казахский тенге'**
  String get currency_auto_1;

  /// Auto-extracted from lib\models\currency.dart
  ///
  /// In ru, this message translates to:
  /// **'Российский рубль'**
  String get currency_auto_2;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get language_auto_3;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get language_auto_4;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get language_auto_5;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get language_auto_6;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get language_auto_7;

  /// Auto-extracted from lib\models\language.dart
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get language_auto_8;

  /// Auto-extracted from lib\models\product.dart
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных поставщиков'**
  String get product_auto_9;

  /// Auto-extracted from lib\models\user_address.dart
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get user_address_auto_10;

  /// Auto-extracted from lib\models\user_address.dart
  ///
  /// In ru, this message translates to:
  /// **'Работа'**
  String get user_address_auto_11;

  /// Auto-extracted from lib\models\user_address.dart
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get user_address_auto_12;

  /// Auto-extracted from lib\models\user_address.dart
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get user_address_auto_13;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'РЈРґР°Р»РёС‚СЊ Р·Р° РЅР°СЂСѓС€РµРЅРёРµ'**
  String get moderation_page_auto_14;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'РћС‚РєР»РѕРЅРёС‚СЊ'**
  String get moderation_page_auto_15;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'Рћ С‚РѕРІР°СЂРµ'**
  String get moderation_page_auto_16;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'РџРѕРґСЂРѕР±РЅРµРµ'**
  String get moderation_page_auto_17;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **' В· '**
  String get moderation_page_auto_18;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка конфигурации API'**
  String get ai_service_auto_19;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать AI-резюме'**
  String get ai_service_auto_20;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ты AI-аналитик поставщиков. ОБЯЗАТЕЛЬНО отвечай ТОЛЬКО на русском языке. '**
  String get ai_service_auto_21;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Все твои ответы должны быть на 100% на русском. '**
  String get ai_service_auto_22;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Никогда не используй другие языки ни при каких обстоятельствах.'**
  String get ai_service_auto_23;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Запрос занял слишком долго'**
  String get ai_service_auto_24;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету'**
  String get ai_service_auto_25;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать AI-резюме'**
  String get ai_service_auto_26;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать AI-резюме'**
  String get ai_service_auto_27;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка конфигурации API'**
  String get ai_service_auto_28;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера. Попробуем другую модель'**
  String get ai_service_auto_29;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка AI сервиса'**
  String get ai_service_auto_30;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get ai_service_auto_31;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get ai_service_auto_32;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get ai_service_auto_33;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get ai_service_auto_34;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'AI-резюме успешно сгенерировано'**
  String get ai_service_auto_35;

  /// Auto-extracted from lib\services\api\ai_service.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при обработке ответа'**
  String get ai_service_auto_36;

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Заказ с ID {orderId} не найден'**
  String message_localization_auto_37(Object orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ #{orderId} подтверждён'**
  String message_localization_auto_38(Object orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Заказ #{orderId} доставлен'**
  String message_localization_auto_39(Object orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Товар с ID {productId} не найден'**
  String message_localization_auto_40(Object productId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка валидации: {details}'**
  String message_localization_auto_41(Object details);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать ответ AI: {reason}'**
  String message_localization_auto_42(Object reason);

  /// Auto-extracted from lib\utils\custom_characteristic_validation.dart
  ///
  /// In ru, this message translates to:
  /// **'Заполните название и значение характеристики'**
  String get custom_characteristic_validation_auto_43;

  /// Auto-extracted from lib\utils\custom_characteristic_validation.dart
  ///
  /// In ru, this message translates to:
  /// **'Такая характеристика уже добавлена'**
  String get custom_characteristic_validation_auto_44;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'январь'**
  String get month_year_parser_auto_45;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'февраль'**
  String get month_year_parser_auto_46;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'март'**
  String get month_year_parser_auto_47;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'апрель'**
  String get month_year_parser_auto_48;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'май'**
  String get month_year_parser_auto_49;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июнь'**
  String get month_year_parser_auto_50;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июль'**
  String get month_year_parser_auto_51;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'август'**
  String get month_year_parser_auto_52;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'сентябрь'**
  String get month_year_parser_auto_53;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'октябрь'**
  String get month_year_parser_auto_54;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'ноябрь'**
  String get month_year_parser_auto_55;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'декабрь'**
  String get month_year_parser_auto_56;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'янв'**
  String get month_year_parser_auto_57;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'фев'**
  String get month_year_parser_auto_58;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'мар'**
  String get month_year_parser_auto_59;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'апр'**
  String get month_year_parser_auto_60;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июн'**
  String get month_year_parser_auto_61;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июл'**
  String get month_year_parser_auto_62;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'авг'**
  String get month_year_parser_auto_63;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'сен'**
  String get month_year_parser_auto_64;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'окт'**
  String get month_year_parser_auto_65;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'ноя'**
  String get month_year_parser_auto_66;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'дек'**
  String get month_year_parser_auto_67;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'янв.'**
  String get month_year_parser_auto_68;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'фев.'**
  String get month_year_parser_auto_69;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'мар.'**
  String get month_year_parser_auto_70;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'апр.'**
  String get month_year_parser_auto_71;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'май.'**
  String get month_year_parser_auto_72;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июн.'**
  String get month_year_parser_auto_73;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'июл.'**
  String get month_year_parser_auto_74;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'авг.'**
  String get month_year_parser_auto_75;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'сен.'**
  String get month_year_parser_auto_76;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'окт.'**
  String get month_year_parser_auto_77;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'ноя.'**
  String get month_year_parser_auto_78;

  /// Auto-extracted from lib\utils\month_year_parser.dart
  ///
  /// In ru, this message translates to:
  /// **'дек.'**
  String get month_year_parser_auto_79;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ё'**
  String get search_normalizer_auto_80;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_81;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'а'**
  String get search_normalizer_auto_82;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'б'**
  String get search_normalizer_auto_83;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get search_normalizer_auto_84;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get search_normalizer_auto_85;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'д'**
  String get search_normalizer_auto_86;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_87;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ё'**
  String get search_normalizer_auto_88;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ж'**
  String get search_normalizer_auto_89;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'з'**
  String get search_normalizer_auto_90;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get search_normalizer_auto_91;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'й'**
  String get search_normalizer_auto_92;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_93;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get search_normalizer_auto_94;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get search_normalizer_auto_95;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'н'**
  String get search_normalizer_auto_96;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'о'**
  String get search_normalizer_auto_97;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'п'**
  String get search_normalizer_auto_98;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'р'**
  String get search_normalizer_auto_99;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get search_normalizer_auto_100;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'т'**
  String get search_normalizer_auto_101;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'у'**
  String get search_normalizer_auto_102;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ф'**
  String get search_normalizer_auto_103;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'х'**
  String get search_normalizer_auto_104;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ц'**
  String get search_normalizer_auto_105;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get search_normalizer_auto_106;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ш'**
  String get search_normalizer_auto_107;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'щ'**
  String get search_normalizer_auto_108;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ъ'**
  String get search_normalizer_auto_109;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ы'**
  String get search_normalizer_auto_110;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ь'**
  String get search_normalizer_auto_111;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'э'**
  String get search_normalizer_auto_112;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ю'**
  String get search_normalizer_auto_113;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'я'**
  String get search_normalizer_auto_114;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'щ'**
  String get search_normalizer_auto_115;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'щ'**
  String get search_normalizer_auto_116;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ж'**
  String get search_normalizer_auto_117;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'х'**
  String get search_normalizer_auto_118;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ц'**
  String get search_normalizer_auto_119;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get search_normalizer_auto_120;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ш'**
  String get search_normalizer_auto_121;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ю'**
  String get search_normalizer_auto_122;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'я'**
  String get search_normalizer_auto_123;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_124;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ё'**
  String get search_normalizer_auto_125;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ю'**
  String get search_normalizer_auto_126;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'я'**
  String get search_normalizer_auto_127;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'а'**
  String get search_normalizer_auto_128;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'б'**
  String get search_normalizer_auto_129;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get search_normalizer_auto_130;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get search_normalizer_auto_131;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'д'**
  String get search_normalizer_auto_132;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_133;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'з'**
  String get search_normalizer_auto_134;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get search_normalizer_auto_135;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'й'**
  String get search_normalizer_auto_136;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_137;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get search_normalizer_auto_138;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get search_normalizer_auto_139;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'н'**
  String get search_normalizer_auto_140;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'о'**
  String get search_normalizer_auto_141;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'п'**
  String get search_normalizer_auto_142;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'р'**
  String get search_normalizer_auto_143;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get search_normalizer_auto_144;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'т'**
  String get search_normalizer_auto_145;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'у'**
  String get search_normalizer_auto_146;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ф'**
  String get search_normalizer_auto_147;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'х'**
  String get search_normalizer_auto_148;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_149;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_150;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get search_normalizer_auto_151;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'кс'**
  String get search_normalizer_auto_152;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'дж'**
  String get search_normalizer_auto_153;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ё'**
  String get search_normalizer_auto_154;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'й'**
  String get search_normalizer_auto_155;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ц'**
  String get search_normalizer_auto_156;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'у'**
  String get search_normalizer_auto_157;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_158;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_159;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'н'**
  String get search_normalizer_auto_160;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get search_normalizer_auto_161;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ш'**
  String get search_normalizer_auto_162;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'щ'**
  String get search_normalizer_auto_163;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'з'**
  String get search_normalizer_auto_164;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'х'**
  String get search_normalizer_auto_165;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ъ'**
  String get search_normalizer_auto_166;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ф'**
  String get search_normalizer_auto_167;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ы'**
  String get search_normalizer_auto_168;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get search_normalizer_auto_169;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'а'**
  String get search_normalizer_auto_170;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'п'**
  String get search_normalizer_auto_171;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'р'**
  String get search_normalizer_auto_172;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'о'**
  String get search_normalizer_auto_173;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get search_normalizer_auto_174;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'д'**
  String get search_normalizer_auto_175;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ж'**
  String get search_normalizer_auto_176;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'э'**
  String get search_normalizer_auto_177;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'я'**
  String get search_normalizer_auto_178;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get search_normalizer_auto_179;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get search_normalizer_auto_180;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get search_normalizer_auto_181;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get search_normalizer_auto_182;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'т'**
  String get search_normalizer_auto_183;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ь'**
  String get search_normalizer_auto_184;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'б'**
  String get search_normalizer_auto_185;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ю'**
  String get search_normalizer_auto_186;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'й'**
  String get search_normalizer_auto_187;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ц'**
  String get search_normalizer_auto_188;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'у'**
  String get search_normalizer_auto_189;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'к'**
  String get search_normalizer_auto_190;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'е'**
  String get search_normalizer_auto_191;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'н'**
  String get search_normalizer_auto_192;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get search_normalizer_auto_193;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ш'**
  String get search_normalizer_auto_194;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'щ'**
  String get search_normalizer_auto_195;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'з'**
  String get search_normalizer_auto_196;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'х'**
  String get search_normalizer_auto_197;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ъ'**
  String get search_normalizer_auto_198;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ф'**
  String get search_normalizer_auto_199;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ы'**
  String get search_normalizer_auto_200;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'в'**
  String get search_normalizer_auto_201;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'а'**
  String get search_normalizer_auto_202;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'п'**
  String get search_normalizer_auto_203;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'р'**
  String get search_normalizer_auto_204;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'о'**
  String get search_normalizer_auto_205;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get search_normalizer_auto_206;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'д'**
  String get search_normalizer_auto_207;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ж'**
  String get search_normalizer_auto_208;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'э'**
  String get search_normalizer_auto_209;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'я'**
  String get search_normalizer_auto_210;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get search_normalizer_auto_211;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get search_normalizer_auto_212;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get search_normalizer_auto_213;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get search_normalizer_auto_214;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'т'**
  String get search_normalizer_auto_215;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ь'**
  String get search_normalizer_auto_216;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'б'**
  String get search_normalizer_auto_217;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ю'**
  String get search_normalizer_auto_218;

  /// Auto-extracted from lib\utils\search_normalizer.dart
  ///
  /// In ru, this message translates to:
  /// **'ё'**
  String get search_normalizer_auto_219;

  /// Auto-extracted from lib\utils\wizard_init.dart
  ///
  /// In ru, this message translates to:
  /// **'Страна производителя'**
  String get wizard_init_auto_220;

  /// Auto-extracted from lib\utils\wizard_init.dart
  ///
  /// In ru, this message translates to:
  /// **'Срок годности'**
  String get wizard_init_auto_221;

  /// No description provided for @product_card_added_to_cart.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в корзину: {name} -{count} шт.'**
  String product_card_added_to_cart(String name, int count);

  /// No description provided for @product_card_delivery.
  ///
  /// In ru, this message translates to:
  /// **'Доставка: {date}'**
  String product_card_delivery(String date);

  /// No description provided for @product_card_days_per_week.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн./нед {time}'**
  String product_card_days_per_week(int count, String time);

  /// No description provided for @product_card_today.
  ///
  /// In ru, this message translates to:
  /// **'сегодня {time}'**
  String product_card_today(String time);

  /// No description provided for @product_card_tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'завтра {time}'**
  String product_card_tomorrow(String time);

  /// No description provided for @supplier_qa_review_card_reply_from.
  ///
  /// In ru, this message translates to:
  /// **'Ответ от {name}'**
  String supplier_qa_review_card_reply_from(String name);

  /// No description provided for @validation_empty_or_too_long.
  ///
  /// In ru, this message translates to:
  /// **'Заполните название и значение характеристики'**
  String get validation_empty_or_too_long;

  /// No description provided for @validation_duplicate.
  ///
  /// In ru, this message translates to:
  /// **'Такая характеристика уже добавлена'**
  String get validation_duplicate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
