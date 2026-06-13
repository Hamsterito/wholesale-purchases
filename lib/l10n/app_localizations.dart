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
  /// **'Редактировать адрес'**
  String get auto_redaktirovatAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавить адрес'**
  String get auto_dobavitAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'АДРЕС'**
  String get auto_adres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'УЛИЦА'**
  String get auto_ulitsa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ПОЧТОВЫЙ ИНДЕКС'**
  String get auto_pochtovyyIndeks;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'КВАРТИРА'**
  String get auto_kvartira;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get auto_dom;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Работа'**
  String get auto_rabota;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get auto_drugoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ'**
  String get auto_sohranit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ АДРЕС'**
  String get auto_sohranitAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите адрес'**
  String get auto_vvediteAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Адрес слишком короткий'**
  String get auto_adresSlishkomKorotkiy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Улица'**
  String get auto_ulitsa_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Индекс должен содержать только цифры (3-10)'**
  String get auto_indeksDolzhenSoderzhat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Квартира'**
  String get auto_kvartira_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Некорректный формат квартиры'**
  String get auto_nekorrektnyyFormatKvart;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите имя владельца карты'**
  String get auto_vvediteImyaVladeltsaKa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Имя слишком короткое'**
  String get auto_imyaSlishkomKorotkoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Имя не должно содержать цифры'**
  String get auto_imyaNeDolzhnoSoderzhat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите номер карты'**
  String get auto_vvediteNomerKarty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер карты должен быть 16 цифр'**
  String get auto_nomerKartyDolzhenByt1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный номер карты'**
  String get auto_nevernyyNomerKarty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите срок действия'**
  String get auto_vvediteSrokDeystviya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите формат ММ/ГГ'**
  String get auto_vvediteFormatMmgg;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Месяц должен быть 01-12'**
  String get auto_mesyatsDolzhenByt0112;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Срок действия истёк'**
  String get auto_srokDeystviyaIstyok;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите CVC'**
  String get auto_vvediteCvc;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'CVC: 3 цифры'**
  String get auto_cvc3Tsifry;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы добавить карту'**
  String get auto_voyditeChtobyDobavitKa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проверьте введённые данные'**
  String get auto_proverteVvedyonnyeDanny;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить карту'**
  String get auto_neUdalosSohranitKartu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавить метод оплаты'**
  String get auto_dobavitMetodOplaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ИМЯ ВЛАДЕЛЬЦА КАРТЫ'**
  String get auto_imyaVladeltsaKarty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НОМЕР КАРТЫ'**
  String get auto_nomerKarty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СРОК ДЕЙСТВИЯ'**
  String get auto_srokDeystviya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ММ/ГГ'**
  String get auto_mmgg;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ДОБАВИТЬ МЕТОД ОПЛАТЫ'**
  String get auto_dobavitMetodOplaty_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get auto_vvediteTekushchiyParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get auto_minimum6Simvolov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get auto_vvediteNovyyParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль должен отличаться от текущего'**
  String get auto_novyyParolDolzhenOtlic;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Повторите новый пароль'**
  String get auto_povtoriteNovyyParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get auto_paroliNeSovpadayut;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить пароль'**
  String get auto_neUdalosIzmenitParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите снова.'**
  String get auto_sessiyaIsteklaVoyditeS;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get auto_izmenitParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get auto_tekushchiyParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get auto_novyyParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль ещё раз'**
  String get auto_vvediteParolEshchyoRaz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать минимум 6 символов и отличаться от текущего.'**
  String get auto_parolDolzhenSoderzhatM;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ ПАРОЛЬ'**
  String get auto_sohranitParol;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Иван Иванов'**
  String get auto_ivanIvanov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Люблю сладости'**
  String get auto_lyublyuSladosti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сделать снимок'**
  String get auto_sdelatSnimok;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get auto_vybratIzGalerei;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get auto_udalitFoto;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вы не авторизованы'**
  String get auto_vyNeAvtorizovany;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Размер файла не должен превышать 5 МБ'**
  String get auto_razmerFaylaNeDolzhenP;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ред. Профиль'**
  String get auto_redProfil;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ФИО'**
  String get auto_fio;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ЭЛ. ПОЧТА'**
  String get auto_elPochta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НОМЕР'**
  String get auto_nomer;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'ОПИСАНИЕ'**
  String get auto_opisanie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер должен быть в формате +7-XXX-XXX-XXXX'**
  String get auto_nomerDolzhenBytVForma;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Как сделать заказ?'**
  String get auto_kakSdelatZakaz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чтобы сделать заказ, выберите товары из каталога, добавьте их в корзину и оформите заказ, указав адрес доставки и способ оплаты.'**
  String get auto_chtobySdelatZakazVyber;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Какие способы оплаты доступны?'**
  String get auto_kakieSposobyOplatyDost;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Мы принимаем оплату наличными, банковскими картами (Visa, Mastercard), а также через PayPal.'**
  String get auto_myPrinimaemOplatuNalic;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сколько времени занимает доставка?'**
  String get auto_skolkoVremeniZanimaetD;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Стандартная доставка занимает 1-3 рабочих дня. Экспресс-доставка доступна в течение 24 часов.'**
  String get auto_standartnayaDostavkaZan;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Могу ли я отменить заказ?'**
  String get auto_moguLiYaOtmenitZakaz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вы можете отменить заказ в течение 30 минут после оформления. После этого заказ уже будет передан на склад для сборки.'**
  String get auto_vyMozheteOtmenitZakaz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Как изменить адрес доставки?'**
  String get auto_kakIzmenitAdresDostavk;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get auto_profil;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Адреса'**
  String get auto_adresa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Что делать если товар не подошел?'**
  String get auto_chtoDelatEsliTovarNe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вы можете вернуть товар в течение 14 дней с момента получения. Свяжитесь с нашей службой поддержки для оформления возврата.'**
  String get auto_vyMozheteVernutTovarV;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Как связаться с поддержкой?'**
  String get auto_kakSvyazatsyaSPodderzh;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Техподдержка'**
  String get auto_tehpodderzhka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Есть ли минимальная сумма заказа?'**
  String get auto_estLiMinimalnayaSumma;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Минимальная сумма заказа составляет 500 ₸. При заказе от 5000 ₸ доставка бесплатная.'**
  String get auto_minimalnayaSummaZakaza;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопросы и ответы'**
  String get auto_voprosyIOtvety;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get auto_nazad;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get auto_izbrannoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вкладка избранные товары'**
  String get auto_vkladkaIzbrannyeTovary;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вкладка избранные компании'**
  String get auto_vkladkaIzbrannyeKompani;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пока нет избранных товаров'**
  String get auto_pokaNetIzbrannyhTovaro;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных компаний'**
  String get auto_netIzbrannyhKompaniy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить адреса'**
  String get auto_neUdalosZagruzitAdresa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нужно войти в аккаунт'**
  String get auto_nuzhnoVoytiVAkkaunt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить адрес'**
  String get auto_neUdalosSohranitAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get auto_zakryt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить адрес'**
  String get auto_neUdalosUdalitAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Мои адреса'**
  String get auto_moiAdresa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Адресов пока нет'**
  String get auto_adresovPokaNet;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес, чтобы оформить заказ быстрее.'**
  String get auto_dobavteAdresChtobyOfor;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Без адреса'**
  String get auto_bezAdresa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get auto_redaktirovat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get auto_udalit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить адрес?'**
  String get auto_udalitAdres;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get auto_otmena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Карта добавлена'**
  String get auto_kartaDobavlena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Метод оплаты'**
  String get auto_metodOplaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get auto_nalichnye;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавить новый'**
  String get auto_dobavitNovyy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет карт Visa'**
  String get auto_netKartVisa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет карт Mastercard'**
  String get auto_netKartMastercard;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавьте карту Visa, чтобы выбрать этот способ оплаты.'**
  String get auto_dobavteKartuVisaChtoby;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавьте карту Mastercard, чтобы выбрать этот способ оплаты.'**
  String get auto_dobavteKartuMastercard;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты Visa'**
  String get auto_vashiKartyVisa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты Mastercard'**
  String get auto_vashiKartyMastercard;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты'**
  String get auto_vashiKarty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оплата наличными'**
  String get auto_oplataNalichnymi;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вы выбрали оплату наличными при получении.'**
  String get auto_vyVybraliOplatuNalichn;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подключение PayPal пока недоступно.\\nВыберите карту или наличные.'**
  String get auto_podklyucheniePaypalPoka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет способа оплаты'**
  String get auto_netSposobaOplaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, выберите способ\\nоплаты'**
  String get auto_pozhaluystaVyberiteSpos;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить карту'**
  String get auto_udalitKartu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Карта удалена'**
  String get auto_kartaUdalena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get auto_neUkazano;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get auto_vvediteImya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get auto_vvediteEmail;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Некорректный email'**
  String get auto_nekorrektnyyEmail;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get auto_vvediteNomerTelefona;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер должен быть в формате +7-000-000-0000'**
  String get auto_nomerDolzhenBytVForma_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Имя сохранено'**
  String get auto_imyaSohraneno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Email сохранен'**
  String get auto_emailSohranen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Номер сохранен'**
  String get auto_nomerSohranen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите название компании'**
  String get auto_vvediteNazvanieKompanii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Название компании сохранено'**
  String get auto_nazvanieKompaniiSohrane;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Личная информация'**
  String get auto_lichnayaInformatsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'НАЗВАНИЕ КОМПАНИИ'**
  String get auto_nazvanieKompanii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите новое значение'**
  String get auto_vvediteNovoeZnachenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get auto_sohranit_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get auto_nastroyki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get auto_vyyti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get auto_moiZakazy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'История заказов'**
  String get auto_istoriyaZakazov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get auto_sposobOplaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваши отзывы'**
  String get auto_vashiOtzyvy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Быстрая доставка'**
  String get auto_bystrayaDostavka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Хорошая цена'**
  String get auto_horoshayaTsena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Качественная упаковка'**
  String get auto_kachestvennayaUpakovka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Свежий товар'**
  String get auto_svezhiyTovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вежливый курьер'**
  String get auto_vezhlivyyKurer;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы увидеть отзывы.'**
  String get auto_voyditeChtobyUvidetOtz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отзывы.'**
  String get auto_neUdalosZagruzitOtzyvy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Есть покупки для оценки'**
  String get auto_estPokupkiDlyaOtsenki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Все отзывы о покупках'**
  String get auto_vseOtzyvyOPokupkah;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов'**
  String get auto_pokaNetOtzyvov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ожидают отзывов'**
  String get auto_ozhidayutOtzyvov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оцените покупки - это помогает другим'**
  String get auto_otsenitePokupkiEtoPomo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправляем...'**
  String get auto_otpravlyaem;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get auto_ostavitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оставьте отзыв после принятия заказа - он появится здесь.'**
  String get auto_ostavteOtzyvPoslePriny;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Текст отзыва'**
  String get auto_tekstOtzyva;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Без текста отзыва'**
  String get auto_bezTekstaOtzyva;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем...'**
  String get auto_sohranyaem;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оцените товар'**
  String get auto_otseniteTovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваш отзыв'**
  String get auto_vashOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь впечатлениями'**
  String get auto_podelitesVpechatleniyami;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get auto_izmenit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы редактировать отзыв'**
  String get auto_voyditeChtobyRedaktirov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отзыв обновлен'**
  String get auto_otzyvObnovlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить отзыв'**
  String get auto_neUdalosSohranitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставьте оценку'**
  String get auto_postavteOtsenku;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавьте детали'**
  String get auto_dobavteDetali;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get auto_otpravitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы оставить отзыв'**
  String get auto_voyditeChtobyOstavitOt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за отзыв!'**
  String get auto_spasiboZaOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить отзыв'**
  String get auto_neUdalosOtpravitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы удалить отзыв'**
  String get auto_voyditeChtobyUdalitOtz;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отзыв удален'**
  String get auto_otzyvUdalen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить отзыв'**
  String get auto_neUdalosUdalitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв?'**
  String get auto_udalitOtzyv;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить.'**
  String get auto_etoDeystvieNelzyaOtmen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды двухфакторной аутентификации\\n'**
  String get auto_rezervnyeKodyDvuhfaktor;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сохраните их в надёжном месте - каждый код можно использовать только один раз.\\n'**
  String get auto_sohraniteIhVNadyozhnom;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Коды скопированы в буфер обмена'**
  String get auto_kodySkopirovanyVBufer;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Файл с кодами сохранён'**
  String get auto_faylSKodamiSohranyon;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды'**
  String get auto_rezervnyeKody;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды двухфакторной аутентификации'**
  String get auto_rezervnyeKodyDvuhfaktor_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сохраните коды в безопасном месте — они показываются один раз. Каждый код можно использовать только однократно для входа, если потерян доступ к почте.'**
  String get auto_sohraniteKodyVBezopasn;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get auto_gotovo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код. Попробуйте ещё раз.'**
  String get auto_neUdalosOtpravitKodPo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация отключена'**
  String get auto_dvuhfaktornayaAutentifik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get auto_nevernyyKod;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения к серверу'**
  String get auto_oshibkaPodklyucheniyaK;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен повторно'**
  String get auto_kodOtpravlenPovtorno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код повторно'**
  String get auto_neUdalosOtpravitKodPo_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Выключение 2FA'**
  String get auto_vyklyuchenie2fa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение по почте'**
  String get auto_podtverzhdeniePoPochte;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите код подтверждения, отправленный на вашу почту, '**
  String get auto_vvediteKodPodtverzhdeni;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'чтобы выключить двухфакторную аутентификацию.'**
  String get auto_chtobyVyklyuchitDvuhfak;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Повторить отправку'**
  String get auto_povtoritOtpravku;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Срок действия кода истёк, отправьте повторно'**
  String get auto_srokDeystviyaKodaIstyo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'СРОК ИСТЁК'**
  String get auto_srokIstyok;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно'**
  String get auto_otpravitPovtorno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get auto_podtverdit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Включение 2FA'**
  String get auto_vklyuchenie2fa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'чтобы включить двухфакторную аутентификацию.'**
  String get auto_chtobyVklyuchitDvuhfakt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить статус двухфакторной аутентификации'**
  String get auto_neUdalosZagruzitStatus;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Регенерация backup-кодов'**
  String get auto_regeneratsiyaBackupkodov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'чтобы заменить текущие резервные коды.'**
  String get auto_chtobyZamenitTekushchie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать новые коды'**
  String get auto_neUdalosSgenerirovatNo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отзыв доверенных устройств'**
  String get auto_otzyvDoverennyhUstroyst;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'чтобы отозвать все ранее запомненные устройства.'**
  String get auto_chtobyOtozvatVseRanee;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Доверенные устройства отозваны'**
  String get auto_doverennyeUstroystvaOto;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отозвать устройства'**
  String get auto_neUdalosOtozvatUstroys;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация'**
  String get auto_dvuhfaktornayaAutentifik_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get auto_povtorit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Осталось мало резервных кодов, сгенерируйте новые'**
  String get auto_ostalosMaloRezervnyhKo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Включена. При входе потребуется код из почты.'**
  String get auto_vklyuchenaPriVhodePotr;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Выключена. Защитите аккаунт дополнительным кодом.'**
  String get auto_vyklyuchenaZashchititeA;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать новые backup-коды'**
  String get auto_sgenerirovatNovyeBackup;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Старые коды будут удалены'**
  String get auto_staryeKodyBudutUdaleny;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отозвать доверенные устройства'**
  String get auto_otozvatDoverennyeUstroy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'На всех устройствах потребуется код заново'**
  String get auto_naVsehUstroystvahPotre;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить пользователя'**
  String get auto_neUdalosOpredelitPolzo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чат'**
  String get auto_neUdalosZagruzitChat;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт. Создайте новое обращение.'**
  String get auto_chatZakrytSozdayteNovo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение'**
  String get auto_vvediteSoobshchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить сообщение'**
  String get auto_neUdalosOtpravitSoobsh;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чат с техподдержкой'**
  String get auto_chatSTehpodderzhkoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Активного чата нет. Сначала отправьте обращение в техподдержку.'**
  String get auto_aktivnogoChataNetSnach;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чат не найден.'**
  String get auto_chatNeNayden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get auto_podderzhka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт'**
  String get auto_chatZakryt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Чат открыт. Техподдержка ответит в этом окне.'**
  String get auto_chatOtkrytTehpodderzhka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Операторы онлайн. Обычно отвечаем быстро.'**
  String get auto_operatoryOnlaynObychno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сейчас офлайн. Ответим в рабочее время.'**
  String get auto_seychasOflaynOtvetimV;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Опишите проблему'**
  String get auto_opishiteProblemu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проблема с заказом'**
  String get auto_problemaSZakazom;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Проблема с оплатой'**
  String get auto_problemaSOplatoy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Технические неполадки'**
  String get auto_tehnicheskieNepoladki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопрос о товаре'**
  String get auto_voprosOTovare;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить обращение'**
  String get auto_neUdalosZagruzitObrash;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Обращение отправлено в техподдержку'**
  String get auto_obrashchenieOtpravlenoV;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сообщение отправлено'**
  String get auto_soobshchenieOtpravleno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить обращение'**
  String get auto_neUdalosOtpravitObrash;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Свяжитесь с нами'**
  String get auto_svyazhitesSNami;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Пн-Вс: 09:00 - 21:00 (UTC+5)'**
  String get auto_pnvs09002100Utc5;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Продолжить обращение'**
  String get auto_prodolzhitObrashchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить обращение'**
  String get auto_otpravitObrashchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Активный чат открыт'**
  String get auto_aktivnyyChatOtkryt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее обращение закрыто. Если вопрос актуален, отправьте новое.'**
  String get auto_predydushcheeObrashcheni;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Открыть чат с техподдержкой'**
  String get auto_otkrytChatSTehpodderzh;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Категория обращения'**
  String get auto_kategoriyaObrashcheniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get auto_vyberiteKategoriyu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Тема обращения'**
  String get auto_temaObrashcheniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Введите тему'**
  String get auto_vvediteTemu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get auto_soobshchenie;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get auto_otpravit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'доставлен'**
  String get auto_dostavlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'доставлено'**
  String get auto_dostavleno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'в пути'**
  String get auto_vPuti;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'собира'**
  String get auto_sobira;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'принят'**
  String get auto_prinyat;

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
  /// **'отмен'**
  String get auto_otmen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get auto_min;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get auto_adresDostavki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить выбор'**
  String get auto_podtverditVybor;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес, чтобы продолжить оформление.'**
  String get auto_dobavteAdresChtobyProd;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы оформить заказ'**
  String get auto_voyditeChtobyOformitZa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'позиция'**
  String get auto_pozitsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'позиции'**
  String get auto_pozitsii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'позиций'**
  String get auto_pozitsiy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Очистить корзину'**
  String get auto_ochistitKorzinu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'напит'**
  String get auto_napit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'овощ'**
  String get auto_ovoshch;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'фрукт'**
  String get auto_frukt;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'хлеб'**
  String get auto_hleb;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'пекар'**
  String get auto_pekar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'молоч'**
  String get auto_moloch;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'мяс'**
  String get auto_myas;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'птиц'**
  String get auto_ptits;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get auto_katalog;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поиск категорий...'**
  String get auto_poiskKategoriy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет категорий'**
  String get auto_netKategoriy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get auto_nichegoNeNaydeno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поиск подкатегорий...'**
  String get auto_poiskPodkategoriy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'В этой категории пока нет товаров'**
  String get auto_vEtoyKategoriiPokaNet;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'все'**
  String get auto_vse;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'барлығы'**
  String get auto_barlyy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'скид'**
  String get auto_skid;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'За день'**
  String get auto_zaDen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get auto_nedelya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get auto_mesyats;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get auto_kvartal;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get auto_filtr;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать в .excel'**
  String get auto_eksportirovatVExcel;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'История пока пустая'**
  String get auto_istoriyaPokaPustaya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров'**
  String get auto_netTovarov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get auto_status;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Дата заказа'**
  String get auto_dataZakaza;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Количество товаров'**
  String get auto_kolichestvoTovarov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Общее кол-во'**
  String get auto_obshcheeKolvo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get auto_polucheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товары в заказе'**
  String get auto_tovaryVZakaze;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'получено'**
  String get auto_polucheno_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'завершено'**
  String get auto_zaversheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Требуется авторизация'**
  String get auto_trebuetsyaAvtorizatsiya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Файл загружен'**
  String get auto_faylZagruzhen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get auto_netVNalichii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'О товаре'**
  String get auto_oTovare;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get auto_podrobnee;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get auto_postavshchik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить из избранного'**
  String get auto_udalitIzIzbrannogo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get auto_dobavitVIzbrannoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get auto_dobavlenoVIzbrannoe;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалено из избранного'**
  String get auto_udalenoIzIzbrannogo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отзывов пока нет'**
  String get auto_otzyvovPokaNet;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Оценить товар можно только после ее покупки'**
  String get auto_otsenitTovarMozhnoTolk;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопросов по товару еще не было'**
  String get auto_voprosovPoTovaruEshche;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Будьте первым!'**
  String get auto_budtePervym;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get auto_zadatVopros;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'вопросов'**
  String get auto_voprosov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get auto_harakteristiki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get auto_opisanie_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет данных о товаре'**
  String get auto_netDannyhOTovare;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Описание не указано'**
  String get auto_opisanieNeUkazano;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get auto_pokupatel;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Без текста'**
  String get auto_bezTeksta;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Перейти ко всем отзывам'**
  String get auto_pereytiKoVsemOtzyvam;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Перейти ко всем вопросам'**
  String get auto_pereytiKoVsemVoprosam;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вопросы о товаре'**
  String get auto_voprosyOTovare;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get auto_oshibka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет вопросов'**
  String get auto_netVoprosov;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Будьте первым, кто задаст вопрос!'**
  String get auto_budtePervymKtoZadastV;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар'**
  String get auto_tovar;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ваш вопрос'**
  String get auto_vashVopros;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отзывы'**
  String get auto_neUdalosZagruzitOtzyvy_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get auto_otzyvy;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся оценки и мнения покупателей.'**
  String get auto_zdesPoyavyatsyaOtsenki;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get auto_svernut;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ответ продавца'**
  String get auto_otvetProdavtsa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get auto_vse_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик не найден'**
  String get auto_postavshchikNeNayden;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания'**
  String get auto_vremyaOzhidaniya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло. Проверьте соединение и повторите попытку.'**
  String get auto_vremyaOzhidaniyaIsteklo;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету'**
  String get auto_netPodklyucheniyaKInte;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные. Попробуйте ещё раз.'**
  String get auto_neUdalosZagruzitDannye;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров от этого поставщика'**
  String get auto_netTovarovOtEtogoPost;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товары не найдены'**
  String get auto_tovaryNeNaydeny;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get auto_poisk;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка'**
  String get auto_proizoshlaOshibka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Вернуться'**
  String get auto_vernutsya;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get auto_filtry;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Цена за шт.'**
  String get auto_tsenaZaSht;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'от'**
  String get auto_ot;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'до'**
  String get auto_do;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get auto_sortirovka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get auto_tsena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get auto_reyting;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Порядок'**
  String get auto_poryadok;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'По возрастанию'**
  String get auto_poVozrastaniyu;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'По убыванию'**
  String get auto_poUbyvaniyu;
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
