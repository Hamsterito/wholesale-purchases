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
  /// **'Редактировать'**
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
  /// **'Повторить'**
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
  /// **'Например, ТОО Ромашка'**
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

  /// Уведомление об отсутствии товаров
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
  /// **'Все товары будут удалены из корзины.'**
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

  /// Заголовок страницы сведений о товаре
  ///
  /// In ru, this message translates to:
  /// **'Детали товара'**
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

  /// Заголовок страницы товаров поставщика
  ///
  /// In ru, this message translates to:
  /// **'Мои товары'**
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

  /// Кнопка Добавить товар
  ///
  /// In ru, this message translates to:
  /// **'Добавление товара'**
  String get supplier_add_product;

  /// Кнопка редактирования товара
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
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

  /// Совет по весу товара
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
  /// **'Поиск по товарам, поставщикам, категориям'**
  String get moderator_search_hint;

  /// Совет по поиску пользователей
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени или email'**
  String get moderator_search_users;

  /// Причина удаления товара
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
  /// **'Чаты поддержки'**
  String get moderator_support_chats;

  /// Совет по выбору категории заявки
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get support_category_hint;

  /// Консультация по теме обращения
  ///
  /// In ru, this message translates to:
  /// **'Введите тему обращения'**
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

  /// Образец уведомления о незаработанном товаре
  ///
  /// In ru, this message translates to:
  /// **'ID {productId} существующий товар не найден'**
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
  /// **'Ошибка обработки сообщения'**
  String get message_parse_error;

  /// Шаблон сообщения об ошибке генерации AI
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать ответ ИИ: {reason}'**
  String message_ai_generation_failed(int reason);

  /// Transition between statuses
  ///
  /// In ru, this message translates to:
  /// **'из \"{fromStatus}\" в \"{toStatus}\"'**
  String supplier_status_transition(Object fromStatus, Object toStatus);

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

  /// Тема секции организационных товаров
  ///
  /// In ru, this message translates to:
  /// **'Похожие товары'**
  String get product_similar;

  /// Ошибка загрузки товаров
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить товары'**
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

  /// Уведомление о отправке товара на модерацию
  ///
  /// In ru, this message translates to:
  /// **'Товар отправлен на модерацию'**
  String get supplier_product_sent_moderation;

  /// Уведомление о внесении изменений в модерацию
  ///
  /// In ru, this message translates to:
  /// **'Изменения отправлены на модерацию'**
  String get supplier_changes_sent_moderation;

  /// Тема диалога удаления товара
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар?'**
  String get supplier_delete_product;

  /// Наименование субъекта продукции
  ///
  /// In ru, this message translates to:
  /// **'Товар'**
  String get supplier_product;

  /// Извещение о снятии продукции с публицистики
  ///
  /// In ru, this message translates to:
  /// **'Товар снят с публикации'**
  String get supplier_removed_from_publication;

  /// Уведомление об уничтожении товара
  ///
  /// In ru, this message translates to:
  /// **'Товар удален'**
  String get supplier_product_deleted;

  /// Сообщение об ошибке удаления товара
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить товар'**
  String get supplier_error_delete_product;

  /// Утвержденный статус товара
  ///
  /// In ru, this message translates to:
  /// **'Одобрен'**
  String get supplier_apprved;

  /// Статус товара без вставки
  ///
  /// In ru, this message translates to:
  /// **'Отклонён'**
  String get supplier_rejected;

  /// Статус товара в умеренности
  ///
  /// In ru, this message translates to:
  /// **'На модерации'**
  String get supplier_pending;

  /// Текст для безымянного товара
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get supplier_no_title;

  /// Текст для товара без описания
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
  /// **'Невозможно перейти в этот статус'**
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
  /// **'Активные'**
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
  /// **'Мои товары на заказ'**
  String get supplier_products_in_order;

  /// Тема секции товаров группы
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

  /// Тег товара свежий
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
  /// **'необязательно'**
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
  /// **'Собирается'**
  String get supplier_status_assembling;

  /// Статус в заказе
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get supplier_status_in_transit;

  /// Заказ доставлен статус
  ///
  /// In ru, this message translates to:
  /// **'Доставлен'**
  String get supplier_status_delivered;

  /// Заказ получен статус
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
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

  /// Тема секции вопросов без ответов
  ///
  /// In ru, this message translates to:
  /// **'Вопросы без ответа'**
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
  /// **'Нет отзывов'**
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
  /// **'Без ответа'**
  String get qa_without_answer;

  /// Уведомление о моменте отправки ответа
  ///
  /// In ru, this message translates to:
  /// **'Ответ успешно отправлен'**
  String get qa_answer_sent_success;

  /// Ответ уведомление о моменте обновления
  ///
  /// In ru, this message translates to:
  /// **'Ответ успешно обновлен'**
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
  /// **'Повторить'**
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
  /// **'Покупатели ещё не задавали вопросов'**
  String get qa_customers_no_questions;

  /// Сообщение о том, что товар не оставил отзыв
  ///
  /// In ru, this message translates to:
  /// **'Покупатели пока не оставили отзывов'**
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
  /// **'Ваши отзывы'**
  String get profile_reviews_title;

  /// Сообщение об отсутствии комментариев
  ///
  /// In ru, this message translates to:
  /// **'пока нет отзывов'**
  String get profile_reviews_empty;

  /// Тема ожидаемой секции комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ожидают отзыва'**
  String get profile_reviews_pending_title;

  /// Подзаголовок секции ожидаемых отзывов
  ///
  /// In ru, this message translates to:
  /// **'Оцените покупки — это поможет другим'**
  String get profile_reviews_pending_subtitle;

  /// Кнопка Оставить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get profile_reviews_leave_review;

  /// Расчет отзывов
  ///
  /// In ru, this message translates to:
  /// **'{count} всего'**
  String profile_reviews_total_count(int count);

  /// Тема секции комментариев
  ///
  /// In ru, this message translates to:
  /// **'Ваши отзывы'**
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
  /// **'Оцените товар'**
  String get profile_reviews_rate_product;

  /// Т қосу добавить записи подписка
  ///
  /// In ru, this message translates to:
  /// **'Добавить детали'**
  String get profile_reviews_add_details;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
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
  /// **'Отзыв обновлен'**
  String get profile_reviews_saved_success;

  /// Сообщение об ошибке сохранения
  ///
  /// In ru, this message translates to:
  /// **'Отзыв не удалось сохранить'**
  String get profile_reviews_save_error;

  /// Уведомление о необходимости авторизации
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы Отправить отзыв'**
  String get profile_reviews_login_required;

  /// Уведомление о необходимости оценки
  ///
  /// In ru, this message translates to:
  /// **'Дайте товару оценку'**
  String get profile_reviews_rating_required;

  /// Успешное отправление сообщения
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за отзыв!'**
  String get profile_reviews_submit_success;

  /// Сообщение об ошибке отправки
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить отзыв'**
  String get profile_reviews_submit_error;

  /// Подтверждение удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв?'**
  String get profile_reviews_delete_confirm;

  /// Сообщение об успешном удалении
  ///
  /// In ru, this message translates to:
  /// **'Отзыв удален'**
  String get profile_reviews_delete_success;

  /// Сообщение об ошибке удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв не удалось'**
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
  /// **'Оцените товар'**
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
  /// **'Редактировать'**
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
  /// **'Оставить отзыв'**
  String get review_leave_button;

  /// Кнопка Отправить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get review_submit_button;

  /// Подтверждение удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв?'**
  String get review_delete_confirm;

  /// Кнопка закрытия диалога
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get review_close_dialog;

  /// Кнопка редактирования
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get review_edit_draft;

  /// Кнопка удаления
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get review_delete_draft;

  /// Кнопка Оставить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get review_leave_draft;

  /// Кнопка Отправить комментарий
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get review_submit_draft;

  /// Сообщение Спасибо за комментарий
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за отзыв!'**
  String get review_thank_you;

  /// Сообщение об отсутствии комментариев
  ///
  /// In ru, this message translates to:
  /// **'пока нет отзывов'**
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

  /// Подтверждение удаления товара
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить этот товар?'**
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
  /// **'Текущая корзина заменяется товарами из шаблона. Продолжать?'**
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
  /// **'января'**
  String get zakazi_month_january;

  /// Февраль месяц
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get zakazi_month_february;

  /// Месяц марта
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get zakazi_month_march;

  /// Апрель месяц
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get zakazi_month_april;

  /// Май месяц
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get zakazi_month_may;

  /// Июнь месяц
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get zakazi_month_june;

  /// Месяц июля
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get zakazi_month_july;

  /// Месяц августа
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get zakazi_month_august;

  /// Сентябрь месяц
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get zakazi_month_september;

  /// Месяц октября
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get zakazi_month_october;

  /// Ноябрь месяц
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get zakazi_month_november;

  /// Месяц декабря
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get zakazi_month_december;

  /// Сокращение категории
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get zakazi_quantity_short;

  /// Статус получения заказа
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get zakazi_accepted_label;

  /// С доставкой
  ///
  /// In ru, this message translates to:
  /// **'С доставкой'**
  String get zakazi_after_delivery;

  /// Уведомление о том, что вы можете получить после доставки
  ///
  /// In ru, this message translates to:
  /// **'Можно принять товар после доставки'**
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
  /// **'Заказ {orderId} - на сумму {amount}'**
  String zakazi_order_amount(int orderId, int amount);

  /// Тема диалога удаления заказа
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ?'**
  String get zakazi_cancel_order_title;

  /// Уведомление об отмене заказа
  ///
  /// In ru, this message translates to:
  /// **'Заказ будет отменён, а товары возвращены на склад.'**
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
  /// **'Заказ принят.'**
  String get zakazi_order_accepted;

  /// Ошибка получения заказа
  ///
  /// In ru, this message translates to:
  /// **'Не удалось принять заказ. Повторите попытку.'**
  String get zakazi_accept_failed;

  /// Ошибка отмены заказа
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отменить заказ. Повторите попытку.'**
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
  /// **'Наличными при получении'**
  String get cart_payment_method_cash;

  /// Способ оплаты картой
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get cart_payment_method_card;

  /// Уведомление об отсутствии подключенной карты
  ///
  /// In ru, this message translates to:
  /// **'Карта не привязана'**
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
  /// **'Добавьте адрес доставки, чтобы продолжить.'**
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
  /// **'Шаблоны'**
  String get cart_template_title;

  /// Требование авторизации для использования шаблонов
  ///
  /// In ru, this message translates to:
  /// **'Чтобы использовать шаблоны, посетите'**
  String get cart_template_login_required;

  /// Ошибка использования шаблона
  ///
  /// In ru, this message translates to:
  /// **'Не удалось применить шаблон'**
  String get cart_template_apply_error;

  /// Когда ни одна продукция в образце не найдена в каталоге
  ///
  /// In ru, this message translates to:
  /// **'Шаблон не применён: товары недоступны'**
  String get cart_template_apply_none;

  /// Успешное использование шаблона
  ///
  /// In ru, this message translates to:
  /// **'Корзина заменена шаблоном «{name}»: добавлено {added} шт.'**
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

  /// Тема списка реализованных товаров
  ///
  /// In ru, this message translates to:
  /// **'Пропущено {count} товаров'**
  String cart_template_skipped_title(int count);

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
  /// **'Поставщик больше не предлагает этот товар'**
  String get cart_template_skip_supplier_missing;

  /// Удачное переименование шаблона
  ///
  /// In ru, this message translates to:
  /// **'Шаблон переименован'**
  String get cart_template_rename_success;

  /// Тема диалога удаления шаблона
  ///
  /// In ru, this message translates to:
  /// **'Удаление шаблона {name}?'**
  String cart_template_delete_title(int name);

  /// Успешное удаление шаблона
  ///
  /// In ru, this message translates to:
  /// **'Шаблон удален'**
  String get cart_template_delete_success;

  /// Примечание о лимите позиций типа
  ///
  /// In ru, this message translates to:
  /// **'В шаблоне должно быть не более 100 позиций.'**
  String get cart_template_limit_items;

  /// Примечание о лимите количества образцов
  ///
  /// In ru, this message translates to:
  /// **'Достигнут лимит шаблонов (20). Удалите ненужные.'**
  String get cart_template_limit_templates;

  /// Успешное сохранение образца
  ///
  /// In ru, this message translates to:
  /// **'Шаблон сохранён'**
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
  /// **'{units} шт - {positions} позиций'**
  String cart_total_summary(int units, int positions);

  /// Уведомление о дополнительных товарах в корзине
  ///
  /// In ru, this message translates to:
  /// **'еще +в корзине{count}'**
  String cart_summary_more_items(int count);

  /// Итоговая сумма по поставщику тема
  ///
  /// In ru, this message translates to:
  /// **'Итого по поставщику'**
  String get cart_supplier_total_title;

  /// Кнопка оформления заказа по поставщику
  ///
  /// In ru, this message translates to:
  /// **'Оформление заказа'**
  String get cart_checkout_order;

  /// Информация о количестве товаров и позиций поставщика
  ///
  /// In ru, this message translates to:
  /// **'{units} шт - {positions} позиций'**
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

  /// Название вкладки "Все товары"
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get home_all_tab;

  /// Сообщение об ошибке загрузки товаров
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки товаров: {error}'**
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
  /// **'Напишите сообщение...'**
  String get chat_empty_hint;

  /// Подпис сегодняшнего дня в чате
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get chat_today;

  /// Уведомление об отсутствии товаров
  ///
  /// In ru, this message translates to:
  /// **'Товары не найдены'**
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
  /// **'Сбросить'**
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
  /// **'Порядок'**
  String get filter_order_title;

  /// От меньшего до большего
  ///
  /// In ru, this message translates to:
  /// **'От меньшего к большему'**
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

  /// Кнопка отображения отфильтрованных товаров
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
  /// **'Сбросить'**
  String get supplier_reset_button;

  /// Кнопка редактирования товара
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
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
  /// **'Одобрить'**
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
  /// **'Сбросить'**
  String get supplier_profile_reset;

  /// Превью показать кнопка
  ///
  /// In ru, this message translates to:
  /// **'Показать {count}'**
  String supplier_profile_preview_show(int count);

  /// Тема диалога создания чата
  ///
  /// In ru, this message translates to:
  /// **'Создать чат?'**
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
  /// **'Принять'**
  String get accept_order_button;

  /// Уведомление об отсутствии поставщиков
  ///
  /// In ru, this message translates to:
  /// **'Поставщики не найдены'**
  String get suppliers_not_found;

  /// Кнопка закрытия чата
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close_chat_button;

  /// Кнопка обновления чата
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
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
  /// **'Не удалось открыть чат'**
  String get chat_open_failed;

  /// Сообщение об ошибке чата
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать чат'**
  String get chat_create_failed;

  /// Сообщение об отсутствии результатов поиска
  ///
  /// In ru, this message translates to:
  /// **'По вашему запросу ничего не найдено'**
  String get search_no_results;

  /// Нет результатов поиска для запроса
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» ничего не найдено'**
  String search_no_results_for(int query);

  /// No description provided for @suppliers_catalog_access_denied.
  ///
  /// In ru, this message translates to:
  /// **'Каталог поставщиков доступен только модераторам и администраторам.'**
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
  /// **'Одобрить'**
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
  /// **'Отзыв'**
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
  /// **'Доступ запрещен'**
  String get auto_dostup_zapreshchen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить вход. Попробуйте позже.'**
  String get auto_ne_udalos_vypolnit_vkhod_poprobuyte;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения к серверу: {e}'**
  String auto_oshibka_podklyucheniya_k_serveru_e(String e);

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать, {name}!'**
  String auto_vkhod_vypolnen(String name);

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать, {name}!'**
  String auto_dobro_pozhalovat_name(String name);

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
  /// **'Введите {emailOtpLength}-значный код'**
  String auto_vvedite_emailotplength_znachnyy_kod(String emailOtpLength);

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
  /// **'Не удалось Отправить код повторно'**
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
  /// **'Использовать backup-код'**
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
  /// **'Не удалось завершить регистрацию'**
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
  /// **'{e}'**
  String auto_oshibka_podklyucheniya(String e);

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
  /// **'Отправить КОД'**
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
  /// **'Модератор'**
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
  /// **'Быстрая доставка'**
  String get auto_dostavka_po_rossii;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Быстрая доставка'**
  String get auto_bystraya_dostavka;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Поставщик качественных товаров оптом'**
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
  /// **'Быстрая доставка'**
  String get auto_ekspressdostavka_24_chasa;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Специализируемся на быстрой доставке'**
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
  /// **'отправлено'**
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
  /// **'Доставлен'**
  String get auto_dostavlen;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get auto_polucheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get auto_prinyat_1;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Принята'**
  String get auto_prinyata;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get auto_prinyato;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Приняты'**
  String get auto_prinyaty;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'завершено'**
  String get auto_zaversheno;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get auto_otmena;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'отменен'**
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
  /// **'Товар'**
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
  /// **'Товар'**
  String get auto_nm;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте подключение: {reason}'**
  String auto_oshibka_seti_proverte_podklyuchenie(String reason);

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания ответа: {reason}'**
  String auto_prevysheno_vremya_ozhidaniya_otveta(String reason);

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Не удалось разобрать сообщение: {reason}'**
  String auto_ne_udalos_razobrat_soobschenie(String reason);

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
  /// **'Сводка статистики кэширована'**
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
  /// **'AI-резюме кэшировано'**
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
  /// **'(isRemembered=true, userId={userId}), кэш пуст'**
  String auto_loadforcurrentuser_rassoglasovanie(String userId);

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
  /// **'Введите причину удаления (будет видна поставщику)'**
  String get auto_prichina_udaleniya_dlya_postavschik;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get auto_udalit;

  /// Auto-extracted
  ///
  /// In ru, this message translates to:
  /// **'Товар удален'**
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
  /// **'Отзыв'**
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
  /// **'Нет подходящих товаров'**
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
  /// **'Завтра'**
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
  /// **'Сб 23 сентября 12:00'**
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
  /// **'Четверг 17:00'**
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
  /// **'Удалить за нарушение'**
  String get moderation_page_auto_14;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get moderation_page_auto_15;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'О товаре'**
  String get moderation_page_auto_16;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get moderation_page_auto_17;

  /// Auto-extracted from lib\moderator\moderation_page.dart
  ///
  /// In ru, this message translates to:
  /// **' · '**
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
  String message_localization_auto_37(String orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ #{orderId} подтверждён'**
  String message_localization_auto_38(String orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Заказ #{orderId} доставлен'**
  String message_localization_auto_39(String orderId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Товар с ID {productId} не найден'**
  String message_localization_auto_40(String productId);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Ошибка валидации: {details}'**
  String message_localization_auto_41(String details);

  /// Auto-extracted from lib\services\message\message_localization.dart
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать ответ AI: {reason}'**
  String message_localization_auto_42(String reason);

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

  /// No description provided for @supplier_orders_order_number.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{orderId}'**
  String supplier_orders_order_number(Object orderId);

  /// No description provided for @supplier_orders_items_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} поз.'**
  String supplier_orders_items_count(int count);

  /// No description provided for @reviews_count_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Оценок: {count}'**
  String reviews_count_prefix(Object count);

  /// No description provided for @questions_error_loading.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки вопросов: {error}'**
  String questions_error_loading(Object error);

  /// No description provided for @questions_total_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} всего'**
  String questions_total_count(Object count);

  /// No description provided for @questions_min_chars_error.
  ///
  /// In ru, this message translates to:
  /// **'Минимум {minLength} символов ({current}/{minLength})'**
  String questions_min_chars_error(Object current, Object minLength);

  /// No description provided for @questions_enter_prompt.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваш вопрос (минимум {minLength} символов)'**
  String questions_enter_prompt(Object minLength);

  /// No description provided for @product_added_to_cart.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в корзину: {name}'**
  String product_added_to_cart(Object name);

  /// No description provided for @product_removed_from_cart.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из корзины: {name}'**
  String product_removed_from_cart(Object name);

  /// No description provided for @product_tab_reviews.
  ///
  /// In ru, this message translates to:
  /// **'Оценки ({count})'**
  String product_tab_reviews(Object count);

  /// No description provided for @product_tab_questions.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы ({count})'**
  String product_tab_questions(Object count);

  /// No description provided for @product_price_per_unit.
  ///
  /// In ru, this message translates to:
  /// **'{price}/шт'**
  String product_price_per_unit(Object price);

  /// No description provided for @product_in_stock.
  ///
  /// In ru, this message translates to:
  /// **'В наличии: {count} шт.'**
  String product_in_stock(Object count);

  /// No description provided for @product_reviews_label.
  ///
  /// In ru, this message translates to:
  /// **'{count} оценок'**
  String product_reviews_label(Object count);

  /// No description provided for @order_history_order_number.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{id}'**
  String order_history_order_number(Object id);

  /// No description provided for @order_history_items_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String order_history_items_count(Object count);

  /// No description provided for @order_history_units_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} ед.'**
  String order_history_units_count(Object count);

  /// No description provided for @order_history_received_items.
  ///
  /// In ru, this message translates to:
  /// **'{received}/{total} шт.'**
  String order_history_received_items(Object received, Object total);

  /// No description provided for @order_history_supplier_name.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик: {name}'**
  String order_history_supplier_name(Object name);

  /// No description provided for @order_history_export_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка экспорта: {error}'**
  String order_history_export_error(Object error);

  /// No description provided for @error_loading_products.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки товаров: {error}'**
  String error_loading_products(Object error);

  /// No description provided for @faqs_address_change_info.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете изменить адрес доставки в разделе {profile} -> {addresses}. {also}'**
  String faqs_address_change_info(
    Object addresses,
    Object also,
    Object profile,
  );

  /// No description provided for @faqs_support_contact_info.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете связаться с нами через раздел {support} {inApp}'**
  String faqs_support_contact_info(Object inApp, Object support);

  /// No description provided for @my_addresses_delete_confirmation.
  ///
  /// In ru, this message translates to:
  /// **'Адрес \"{title}\" будет удален без возможности восстановления.'**
  String my_addresses_delete_confirmation(Object title);

  /// No description provided for @reviews_total_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} всего'**
  String reviews_total_count(Object count);

  /// No description provided for @reviews_total_count_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String reviews_total_count_prefix(Object count);

  /// No description provided for @reviews_order_label.
  ///
  /// In ru, this message translates to:
  /// **'Заказ {id}'**
  String reviews_order_label(Object id);

  /// No description provided for @support_close_reason.
  ///
  /// In ru, this message translates to:
  /// **'Причина закрытия: {reason}'**
  String support_close_reason(Object reason);

  /// No description provided for @support_chat_closed.
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт'**
  String get support_chat_closed;

  /// No description provided for @support_chat_closed_reason.
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт. Причина: {reason}'**
  String support_chat_closed_reason(Object reason);

  /// No description provided for @zakazi_quantity.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String zakazi_quantity(Object count);

  /// No description provided for @zakazi_hours_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String zakazi_hours_minutes(Object hours, Object minutes);

  /// No description provided for @zakazi_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String zakazi_minutes(Object minutes);

  /// No description provided for @personal_info_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String personal_info_save_error(Object error);

  /// No description provided for @payment_method_delete_confirmation.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить карту **** {last4}?'**
  String payment_method_delete_confirmation(Object last4);

  /// No description provided for @address_field_max_length.
  ///
  /// In ru, this message translates to:
  /// **'Поле {field} не должно превышать {max} символов'**
  String address_field_max_length(Object field, Object max);

  /// No description provided for @address_zip_max_length.
  ///
  /// In ru, this message translates to:
  /// **'Индекс не должен превышать {max} символов'**
  String address_zip_max_length(Object max);

  /// No description provided for @two_factor_enter_code.
  ///
  /// In ru, this message translates to:
  /// **'Введите {length}-значный код'**
  String two_factor_enter_code(Object length);

  /// No description provided for @two_factor_code_valid.
  ///
  /// In ru, this message translates to:
  /// **'КОД ДЕЙСТВИТЕЛЕН {seconds} СЕК'**
  String two_factor_code_valid(Object seconds);

  /// No description provided for @two_factor_file_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить файл: {error}'**
  String two_factor_file_save_error(Object error);

  /// No description provided for @moderator_remove_confirmation.
  ///
  /// In ru, this message translates to:
  /// **'{name} ({email}) больше не сможет модерировать товары.'**
  String moderator_remove_confirmation(Object email, Object name);

  /// No description provided for @moderator_user_label.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь #{id}'**
  String moderator_user_label(Object id);

  /// No description provided for @moderation_from_min_qty.
  ///
  /// In ru, this message translates to:
  /// **'От {min} шт.'**
  String moderation_from_min_qty(Object min);

  /// No description provided for @moderation_qty_range.
  ///
  /// In ru, this message translates to:
  /// **'{min}-{max} шт.'**
  String moderation_qty_range(Object max, Object min);

  /// No description provided for @moderation_summary_time.
  ///
  /// In ru, this message translates to:
  /// **'{summary} · {time}'**
  String moderation_summary_time(Object summary, Object time);

  /// No description provided for @moderation_stock_quantity.
  ///
  /// In ru, this message translates to:
  /// **'Остаток: {count} шт.'**
  String moderation_stock_quantity(Object count);

  /// No description provided for @moderation_price_per_unit.
  ///
  /// In ru, this message translates to:
  /// **'{price} за единицу'**
  String moderation_price_per_unit(Object price);

  /// No description provided for @moderation_comment_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв модерации: {comment}'**
  String moderation_comment_prefix(Object comment);

  /// No description provided for @moderation_characteristic_format.
  ///
  /// In ru, this message translates to:
  /// **'{key} — {value}'**
  String moderation_characteristic_format(Object key, Object value);

  /// No description provided for @moderator_two_factor_remove_warning.
  ///
  /// In ru, this message translates to:
  /// **'Это удалит все backup-коды и доверенные устройства пользователя {name}. {warning}'**
  String moderator_two_factor_remove_warning(Object name, Object warning);

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
  String product_card_delivery(Object date);

  /// No description provided for @product_card_days_per_week.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн./нед {time}'**
  String product_card_days_per_week(int count, String time);

  /// No description provided for @product_card_today.
  ///
  /// In ru, this message translates to:
  /// **'сегодня {time}'**
  String product_card_today(Object time);

  /// No description provided for @product_card_tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'завтра {time}'**
  String product_card_tomorrow(Object time);

  /// No description provided for @supplier_qa_review_card_reply_from.
  ///
  /// In ru, this message translates to:
  /// **'Ответ от {name}'**
  String supplier_qa_review_card_reply_from(Object name);

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

  /// No description provided for @qa_minimum_characters.
  ///
  /// In ru, this message translates to:
  /// **'Минимум {minLength} символов ({currentLength}/{minLength})'**
  String qa_minimum_characters(int minLength, int currentLength);

  /// No description provided for @qa_enter_answer_minimum.
  ///
  /// In ru, this message translates to:
  /// **'Введите ответ (минимум {minLength} символов)'**
  String qa_enter_answer_minimum(int minLength);

  /// No description provided for @avatar_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить аватарку: {url} ({error})'**
  String avatar_load_error(Object error, Object url);

  /// No description provided for @qa_answer_from_supplier.
  ///
  /// In ru, this message translates to:
  /// **'Ответ от {supplierName}'**
  String qa_answer_from_supplier(Object supplierName);

  /// No description provided for @ratings_count_parentheses.
  ///
  /// In ru, this message translates to:
  /// **'Оценок ({count})'**
  String ratings_count_parentheses(int count);

  /// No description provided for @ratings_count_colon.
  ///
  /// In ru, this message translates to:
  /// **'Оценок: {count}'**
  String ratings_count_colon(int count);

  /// No description provided for @nutrition_calories_unit.
  ///
  /// In ru, this message translates to:
  /// **'{value} к'**
  String nutrition_calories_unit(Object value);

  /// No description provided for @nutrition_grams_unit.
  ///
  /// In ru, this message translates to:
  /// **'{value} г'**
  String nutrition_grams_unit(Object value);

  /// No description provided for @templates_sheet_rename_template.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать шаблон {name}'**
  String templates_sheet_rename_template(Object name);

  /// No description provided for @templates_sheet_delete_template.
  ///
  /// In ru, this message translates to:
  /// **'Удалить шаблон {name}'**
  String templates_sheet_delete_template(Object name);

  /// No description provided for @templates_sheet_add_to_cart_template.
  ///
  /// In ru, this message translates to:
  /// **'В корзину шаблон {name}'**
  String templates_sheet_add_to_cart_template(Object name);

  /// No description provided for @supplier_stats_days.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String supplier_stats_days(Object days);

  /// No description provided for @supplier_stats_units_sold.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт. продано'**
  String supplier_stats_units_sold(int count);

  /// No description provided for @supplier_stats_repeat_buyers.
  ///
  /// In ru, this message translates to:
  /// **'{percentage}% постоянных'**
  String supplier_stats_repeat_buyers(Object percentage);

  /// No description provided for @supplier_stats_reviews.
  ///
  /// In ru, this message translates to:
  /// **'{count} отзывов'**
  String supplier_stats_reviews(int count);

  /// No description provided for @supplier_stats_order_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Заказ #{orderId}'**
  String supplier_stats_order_prefix(Object orderId);

  /// No description provided for @wizard_error_price_max.
  ///
  /// In ru, this message translates to:
  /// **'Цена не должна превышать {max}'**
  String wizard_error_price_max(Object max);

  /// No description provided for @wizard_error_min_quantity_max.
  ///
  /// In ru, this message translates to:
  /// **'Минимальное количество не должно превышать {max}'**
  String wizard_error_min_quantity_max(Object max);

  /// No description provided for @wizard_error_stock_max.
  ///
  /// In ru, this message translates to:
  /// **'Остаток на складе не должен превышать {max}'**
  String wizard_error_stock_max(Object max);

  /// No description provided for @wizard_error_calories_max.
  ///
  /// In ru, this message translates to:
  /// **'Калории не должны превышать {max} (ограничение NUMERIC(10,2))'**
  String wizard_error_calories_max(Object max);

  /// No description provided for @wizard_error_protein_max.
  ///
  /// In ru, this message translates to:
  /// **'Белки не должны превышать {max} (ограничение NUMERIC(10,2))'**
  String wizard_error_protein_max(Object max);

  /// No description provided for @wizard_error_fat_max.
  ///
  /// In ru, this message translates to:
  /// **'Жиры не должны превышать {max} (ограничение NUMERIC(10,2))'**
  String wizard_error_fat_max(Object max);

  /// No description provided for @wizard_error_carbs_max.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы не должны превышать {max} (ограничение NUMERIC(10,2))'**
  String wizard_error_carbs_max(Object max);

  /// No description provided for @wizard_show_all_categories.
  ///
  /// In ru, this message translates to:
  /// **'Показать все ({count})'**
  String wizard_show_all_categories(int count);

  /// No description provided for @wizard_step_indicator.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {current} из {total}'**
  String wizard_step_indicator(int current, int total);

  /// No description provided for @supplier_products_stock_quantity.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String supplier_products_stock_quantity(int count);

  /// No description provided for @supplier_products_min_quantity.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String supplier_products_min_quantity(int count);

  /// Remaining seconds
  ///
  /// In ru, this message translates to:
  /// **'{count} секунд'**
  String util_seconds_left(String count);

  /// No description provided for @util_review_one.
  ///
  /// In ru, this message translates to:
  /// **'отзыв'**
  String get util_review_one;

  /// No description provided for @util_review_few.
  ///
  /// In ru, this message translates to:
  /// **'отзыва'**
  String get util_review_few;

  /// No description provided for @util_review_many.
  ///
  /// In ru, this message translates to:
  /// **'отзывов'**
  String get util_review_many;

  /// No description provided for @auto_oshibkaZapuska.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка запуска'**
  String get auto_oshibkaZapuska;

  /// No description provided for @auto_oshibkaZapuskaPrilozhen.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка запуска приложения'**
  String get auto_oshibkaZapuskaPrilozhen;

  /// No description provided for @auto_poprobuytePerezapustitP.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте перезапустить приложение'**
  String get auto_poprobuytePerezapustitP;

  /// No description provided for @auto_optovyeZakupki.
  ///
  /// In ru, this message translates to:
  /// **'Оптовые закупки'**
  String get auto_optovyeZakupki;

  /// No description provided for @auto_vvediteImya.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get auto_vvediteImya;

  /// No description provided for @auto_slishkomKorotkoe.
  ///
  /// In ru, this message translates to:
  /// **'Слишком короткое'**
  String get auto_slishkomKorotkoe;

  /// No description provided for @auto_vvediteEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get auto_vvediteEmail;

  /// No description provided for @auto_nekorrektnyyEmail.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный email'**
  String get auto_nekorrektnyyEmail;

  /// No description provided for @auto_vvediteTelefon.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон'**
  String get auto_vvediteTelefon;

  /// No description provided for @auto_nuzhno11Tsifr.
  ///
  /// In ru, this message translates to:
  /// **'Нужно 11 цифр'**
  String get auto_nuzhno11Tsifr;

  /// No description provided for @auto_dolzhenNachinatsyaS7.
  ///
  /// In ru, this message translates to:
  /// **'Должен начинаться с 7'**
  String get auto_dolzhenNachinatsyaS7;

  /// No description provided for @auto_vvediteParol.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get auto_vvediteParol;

  /// No description provided for @auto_minimum6Simvolov.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get auto_minimum6Simvolov;

  /// No description provided for @auto_neUdalosSozdatModerato.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать модератора'**
  String get auto_neUdalosSozdatModerato;

  /// No description provided for @auto_imya_1.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get auto_imya_1;

  /// No description provided for @auto_telefon.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get auto_telefon;

  /// No description provided for @auto_skryt.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get auto_skryt;

  /// No description provided for @auto_neAvtorizovan.
  ///
  /// In ru, this message translates to:
  /// **'Не авторизован'**
  String get auto_neAvtorizovan;

  /// No description provided for @auto_dostup.
  ///
  /// In ru, this message translates to:
  /// **'доступ'**
  String get auto_dostup;

  /// No description provided for @auto_neUdalosZagruzitModera.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить модераторов'**
  String get auto_neUdalosZagruzitModera;

  /// No description provided for @auto_moderatorDobavlen.
  ///
  /// In ru, this message translates to:
  /// **'Модератор добавлен'**
  String get auto_moderatorDobavlen;

  /// No description provided for @auto_moderatorUdalyon.
  ///
  /// In ru, this message translates to:
  /// **'Модератор удалён'**
  String get auto_moderatorUdalyon;

  /// No description provided for @auto_dobavitModeratora.
  ///
  /// In ru, this message translates to:
  /// **'Добавить модератора'**
  String get auto_dobavitModeratora;

  /// No description provided for @auto_dobavit.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get auto_dobavit;

  /// No description provided for @auto_poiskPoImeniIliEmail.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени или email'**
  String get auto_poiskPoImeniIliEmail;

  /// No description provided for @auto_moderatoryNeNaydeny.
  ///
  /// In ru, this message translates to:
  /// **'Модераторы не найдены'**
  String get auto_moderatoryNeNaydeny;

  /// No description provided for @auto_nichegoNeNaydenoPoZap.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено по запросу'**
  String get auto_nichegoNeNaydenoPoZap;

  /// No description provided for @auto_oshibka.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get auto_oshibka;

  /// No description provided for @auto_dostupZapreshchyonVoydi.
  ///
  /// In ru, this message translates to:
  /// **'Доступ запрещён. Войдите снова.'**
  String get auto_dostupZapreshchyonVoydi;

  /// No description provided for @auto_bezImeni.
  ///
  /// In ru, this message translates to:
  /// **'Без имени'**
  String get auto_bezImeni;

  /// No description provided for @auto_elPochta_1.
  ///
  /// In ru, this message translates to:
  /// **'Эл. почта'**
  String get auto_elPochta_1;

  /// No description provided for @auto_neUdalosZagruzitChaty.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чаты техподдержки'**
  String get auto_neUdalosZagruzitChaty;

  /// No description provided for @auto_zakryt_1.
  ///
  /// In ru, this message translates to:
  /// **'Закрыт'**
  String get auto_zakryt_1;

  /// No description provided for @auto_otkrytye.
  ///
  /// In ru, this message translates to:
  /// **'Открытые'**
  String get auto_otkrytye;

  /// No description provided for @auto_istoriya.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get auto_istoriya;

  /// No description provided for @auto_zakrytyhChatovPokaNet.
  ///
  /// In ru, this message translates to:
  /// **'Закрытых чатов пока нет'**
  String get auto_zakrytyhChatovPokaNet;

  /// No description provided for @auto_otkrytyhChatovSeychasN.
  ///
  /// In ru, this message translates to:
  /// **'Открытых чатов сейчас нет'**
  String get auto_otkrytyhChatovSeychasN;

  /// No description provided for @auto_neUdalosZagruzitSoobsh.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сообщения'**
  String get auto_neUdalosZagruzitSoobsh;

  /// No description provided for @auto_neUdalosOpredelitSotru.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить сотрудника техподдержки'**
  String get auto_neUdalosOpredelitSotru;

  /// No description provided for @auto_chatUzheZakryt.
  ///
  /// In ru, this message translates to:
  /// **'Чат уже закрыт'**
  String get auto_chatUzheZakryt;

  /// No description provided for @auto_vvediteSoobshchenie.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение'**
  String get auto_vvediteSoobshchenie;

  /// No description provided for @auto_neUdalosOtpravitSoobsh.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить сообщение'**
  String get auto_neUdalosOtpravitSoobsh;

  /// No description provided for @auto_prichinaZakrytiyaNeobya.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get auto_prichinaZakrytiyaNeobya;

  /// No description provided for @auto_chatZakryt.
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт'**
  String get auto_chatZakryt;

  /// No description provided for @auto_neUdalosZakrytChat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось закрыть чат'**
  String get auto_neUdalosZakrytChat;

  /// No description provided for @auto_otvetitPolzovatelyu.
  ///
  /// In ru, this message translates to:
  /// **'Ответить пользователю'**
  String get auto_otvetitPolzovatelyu;

  /// No description provided for @auto_chatOtkryt.
  ///
  /// In ru, this message translates to:
  /// **'Чат открыт'**
  String get auto_chatOtkryt;

  /// No description provided for @auto_zakrytChat.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть чат'**
  String get auto_zakrytChat;

  /// No description provided for @auto_adresDostavki.
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get auto_adresDostavki;

  /// No description provided for @auto_podtverditVybor.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить выбор'**
  String get auto_podtverditVybor;

  /// No description provided for @auto_adresovPokaNet.
  ///
  /// In ru, this message translates to:
  /// **'Адресов пока нет'**
  String get auto_adresovPokaNet;

  /// No description provided for @auto_dobavteAdresChtobyProd.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес, чтобы продолжить оформление.'**
  String get auto_dobavteAdresChtobyProd;

  /// No description provided for @auto_bezAdresa.
  ///
  /// In ru, this message translates to:
  /// **'Без адреса'**
  String get auto_bezAdresa;

  /// No description provided for @auto_neUdalosSohranitAdres.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить адрес'**
  String get auto_neUdalosSohranitAdres;

  /// No description provided for @auto_voyditeChtobyOformitZa.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы оформить заказ'**
  String get auto_voyditeChtobyOformitZa;

  /// No description provided for @auto_pozitsiya.
  ///
  /// In ru, this message translates to:
  /// **'позиция'**
  String get auto_pozitsiya;

  /// No description provided for @auto_pozitsii.
  ///
  /// In ru, this message translates to:
  /// **'позиции'**
  String get auto_pozitsii;

  /// No description provided for @auto_pozitsiy.
  ///
  /// In ru, this message translates to:
  /// **'позиций'**
  String get auto_pozitsiy;

  /// No description provided for @auto_ochistitKorzinu.
  ///
  /// In ru, this message translates to:
  /// **'Очистить корзину'**
  String get auto_ochistitKorzinu;

  /// No description provided for @auto_napit.
  ///
  /// In ru, this message translates to:
  /// **'напит'**
  String get auto_napit;

  /// No description provided for @auto_frukt.
  ///
  /// In ru, this message translates to:
  /// **'фрукт'**
  String get auto_frukt;

  /// No description provided for @auto_pekar.
  ///
  /// In ru, this message translates to:
  /// **'пекар'**
  String get auto_pekar;

  /// No description provided for @auto_moloch.
  ///
  /// In ru, this message translates to:
  /// **'молоч'**
  String get auto_moloch;

  /// No description provided for @auto_ptits.
  ///
  /// In ru, this message translates to:
  /// **'птиц'**
  String get auto_ptits;

  /// No description provided for @auto_katalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get auto_katalog;

  /// No description provided for @auto_poiskKategoriy.
  ///
  /// In ru, this message translates to:
  /// **'Поиск категорий...'**
  String get auto_poiskKategoriy;

  /// No description provided for @auto_netKategoriy.
  ///
  /// In ru, this message translates to:
  /// **'Нет категорий'**
  String get auto_netKategoriy;

  /// No description provided for @auto_nichegoNeNaydeno.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get auto_nichegoNeNaydeno;

  /// No description provided for @auto_poiskPodkategoriy.
  ///
  /// In ru, this message translates to:
  /// **'Поиск подкатегорий...'**
  String get auto_poiskPodkategoriy;

  /// No description provided for @auto_povtorit.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get auto_povtorit;

  /// No description provided for @auto_vEtoyKategoriiPokaNet.
  ///
  /// In ru, this message translates to:
  /// **'В этой категории пока нет товаров'**
  String get auto_vEtoyKategoriiPokaNet;

  /// No description provided for @auto_barlyy.
  ///
  /// In ru, this message translates to:
  /// **'все'**
  String get auto_barlyy;

  /// No description provided for @auto_skid.
  ///
  /// In ru, this message translates to:
  /// **'скид'**
  String get auto_skid;

  /// No description provided for @auto_istoriyaZakazov.
  ///
  /// In ru, this message translates to:
  /// **'История заказов'**
  String get auto_istoriyaZakazov;

  /// No description provided for @auto_filtr.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get auto_filtr;

  /// No description provided for @auto_eksportirovatVExcel.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать в .excel'**
  String get auto_eksportirovatVExcel;

  /// No description provided for @auto_istoriyaPokaPustaya.
  ///
  /// In ru, this message translates to:
  /// **'История пока пустая'**
  String get auto_istoriyaPokaPustaya;

  /// No description provided for @auto_netTovarov.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров'**
  String get auto_netTovarov;

  /// No description provided for @auto_status.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get auto_status;

  /// No description provided for @auto_dataZakaza.
  ///
  /// In ru, this message translates to:
  /// **'Дата заказа'**
  String get auto_dataZakaza;

  /// No description provided for @auto_kolichestvoTovarov.
  ///
  /// In ru, this message translates to:
  /// **'Количество товаров'**
  String get auto_kolichestvoTovarov;

  /// No description provided for @auto_obshcheeKolvo.
  ///
  /// In ru, this message translates to:
  /// **'Общее кол-во:'**
  String get auto_obshcheeKolvo;

  /// No description provided for @auto_tovaryVZakaze.
  ///
  /// In ru, this message translates to:
  /// **'Товары в заказе'**
  String get auto_tovaryVZakaze;

  /// No description provided for @auto_polucheno_1.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get auto_polucheno_1;

  /// No description provided for @auto_otmen.
  ///
  /// In ru, this message translates to:
  /// **'отмен'**
  String get auto_otmen;

  /// No description provided for @auto_trebuetsyaAvtorizatsiya.
  ///
  /// In ru, this message translates to:
  /// **'Требуется авторизация'**
  String get auto_trebuetsyaAvtorizatsiya;

  /// No description provided for @auto_faylZagruzhen.
  ///
  /// In ru, this message translates to:
  /// **'Файл загружен'**
  String get auto_faylZagruzhen;

  /// No description provided for @auto_dostavleno.
  ///
  /// In ru, this message translates to:
  /// **'доставлено'**
  String get auto_dostavleno;

  /// No description provided for @auto_netVNalichii.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get auto_netVNalichii;

  /// No description provided for @auto_oTovare.
  ///
  /// In ru, this message translates to:
  /// **'О товаре'**
  String get auto_oTovare;

  /// No description provided for @auto_udalitIzIzbrannogo.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из избранного'**
  String get auto_udalitIzIzbrannogo;

  /// No description provided for @auto_dobavitVIzbrannoe.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get auto_dobavitVIzbrannoe;

  /// No description provided for @auto_dobavlenoVIzbrannoe.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get auto_dobavlenoVIzbrannoe;

  /// No description provided for @auto_udalenoIzIzbrannogo.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из избранного'**
  String get auto_udalenoIzIzbrannogo;

  /// No description provided for @auto_otzyvovPokaNet.
  ///
  /// In ru, this message translates to:
  /// **'Отзывов пока нет'**
  String get auto_otzyvovPokaNet;

  /// No description provided for @auto_otsenitTovarMozhnoTolk.
  ///
  /// In ru, this message translates to:
  /// **'Оценить товар можно только после ее покупки'**
  String get auto_otsenitTovarMozhnoTolk;

  /// No description provided for @auto_voprosovPoTovaruEshche.
  ///
  /// In ru, this message translates to:
  /// **'Вопросов по товару еще нет'**
  String get auto_voprosovPoTovaruEshche;

  /// No description provided for @auto_budtePervym.
  ///
  /// In ru, this message translates to:
  /// **'Будьте первым!'**
  String get auto_budtePervym;

  /// No description provided for @auto_zadatVopros.
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get auto_zadatVopros;

  /// No description provided for @auto_voprosov.
  ///
  /// In ru, this message translates to:
  /// **'вопросов'**
  String get auto_voprosov;

  /// No description provided for @auto_zakryt.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get auto_zakryt;

  /// No description provided for @auto_harakteristiki.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get auto_harakteristiki;

  /// No description provided for @auto_opisanie_1.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get auto_opisanie_1;

  /// No description provided for @auto_netDannyhOTovare.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных о товаре'**
  String get auto_netDannyhOTovare;

  /// No description provided for @auto_opisanieNeUkazano.
  ///
  /// In ru, this message translates to:
  /// **'Описание не указано'**
  String get auto_opisanieNeUkazano;

  /// No description provided for @auto_bezTeksta.
  ///
  /// In ru, this message translates to:
  /// **'Без текста'**
  String get auto_bezTeksta;

  /// No description provided for @auto_pereytiKoVsemOtzyvam.
  ///
  /// In ru, this message translates to:
  /// **'Перейти ко всем отзывам'**
  String get auto_pereytiKoVsemOtzyvam;

  /// No description provided for @auto_pereytiKoVsemVoprosam.
  ///
  /// In ru, this message translates to:
  /// **'Перейти ко всем вопросам'**
  String get auto_pereytiKoVsemVoprosam;

  /// No description provided for @auto_voprosyOTovare.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы о товаре'**
  String get auto_voprosyOTovare;

  /// No description provided for @auto_netVoprosov.
  ///
  /// In ru, this message translates to:
  /// **'Нет вопросов'**
  String get auto_netVoprosov;

  /// No description provided for @auto_budtePervymKtoZadastV.
  ///
  /// In ru, this message translates to:
  /// **'Будьте первым, кто задаст вопрос!'**
  String get auto_budtePervymKtoZadastV;

  /// No description provided for @auto_vyNeAvtorizovany.
  ///
  /// In ru, this message translates to:
  /// **'Вы не авторизованы'**
  String get auto_vyNeAvtorizovany;

  /// No description provided for @auto_vashVopros.
  ///
  /// In ru, this message translates to:
  /// **'Ваш вопрос'**
  String get auto_vashVopros;

  /// No description provided for @auto_neUdalosZagruzitOtzyvy_1.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отзывы'**
  String get auto_neUdalosZagruzitOtzyvy_1;

  /// No description provided for @auto_otzyvy.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get auto_otzyvy;

  /// No description provided for @auto_pokaNetOtzyvov.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов'**
  String get auto_pokaNetOtzyvov;

  /// No description provided for @auto_zdesPoyavyatsyaOtsenki.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся оценки и мнения покупателей.'**
  String get auto_zdesPoyavyatsyaOtsenki;

  /// No description provided for @auto_svernut.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get auto_svernut;

  /// No description provided for @auto_otvetProdavtsa.
  ///
  /// In ru, this message translates to:
  /// **'Ответ продавца'**
  String get auto_otvetProdavtsa;

  /// No description provided for @auto_vse_1.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get auto_vse_1;

  /// No description provided for @auto_postavshchikNeNayden.
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло. Проверьте соединение и повторите попытку.'**
  String get auto_postavshchikNeNayden;

  /// No description provided for @auto_vremyaOzhidaniya.
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло. Проверьте соединение и повторите попытку.'**
  String get auto_vremyaOzhidaniya;

  /// No description provided for @auto_vremyaOzhidaniyaIsteklo.
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло. Проверьте соединение и повторите попытку.'**
  String get auto_vremyaOzhidaniyaIsteklo;

  /// No description provided for @auto_netPodklyucheniyaKInte.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету'**
  String get auto_netPodklyucheniyaKInte;

  /// No description provided for @auto_neUdalosZagruzitDannye.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные. Попробуйте ещё раз.'**
  String get auto_neUdalosZagruzitDannye;

  /// No description provided for @auto_netTovarovOtEtogoPost.
  ///
  /// In ru, this message translates to:
  /// **'Товары не найдены'**
  String get auto_netTovarovOtEtogoPost;

  /// No description provided for @auto_tovaryNeNaydeny.
  ///
  /// In ru, this message translates to:
  /// **'Товары не найдены'**
  String get auto_tovaryNeNaydeny;

  /// No description provided for @auto_poisk.
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get auto_poisk;

  /// No description provided for @auto_proizoshlaOshibka.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка'**
  String get auto_proizoshlaOshibka;

  /// No description provided for @auto_vernutsya.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться'**
  String get auto_vernutsya;

  /// No description provided for @auto_filtry.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get auto_filtry;

  /// No description provided for @auto_tsenaZaSht.
  ///
  /// In ru, this message translates to:
  /// **'Цена за шт.'**
  String get auto_tsenaZaSht;

  /// No description provided for @auto_ot.
  ///
  /// In ru, this message translates to:
  /// **'от'**
  String get auto_ot;

  /// No description provided for @auto_do.
  ///
  /// In ru, this message translates to:
  /// **'до'**
  String get auto_do;

  /// No description provided for @auto_sortirovka.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get auto_sortirovka;

  /// No description provided for @auto_reyting.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get auto_reyting;

  /// No description provided for @auto_poryadok.
  ///
  /// In ru, this message translates to:
  /// **'Порядок'**
  String get auto_poryadok;

  /// No description provided for @auto_poVozrastaniyu.
  ///
  /// In ru, this message translates to:
  /// **'По возрастанию'**
  String get auto_poVozrastaniyu;

  /// No description provided for @auto_poUbyvaniyu.
  ///
  /// In ru, this message translates to:
  /// **'По убыванию'**
  String get auto_poUbyvaniyu;

  /// No description provided for @auto_dobavitAdres.
  ///
  /// In ru, this message translates to:
  /// **'Добавить адрес'**
  String get auto_dobavitAdres;

  /// No description provided for @auto_adres.
  ///
  /// In ru, this message translates to:
  /// **'АДРЕС'**
  String get auto_adres;

  /// No description provided for @auto_ulitsa.
  ///
  /// In ru, this message translates to:
  /// **'УЛИЦА'**
  String get auto_ulitsa;

  /// No description provided for @auto_pochtovyyIndeks.
  ///
  /// In ru, this message translates to:
  /// **'ПОЧТОВЫЙ ИНДЕКС'**
  String get auto_pochtovyyIndeks;

  /// No description provided for @auto_kvartira.
  ///
  /// In ru, this message translates to:
  /// **'КВАРТИРА'**
  String get auto_kvartira;

  /// No description provided for @auto_dom.
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get auto_dom;

  /// No description provided for @auto_rabota.
  ///
  /// In ru, this message translates to:
  /// **'Работа'**
  String get auto_rabota;

  /// No description provided for @auto_drugoe.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get auto_drugoe;

  /// No description provided for @auto_sohranit.
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ'**
  String get auto_sohranit;

  /// No description provided for @auto_sohranitAdres.
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ АДРЕС'**
  String get auto_sohranitAdres;

  /// No description provided for @auto_vvediteAdres.
  ///
  /// In ru, this message translates to:
  /// **'Введите адрес'**
  String get auto_vvediteAdres;

  /// No description provided for @auto_adresSlishkomKorotkiy.
  ///
  /// In ru, this message translates to:
  /// **'Адрес слишком короткий'**
  String get auto_adresSlishkomKorotkiy;

  /// No description provided for @auto_ulitsa_1.
  ///
  /// In ru, this message translates to:
  /// **'Поле \"Улица\" не должно превышать {streetMaxLength} символов'**
  String auto_ulitsa_1(Object streetMaxLength);

  /// No description provided for @auto_indeksDolzhenSoderzhat.
  ///
  /// In ru, this message translates to:
  /// **'Индекс должен содержать только цифры (3-10)'**
  String get auto_indeksDolzhenSoderzhat;

  /// No description provided for @auto_kvartira_1.
  ///
  /// In ru, this message translates to:
  /// **'Поле \"Квартира\" не должно превышать {apartmentMaxLength} символов'**
  String auto_kvartira_1(Object apartmentMaxLength);

  /// No description provided for @auto_nekorrektnyyFormatKvart.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный формат квартиры'**
  String get auto_nekorrektnyyFormatKvart;

  /// No description provided for @auto_vvediteImyaVladeltsaKa.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя владельца карты'**
  String get auto_vvediteImyaVladeltsaKa;

  /// No description provided for @auto_imyaSlishkomKorotkoe.
  ///
  /// In ru, this message translates to:
  /// **'Имя слишком короткое'**
  String get auto_imyaSlishkomKorotkoe;

  /// No description provided for @auto_imyaNeDolzhnoSoderzhat.
  ///
  /// In ru, this message translates to:
  /// **'Имя не должно содержать цифры'**
  String get auto_imyaNeDolzhnoSoderzhat;

  /// No description provided for @auto_vvediteNomerKarty.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер карты'**
  String get auto_vvediteNomerKarty;

  /// No description provided for @auto_nomerKartyDolzhenByt1.
  ///
  /// In ru, this message translates to:
  /// **'Номер карты должен быть 16 цифр'**
  String get auto_nomerKartyDolzhenByt1;

  /// No description provided for @auto_nevernyyNomerKarty.
  ///
  /// In ru, this message translates to:
  /// **'Неверный номер карты'**
  String get auto_nevernyyNomerKarty;

  /// No description provided for @auto_vvediteSrokDeystviya.
  ///
  /// In ru, this message translates to:
  /// **'Введите срок действия'**
  String get auto_vvediteSrokDeystviya;

  /// No description provided for @auto_vvediteFormatMmgg.
  ///
  /// In ru, this message translates to:
  /// **'Введите формат ММ/ГГ'**
  String get auto_vvediteFormatMmgg;

  /// No description provided for @auto_mesyatsDolzhenByt0112.
  ///
  /// In ru, this message translates to:
  /// **'Месяц должен быть 01-12'**
  String get auto_mesyatsDolzhenByt0112;

  /// No description provided for @auto_srokDeystviyaIstyok.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия истёк'**
  String get auto_srokDeystviyaIstyok;

  /// No description provided for @auto_vvediteCvc.
  ///
  /// In ru, this message translates to:
  /// **'Введите CVC'**
  String get auto_vvediteCvc;

  /// No description provided for @auto_cvc3Tsifry.
  ///
  /// In ru, this message translates to:
  /// **'CVC: 3 цифры'**
  String get auto_cvc3Tsifry;

  /// No description provided for @auto_voyditeChtobyDobavitKa.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы добавить карту'**
  String get auto_voyditeChtobyDobavitKa;

  /// No description provided for @auto_proverteVvedyonnyeDanny.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте введённые данные'**
  String get auto_proverteVvedyonnyeDanny;

  /// No description provided for @auto_neUdalosSohranitKartu.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить карту'**
  String get auto_neUdalosSohranitKartu;

  /// No description provided for @auto_dobavitMetodOplaty.
  ///
  /// In ru, this message translates to:
  /// **'Добавить способ оплаты'**
  String get auto_dobavitMetodOplaty;

  /// No description provided for @auto_imyaVladeltsaKarty.
  ///
  /// In ru, this message translates to:
  /// **'ИМЯ ВЛАДЕЛЬЦА КАРТЫ'**
  String get auto_imyaVladeltsaKarty;

  /// No description provided for @auto_nomerKarty.
  ///
  /// In ru, this message translates to:
  /// **'НОМЕР КАРТЫ'**
  String get auto_nomerKarty;

  /// No description provided for @auto_srokDeystviya.
  ///
  /// In ru, this message translates to:
  /// **'СРОК ДЕЙСТВИЯ'**
  String get auto_srokDeystviya;

  /// No description provided for @auto_mmgg.
  ///
  /// In ru, this message translates to:
  /// **'ММ/ГГ'**
  String get auto_mmgg;

  /// No description provided for @auto_dobavitMetodOplaty_1.
  ///
  /// In ru, this message translates to:
  /// **'ДОБАВИТЬ СПОСОБ ОПЛАТЫ'**
  String get auto_dobavitMetodOplaty_1;

  /// No description provided for @auto_vvediteTekushchiyParol.
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get auto_vvediteTekushchiyParol;

  /// No description provided for @auto_vvediteNovyyParol.
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль'**
  String get auto_vvediteNovyyParol;

  /// No description provided for @auto_novyyParolDolzhenOtlic.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль должен отличаться от текущего'**
  String get auto_novyyParolDolzhenOtlic;

  /// No description provided for @auto_povtoriteNovyyParol.
  ///
  /// In ru, this message translates to:
  /// **'Повторите новый пароль'**
  String get auto_povtoriteNovyyParol;

  /// No description provided for @auto_paroliNeSovpadayut.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get auto_paroliNeSovpadayut;

  /// No description provided for @auto_neUdalosIzmenitParol.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить пароль'**
  String get auto_neUdalosIzmenitParol;

  /// No description provided for @auto_sessiyaIsteklaVoyditeS.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите снова.'**
  String get auto_sessiyaIsteklaVoyditeS;

  /// No description provided for @auto_izmenitParol.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get auto_izmenitParol;

  /// No description provided for @auto_tekushchiyParol.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get auto_tekushchiyParol;

  /// No description provided for @auto_novyyParol.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get auto_novyyParol;

  /// No description provided for @auto_vvediteParolEshchyoRaz.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль ещё раз'**
  String get auto_vvediteParolEshchyoRaz;

  /// No description provided for @auto_parolDolzhenSoderzhatM.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать минимум 6 символов и отличаться от текущего.'**
  String get auto_parolDolzhenSoderzhatM;

  /// No description provided for @auto_sohranitParol.
  ///
  /// In ru, this message translates to:
  /// **'СОХРАНИТЬ ПАРОЛЬ'**
  String get auto_sohranitParol;

  /// No description provided for @auto_ivanIvanov.
  ///
  /// In ru, this message translates to:
  /// **'Иван Иванов'**
  String get auto_ivanIvanov;

  /// No description provided for @auto_lyublyuSladosti.
  ///
  /// In ru, this message translates to:
  /// **'Люблю сладости'**
  String get auto_lyublyuSladosti;

  /// No description provided for @auto_sdelatSnimok.
  ///
  /// In ru, this message translates to:
  /// **'Сделать снимок'**
  String get auto_sdelatSnimok;

  /// No description provided for @auto_vybratIzGalerei.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get auto_vybratIzGalerei;

  /// No description provided for @auto_udalitFoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get auto_udalitFoto;

  /// No description provided for @auto_razmerFaylaNeDolzhenP.
  ///
  /// In ru, this message translates to:
  /// **'Размер файла не должен превышать 5 МБ'**
  String get auto_razmerFaylaNeDolzhenP;

  /// No description provided for @auto_redProfil.
  ///
  /// In ru, this message translates to:
  /// **'Ред. Профиль'**
  String get auto_redProfil;

  /// No description provided for @auto_fio.
  ///
  /// In ru, this message translates to:
  /// **'ФИО'**
  String get auto_fio;

  /// No description provided for @auto_elPochta.
  ///
  /// In ru, this message translates to:
  /// **'ЭЛ. ПОЧТА'**
  String get auto_elPochta;

  /// No description provided for @auto_nomer.
  ///
  /// In ru, this message translates to:
  /// **'НОМЕР'**
  String get auto_nomer;

  /// No description provided for @auto_opisanie.
  ///
  /// In ru, this message translates to:
  /// **'ОПИСАНИЕ'**
  String get auto_opisanie;

  /// No description provided for @auto_nomerDolzhenBytVForma.
  ///
  /// In ru, this message translates to:
  /// **'Номер должен быть в формате +7-XXX-XXX-XXXX'**
  String get auto_nomerDolzhenBytVForma;

  /// No description provided for @auto_kakSdelatZakaz.
  ///
  /// In ru, this message translates to:
  /// **'Как сделать заказ?'**
  String get auto_kakSdelatZakaz;

  /// No description provided for @auto_chtobySdelatZakazVyber.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы сделать заказ, выберите товары из каталога, добавьте их в корзину и оформите заказ, указав адрес доставки и способ оплаты.'**
  String get auto_chtobySdelatZakazVyber;

  /// No description provided for @auto_kakieSposobyOplatyDost.
  ///
  /// In ru, this message translates to:
  /// **'Какие способы оплаты доступны?'**
  String get auto_kakieSposobyOplatyDost;

  /// No description provided for @auto_myPrinimaemOplatuNalic.
  ///
  /// In ru, this message translates to:
  /// **'Мы принимаем оплату наличными, банковскими картами (Visa, Mastercard), а также через PayPal.'**
  String get auto_myPrinimaemOplatuNalic;

  /// No description provided for @auto_skolkoVremeniZanimaetD.
  ///
  /// In ru, this message translates to:
  /// **'Сколько времени занимает доставка?'**
  String get auto_skolkoVremeniZanimaetD;

  /// No description provided for @auto_standartnayaDostavkaZan.
  ///
  /// In ru, this message translates to:
  /// **'Стандартная доставка занимает 1-3 рабочих дня. Экспресс-доставка доступна в течение 24 часов.'**
  String get auto_standartnayaDostavkaZan;

  /// No description provided for @auto_moguLiYaOtmenitZakaz.
  ///
  /// In ru, this message translates to:
  /// **'Могу ли я отменить заказ?'**
  String get auto_moguLiYaOtmenitZakaz;

  /// No description provided for @auto_vyMozheteOtmenitZakaz.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете отменить заказ в течение 30 минут после оформления. После этого заказ уже будет передан на склад для сборки.'**
  String get auto_vyMozheteOtmenitZakaz;

  /// No description provided for @auto_kakIzmenitAdresDostavk.
  ///
  /// In ru, this message translates to:
  /// **'Как изменить адрес доставки?'**
  String get auto_kakIzmenitAdresDostavk;

  /// No description provided for @auto_profil.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get auto_profil;

  /// No description provided for @auto_adresa.
  ///
  /// In ru, this message translates to:
  /// **'Адреса'**
  String get auto_adresa;

  /// No description provided for @auto_takzheMozhnoUkazatNov.
  ///
  /// In ru, this message translates to:
  /// **'Также можно указать новый адрес при оформлении заказа.'**
  String get auto_takzheMozhnoUkazatNov;

  /// No description provided for @auto_chtoDelatEsliTovarNe.
  ///
  /// In ru, this message translates to:
  /// **'Что делать если товар не подошел?'**
  String get auto_chtoDelatEsliTovarNe;

  /// No description provided for @auto_vyMozheteVernutTovarV.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете вернуть товар в течение 14 дней с момента получения. Свяжитесь с нашей службой поддержки для оформления возврата.'**
  String get auto_vyMozheteVernutTovarV;

  /// No description provided for @auto_kakSvyazatsyaSPodderzh.
  ///
  /// In ru, this message translates to:
  /// **'Как связаться с поддержкой?'**
  String get auto_kakSvyazatsyaSPodderzh;

  /// No description provided for @auto_tehpodderzhka.
  ///
  /// In ru, this message translates to:
  /// **'Техподдержка'**
  String get auto_tehpodderzhka;

  /// No description provided for @auto_vPrilozheniiPoElektro.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете связаться с нами через раздел \"Техподдержка\" в приложении, по электронной почте или по телефону горячей линии.'**
  String get auto_vPrilozheniiPoElektro;

  /// No description provided for @auto_estLiMinimalnayaSumma.
  ///
  /// In ru, this message translates to:
  /// **'Есть ли минимальная сумма заказа?'**
  String get auto_estLiMinimalnayaSumma;

  /// No description provided for @auto_minimalnayaSummaZakaza.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная сумма заказа составляет 500. При заказе от 5000 доставка бесплатная.'**
  String get auto_minimalnayaSummaZakaza;

  /// No description provided for @auto_voprosyIOtvety.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы и ответы'**
  String get auto_voprosyIOtvety;

  /// No description provided for @auto_izbrannoe.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get auto_izbrannoe;

  /// No description provided for @auto_vkladkaIzbrannyeTovary.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get auto_vkladkaIzbrannyeTovary;

  /// No description provided for @auto_vkladkaIzbrannyeKompani.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get auto_vkladkaIzbrannyeKompani;

  /// No description provided for @auto_pokaNetIzbrannyhTovaro.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет избранных товаров'**
  String get auto_pokaNetIzbrannyhTovaro;

  /// No description provided for @auto_netIzbrannyhKompaniy.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных компаний'**
  String get auto_netIzbrannyhKompaniy;

  /// No description provided for @auto_neUdalosZagruzitAdresa.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить адреса'**
  String get auto_neUdalosZagruzitAdresa;

  /// No description provided for @auto_nuzhnoVoytiVAkkaunt.
  ///
  /// In ru, this message translates to:
  /// **'Нужно войти в аккаунт'**
  String get auto_nuzhnoVoytiVAkkaunt;

  /// No description provided for @auto_neUdalosUdalitAdres.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить адрес'**
  String get auto_neUdalosUdalitAdres;

  /// No description provided for @auto_moiAdresa.
  ///
  /// In ru, this message translates to:
  /// **'Мои адреса'**
  String get auto_moiAdresa;

  /// No description provided for @auto_dobavteAdresChtobyOfor.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте адрес, чтобы оформить заказ быстрее.'**
  String get auto_dobavteAdresChtobyOfor;

  /// No description provided for @auto_redaktirovat.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get auto_redaktirovat;

  /// No description provided for @auto_udalitAdres.
  ///
  /// In ru, this message translates to:
  /// **'Удалить адрес?'**
  String get auto_udalitAdres;

  /// No description provided for @auto_kartaDobavlena.
  ///
  /// In ru, this message translates to:
  /// **'Карта добавлена'**
  String get auto_kartaDobavlena;

  /// No description provided for @auto_metodOplaty.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get auto_metodOplaty;

  /// No description provided for @auto_nalichnye.
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get auto_nalichnye;

  /// No description provided for @auto_dobavitNovyy.
  ///
  /// In ru, this message translates to:
  /// **'Добавить новый'**
  String get auto_dobavitNovyy;

  /// No description provided for @auto_netKartVisa.
  ///
  /// In ru, this message translates to:
  /// **'Нет карт Visa'**
  String get auto_netKartVisa;

  /// No description provided for @auto_netKartMastercard.
  ///
  /// In ru, this message translates to:
  /// **'Нет карт Mastercard'**
  String get auto_netKartMastercard;

  /// No description provided for @auto_dobavteKartuVisaChtoby.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте карту Visa, чтобы выбрать этот способ оплаты.'**
  String get auto_dobavteKartuVisaChtoby;

  /// No description provided for @auto_dobavteKartuMastercard.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте карту Mastercard, чтобы выбрать этот способ оплаты.'**
  String get auto_dobavteKartuMastercard;

  /// No description provided for @auto_vashiKartyVisa.
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты Visa'**
  String get auto_vashiKartyVisa;

  /// No description provided for @auto_vashiKartyMastercard.
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты Mastercard'**
  String get auto_vashiKartyMastercard;

  /// No description provided for @auto_vashiKarty.
  ///
  /// In ru, this message translates to:
  /// **'Ваши карты'**
  String get auto_vashiKarty;

  /// No description provided for @auto_oplataNalichnymi.
  ///
  /// In ru, this message translates to:
  /// **'Оплата наличными'**
  String get auto_oplataNalichnymi;

  /// No description provided for @auto_vyVybraliOplatuNalichn.
  ///
  /// In ru, this message translates to:
  /// **'Вы выбрали оплату наличными при получении.'**
  String get auto_vyVybraliOplatuNalichn;

  /// No description provided for @auto_podklyucheniePaypalPoka.
  ///
  /// In ru, this message translates to:
  /// **'Подключение PayPal пока недоступно.\\nВыберите карту или наличные.'**
  String get auto_podklyucheniePaypalPoka;

  /// No description provided for @auto_netSposobaOplaty.
  ///
  /// In ru, this message translates to:
  /// **'Нет способа оплаты'**
  String get auto_netSposobaOplaty;

  /// No description provided for @auto_pozhaluystaVyberiteSpos.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, выберите способ\\nоплаты'**
  String get auto_pozhaluystaVyberiteSpos;

  /// No description provided for @auto_udalitKartu.
  ///
  /// In ru, this message translates to:
  /// **'Удалить карту'**
  String get auto_udalitKartu;

  /// No description provided for @auto_kartaUdalena.
  ///
  /// In ru, this message translates to:
  /// **'Карта удалена'**
  String get auto_kartaUdalena;

  /// No description provided for @auto_neUkazano.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get auto_neUkazano;

  /// No description provided for @auto_vvediteNomerTelefona.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get auto_vvediteNomerTelefona;

  /// No description provided for @auto_nomerDolzhenBytVForma_1.
  ///
  /// In ru, this message translates to:
  /// **'Номер должен быть в формате +7-000-000-0000'**
  String get auto_nomerDolzhenBytVForma_1;

  /// No description provided for @auto_imyaSohraneno.
  ///
  /// In ru, this message translates to:
  /// **'Имя сохранено'**
  String get auto_imyaSohraneno;

  /// No description provided for @auto_emailSohranen.
  ///
  /// In ru, this message translates to:
  /// **'Email сохранен'**
  String get auto_emailSohranen;

  /// No description provided for @auto_nomerSohranen.
  ///
  /// In ru, this message translates to:
  /// **'Номер сохранен'**
  String get auto_nomerSohranen;

  /// No description provided for @auto_vvediteNazvanieKompanii.
  ///
  /// In ru, this message translates to:
  /// **'Введите название компании'**
  String get auto_vvediteNazvanieKompanii;

  /// No description provided for @auto_nazvanieKompaniiSohrane.
  ///
  /// In ru, this message translates to:
  /// **'Название компании сохранено'**
  String get auto_nazvanieKompaniiSohrane;

  /// No description provided for @auto_lichnayaInformatsiya.
  ///
  /// In ru, this message translates to:
  /// **'Личная информация'**
  String get auto_lichnayaInformatsiya;

  /// No description provided for @auto_nazvanieKompanii.
  ///
  /// In ru, this message translates to:
  /// **'НАЗВАНИЕ КОМПАНИИ'**
  String get auto_nazvanieKompanii;

  /// No description provided for @auto_vvediteNovoeZnachenie.
  ///
  /// In ru, this message translates to:
  /// **'Введите новое значение'**
  String get auto_vvediteNovoeZnachenie;

  /// No description provided for @auto_sohranit_1.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get auto_sohranit_1;

  /// No description provided for @auto_nastroyki.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get auto_nastroyki;

  /// No description provided for @auto_vyyti.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get auto_vyyti;

  /// No description provided for @auto_moiZakazy.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get auto_moiZakazy;

  /// No description provided for @auto_sposobOplaty.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get auto_sposobOplaty;

  /// No description provided for @auto_vashiOtzyvy.
  ///
  /// In ru, this message translates to:
  /// **'Ваши отзывы'**
  String get auto_vashiOtzyvy;

  /// No description provided for @auto_bystrayaDostavka.
  ///
  /// In ru, this message translates to:
  /// **'Быстрая доставка'**
  String get auto_bystrayaDostavka;

  /// No description provided for @auto_horoshayaTsena.
  ///
  /// In ru, this message translates to:
  /// **'Хорошая цена'**
  String get auto_horoshayaTsena;

  /// No description provided for @auto_kachestvennayaUpakovka.
  ///
  /// In ru, this message translates to:
  /// **'Качественная упаковка'**
  String get auto_kachestvennayaUpakovka;

  /// No description provided for @auto_svezhiyTovar.
  ///
  /// In ru, this message translates to:
  /// **'Свежий товар'**
  String get auto_svezhiyTovar;

  /// No description provided for @auto_vezhlivyyKurer.
  ///
  /// In ru, this message translates to:
  /// **'Вежливый курьер'**
  String get auto_vezhlivyyKurer;

  /// No description provided for @auto_voyditeChtobyUvidetOtz.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы увидеть отзывы.'**
  String get auto_voyditeChtobyUvidetOtz;

  /// No description provided for @auto_neUdalosZagruzitOtzyvy.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отзывы.'**
  String get auto_neUdalosZagruzitOtzyvy;

  /// No description provided for @auto_estPokupkiDlyaOtsenki.
  ///
  /// In ru, this message translates to:
  /// **'Есть покупки для оценки'**
  String get auto_estPokupkiDlyaOtsenki;

  /// No description provided for @auto_vseOtzyvyOPokupkah.
  ///
  /// In ru, this message translates to:
  /// **'Все отзывы о покупках'**
  String get auto_vseOtzyvyOPokupkah;

  /// No description provided for @auto_ozhidayutOtzyvov.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают отзывов'**
  String get auto_ozhidayutOtzyvov;

  /// No description provided for @auto_otsenitePokupkiEtoPomo.
  ///
  /// In ru, this message translates to:
  /// **'Оцените покупки - это помогает другим'**
  String get auto_otsenitePokupkiEtoPomo;

  /// No description provided for @auto_ostavitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get auto_ostavitOtzyv;

  /// No description provided for @auto_ostavteOtzyvPoslePriny.
  ///
  /// In ru, this message translates to:
  /// **'Оставьте отзыв после принятия заказа - он появится здесь.'**
  String get auto_ostavteOtzyvPoslePriny;

  /// No description provided for @auto_tekstOtzyva.
  ///
  /// In ru, this message translates to:
  /// **'Текст отзыва'**
  String get auto_tekstOtzyva;

  /// No description provided for @auto_bezTekstaOtzyva.
  ///
  /// In ru, this message translates to:
  /// **'Без текста отзыва'**
  String get auto_bezTekstaOtzyva;

  /// No description provided for @auto_otseniteTovar.
  ///
  /// In ru, this message translates to:
  /// **'Оцените товар'**
  String get auto_otseniteTovar;

  /// No description provided for @auto_vashOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Ваш отзыв'**
  String get auto_vashOtzyv;

  /// No description provided for @auto_podelitesVpechatleniyami.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь впечатлениями'**
  String get auto_podelitesVpechatleniyami;

  /// No description provided for @auto_izmenit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get auto_izmenit;

  /// No description provided for @auto_voyditeChtobyRedaktirov.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы редактировать отзыв'**
  String get auto_voyditeChtobyRedaktirov;

  /// No description provided for @auto_otzyvObnovlen.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв обновлен'**
  String get auto_otzyvObnovlen;

  /// No description provided for @auto_neUdalosSohranitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить отзыв'**
  String get auto_neUdalosSohranitOtzyv;

  /// No description provided for @auto_postavteOtsenku.
  ///
  /// In ru, this message translates to:
  /// **'Поставьте оценку'**
  String get auto_postavteOtsenku;

  /// No description provided for @auto_dobavteDetali.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте детали'**
  String get auto_dobavteDetali;

  /// No description provided for @auto_otpravitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get auto_otpravitOtzyv;

  /// No description provided for @auto_voyditeChtobyOstavitOt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы оставить отзыв'**
  String get auto_voyditeChtobyOstavitOt;

  /// No description provided for @auto_spasiboZaOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за отзыв!'**
  String get auto_spasiboZaOtzyv;

  /// No description provided for @auto_neUdalosOtpravitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить отзыв'**
  String get auto_neUdalosOtpravitOtzyv;

  /// No description provided for @auto_voyditeChtobyUdalitOtz.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы удалить отзыв'**
  String get auto_voyditeChtobyUdalitOtz;

  /// No description provided for @auto_otzyvUdalen.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв удален'**
  String get auto_otzyvUdalen;

  /// No description provided for @auto_neUdalosUdalitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить отзыв'**
  String get auto_neUdalosUdalitOtzyv;

  /// No description provided for @auto_udalitOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв?'**
  String get auto_udalitOtzyv;

  /// No description provided for @auto_etoDeystvieNelzyaOtmen.
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить.'**
  String get auto_etoDeystvieNelzyaOtmen;

  /// No description provided for @auto_rezervnyeKodyDvuhfaktor.
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды двухфакторной аутентификации'**
  String get auto_rezervnyeKodyDvuhfaktor;

  /// No description provided for @auto_sohraniteIhVNadyozhnom.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните их в надёжном месте - каждый код можно использовать только один раз.\\n'**
  String get auto_sohraniteIhVNadyozhnom;

  /// No description provided for @auto_kodySkopirovanyVBufer.
  ///
  /// In ru, this message translates to:
  /// **'Коды скопированы в буфер обмена'**
  String get auto_kodySkopirovanyVBufer;

  /// No description provided for @auto_faylSKodamiSohranyon.
  ///
  /// In ru, this message translates to:
  /// **'Файл с кодами сохранён'**
  String get auto_faylSKodamiSohranyon;

  /// No description provided for @auto_rezervnyeKody.
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды'**
  String get auto_rezervnyeKody;

  /// No description provided for @auto_rezervnyeKodyDvuhfaktor_1.
  ///
  /// In ru, this message translates to:
  /// **'Резервные коды двухфакторной аутентификации'**
  String get auto_rezervnyeKodyDvuhfaktor_1;

  /// No description provided for @auto_sohraniteKodyVBezopasn.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните коды в безопасном месте — они показываются один раз. Каждый код можно использовать только однократно для входа, если потерян доступ к почте.'**
  String get auto_sohraniteKodyVBezopasn;

  /// No description provided for @auto_gotovo.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get auto_gotovo;

  /// No description provided for @auto_neUdalosOtpravitKodPo.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить код. Попробуйте ещё раз.'**
  String get auto_neUdalosOtpravitKodPo;

  /// No description provided for @auto_dvuhfaktornayaAutentifik.
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация отключена'**
  String get auto_dvuhfaktornayaAutentifik;

  /// No description provided for @auto_nevernyyKod.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get auto_nevernyyKod;

  /// No description provided for @auto_oshibkaPodklyucheniyaK.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения к серверу'**
  String get auto_oshibkaPodklyucheniyaK;

  /// No description provided for @auto_kodOtpravlenPovtorno.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен повторно'**
  String get auto_kodOtpravlenPovtorno;

  /// No description provided for @auto_neUdalosOtpravitKodPo_1.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить код повторно'**
  String get auto_neUdalosOtpravitKodPo_1;

  /// No description provided for @auto_vyklyuchenie2fa.
  ///
  /// In ru, this message translates to:
  /// **'Выключение 2FA'**
  String get auto_vyklyuchenie2fa;

  /// No description provided for @auto_podtverzhdeniePoPochte.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение по почте'**
  String get auto_podtverzhdeniePoPochte;

  /// No description provided for @auto_chtobyVyklyuchitDvuhfak.
  ///
  /// In ru, this message translates to:
  /// **'чтобы выключить двухфакторную аутентификацию.'**
  String get auto_chtobyVyklyuchitDvuhfak;

  /// No description provided for @auto_povtoritOtpravku.
  ///
  /// In ru, this message translates to:
  /// **'Повторить отправку'**
  String get auto_povtoritOtpravku;

  /// No description provided for @auto_srokDeystviyaKodaIstyo.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия кода истёк, отправьте повторно'**
  String get auto_srokDeystviyaKodaIstyo;

  /// No description provided for @auto_srokIstyok.
  ///
  /// In ru, this message translates to:
  /// **'КОД ДЕЙСТВИТЕЛЕН {ttlSecondsLeft} СЕК'**
  String auto_srokIstyok(Object ttlSecondsLeft);

  /// No description provided for @auto_otpravitPovtorno.
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно'**
  String get auto_otpravitPovtorno;

  /// No description provided for @auto_vklyuchenie2fa.
  ///
  /// In ru, this message translates to:
  /// **'Включение 2FA'**
  String get auto_vklyuchenie2fa;

  /// No description provided for @auto_chtobyVklyuchitDvuhfakt.
  ///
  /// In ru, this message translates to:
  /// **'чтобы включить двухфакторную аутентификацию.'**
  String get auto_chtobyVklyuchitDvuhfakt;

  /// No description provided for @auto_neUdalosZagruzitStatus.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить статус двухфакторной аутентификации'**
  String get auto_neUdalosZagruzitStatus;

  /// No description provided for @auto_regeneratsiyaBackupkodov.
  ///
  /// In ru, this message translates to:
  /// **'Регенерация backup-кодов'**
  String get auto_regeneratsiyaBackupkodov;

  /// No description provided for @auto_chtobyZamenitTekushchie.
  ///
  /// In ru, this message translates to:
  /// **'чтобы заменить текущие резервные коды.'**
  String get auto_chtobyZamenitTekushchie;

  /// No description provided for @auto_neUdalosSgenerirovatNo.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать новые коды'**
  String get auto_neUdalosSgenerirovatNo;

  /// No description provided for @auto_otzyvDoverennyhUstroyst.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв доверенных устройств'**
  String get auto_otzyvDoverennyhUstroyst;

  /// No description provided for @auto_chtobyOtozvatVseRanee.
  ///
  /// In ru, this message translates to:
  /// **'чтобы отозвать все ранее запомненные устройства.'**
  String get auto_chtobyOtozvatVseRanee;

  /// No description provided for @auto_doverennyeUstroystvaOto.
  ///
  /// In ru, this message translates to:
  /// **'Доверенные устройства отозваны'**
  String get auto_doverennyeUstroystvaOto;

  /// No description provided for @auto_neUdalosOtozvatUstroys.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отозвать устройства'**
  String get auto_neUdalosOtozvatUstroys;

  /// No description provided for @auto_dvuhfaktornayaAutentifik_1.
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная аутентификация'**
  String get auto_dvuhfaktornayaAutentifik_1;

  /// No description provided for @auto_ostalosMaloRezervnyhKo.
  ///
  /// In ru, this message translates to:
  /// **'Осталось мало резервных кодов, сгенерируйте новые'**
  String get auto_ostalosMaloRezervnyhKo;

  /// No description provided for @auto_vklyuchenaPriVhodePotr.
  ///
  /// In ru, this message translates to:
  /// **'Включена. При входе потребуется код.'**
  String get auto_vklyuchenaPriVhodePotr;

  /// No description provided for @auto_vyklyuchenaZashchititeA.
  ///
  /// In ru, this message translates to:
  /// **'Выключена. Защитите аккаунт дополнительным кодом.'**
  String get auto_vyklyuchenaZashchititeA;

  /// No description provided for @auto_sgenerirovatNovyeBackup.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать новые backup коды'**
  String get auto_sgenerirovatNovyeBackup;

  /// No description provided for @auto_staryeKodyBudutUdaleny.
  ///
  /// In ru, this message translates to:
  /// **'Старые коды будут удалены'**
  String get auto_staryeKodyBudutUdaleny;

  /// No description provided for @auto_otozvatDoverennyeUstroy.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать доверенные устройства'**
  String get auto_otozvatDoverennyeUstroy;

  /// No description provided for @auto_naVsehUstroystvahPotre.
  ///
  /// In ru, this message translates to:
  /// **'На всех устройствах потребуется код заново'**
  String get auto_naVsehUstroystvahPotre;

  /// No description provided for @auto_neUdalosOpredelitPolzo.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить пользователя'**
  String get auto_neUdalosOpredelitPolzo;

  /// No description provided for @auto_neUdalosZagruzitChat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чат'**
  String get auto_neUdalosZagruzitChat;

  /// No description provided for @auto_chatZakrytSozdayteNovo.
  ///
  /// In ru, this message translates to:
  /// **'Чат закрыт. Создайте новое обращение.'**
  String get auto_chatZakrytSozdayteNovo;

  /// No description provided for @auto_chatSTehpodderzhkoy.
  ///
  /// In ru, this message translates to:
  /// **'Чат с техподдержкой'**
  String get auto_chatSTehpodderzhkoy;

  /// No description provided for @auto_aktivnogoChataNetSnach.
  ///
  /// In ru, this message translates to:
  /// **'Активного чата нет. Сначала начните диалог.'**
  String get auto_aktivnogoChataNetSnach;

  /// No description provided for @auto_chatNeNayden.
  ///
  /// In ru, this message translates to:
  /// **'Чат не найден.'**
  String get auto_chatNeNayden;

  /// No description provided for @auto_podderzhka.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get auto_podderzhka;

  /// No description provided for @auto_chatOtkrytTehpodderzhka.
  ///
  /// In ru, this message translates to:
  /// **'Чат открыт. Техподдержка ответит в этом окне.'**
  String get auto_chatOtkrytTehpodderzhka;

  /// No description provided for @auto_operatoryOnlaynObychno.
  ///
  /// In ru, this message translates to:
  /// **'Операторы онлайн. Обычно отвечают быстро.'**
  String get auto_operatoryOnlaynObychno;

  /// No description provided for @auto_seychasOflaynOtvetimV.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас офлайн. Ответим в рабочее время.'**
  String get auto_seychasOflaynOtvetimV;

  /// No description provided for @auto_opishiteProblemu.
  ///
  /// In ru, this message translates to:
  /// **'Опишите проблему'**
  String get auto_opishiteProblemu;

  /// No description provided for @auto_problemaSZakazom.
  ///
  /// In ru, this message translates to:
  /// **'Проблема с заказом'**
  String get auto_problemaSZakazom;

  /// No description provided for @auto_problemaSOplatoy.
  ///
  /// In ru, this message translates to:
  /// **'Проблема с оплатой'**
  String get auto_problemaSOplatoy;

  /// No description provided for @auto_tehnicheskieNepoladki.
  ///
  /// In ru, this message translates to:
  /// **'Технические неполадки'**
  String get auto_tehnicheskieNepoladki;

  /// No description provided for @auto_voprosOTovare.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос о товаре'**
  String get auto_voprosOTovare;

  /// No description provided for @auto_neUdalosZagruzitObrash.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить обращение'**
  String get auto_neUdalosZagruzitObrash;

  /// No description provided for @auto_obrashchenieOtpravlenoV.
  ///
  /// In ru, this message translates to:
  /// **'Обращение отправлено в поддержку'**
  String get auto_obrashchenieOtpravlenoV;

  /// No description provided for @auto_soobshchenieOtpravleno.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение отправлено'**
  String get auto_soobshchenieOtpravleno;

  /// No description provided for @auto_neUdalosOtpravitObrash.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось Отправить обращение'**
  String get auto_neUdalosOtpravitObrash;

  /// No description provided for @auto_svyazhitesSNami.
  ///
  /// In ru, this message translates to:
  /// **'Свяжитесь с нами'**
  String get auto_svyazhitesSNami;

  /// No description provided for @auto_pnvs09002100Utc5.
  ///
  /// In ru, this message translates to:
  /// **'Пн-Вс: 09:00 - 21:00 (UTC+5)'**
  String get auto_pnvs09002100Utc5;

  /// No description provided for @auto_prodolzhitObrashchenie.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить обращение'**
  String get auto_prodolzhitObrashchenie;

  /// No description provided for @auto_otpravitObrashchenie.
  ///
  /// In ru, this message translates to:
  /// **'Отправить обращение'**
  String get auto_otpravitObrashchenie;

  /// No description provided for @auto_aktivnyyChatOtkryt.
  ///
  /// In ru, this message translates to:
  /// **'Активный чат открыт'**
  String get auto_aktivnyyChatOtkryt;

  /// No description provided for @auto_predydushcheeObrashcheni.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее обращение закрыто. Если вопрос актуален, отправьте новое.'**
  String get auto_predydushcheeObrashcheni;

  /// No description provided for @auto_otkrytChatSTehpodderzh.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чат с техподдержкой'**
  String get auto_otkrytChatSTehpodderzh;

  /// No description provided for @auto_kategoriyaObrashcheniya.
  ///
  /// In ru, this message translates to:
  /// **'Категория обращения'**
  String get auto_kategoriyaObrashcheniya;

  /// No description provided for @auto_vyberiteKategoriyu.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get auto_vyberiteKategoriyu;

  /// No description provided for @auto_temaObrashcheniya.
  ///
  /// In ru, this message translates to:
  /// **'Тема обращения'**
  String get auto_temaObrashcheniya;

  /// No description provided for @auto_vvediteTemu.
  ///
  /// In ru, this message translates to:
  /// **'Введите тему'**
  String get auto_vvediteTemu;

  /// No description provided for @auto_soobshchenie.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get auto_soobshchenie;

  /// No description provided for @auto_vPuti.
  ///
  /// In ru, this message translates to:
  /// **'в пути'**
  String get auto_vPuti;

  /// No description provided for @auto_sobira.
  ///
  /// In ru, this message translates to:
  /// **'собира'**
  String get auto_sobira;

  /// No description provided for @auto_dostav.
  ///
  /// In ru, this message translates to:
  /// **'Доставлен'**
  String get auto_dostav;

  /// No description provided for @auto_oshibkaOperatsii.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка операции'**
  String get auto_oshibkaOperatsii;

  /// No description provided for @auto_tovarSnyatSPublikatsii_1.
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get auto_tovarSnyatSPublikatsii_1;

  /// No description provided for @auto_tovarUdalyon.
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get auto_tovarUdalyon;

  /// No description provided for @auto_minPartiya.
  ///
  /// In ru, this message translates to:
  /// **'Мин. партия:'**
  String get auto_minPartiya;

  /// No description provided for @auto_ostatok.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get auto_ostatok;

  /// No description provided for @auto_pokaNetTovarov.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет товаров'**
  String get auto_pokaNetTovarov;

  /// No description provided for @auto_dobavtePervyyTovarIOt.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первый товар и отправьте его на модерацию.'**
  String get auto_dobavtePervyyTovarIOt;

  /// No description provided for @auto_dobavitTovar.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар'**
  String get auto_dobavitTovar;

  /// No description provided for @auto_ponedelnik_1.
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get auto_ponedelnik_1;

  /// No description provided for @auto_vtornik_1.
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get auto_vtornik_1;

  /// No description provided for @auto_sreda_1.
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get auto_sreda_1;

  /// No description provided for @auto_chetverg_1.
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get auto_chetverg_1;

  /// No description provided for @auto_pyatnitsa_1.
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get auto_pyatnitsa_1;

  /// No description provided for @auto_subbota_1.
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get auto_subbota_1;

  /// No description provided for @auto_voskresene_1.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get auto_voskresene_1;

  /// No description provided for @auto_molochnayaProduktsiya.
  ///
  /// In ru, this message translates to:
  /// **'Молочная продукция'**
  String get auto_molochnayaProduktsiya;

  /// No description provided for @auto_ovoshchiIFrukty.
  ///
  /// In ru, this message translates to:
  /// **'Овощи и фрукты'**
  String get auto_ovoshchiIFrukty;

  /// No description provided for @auto_myasoIPtitsa.
  ///
  /// In ru, this message translates to:
  /// **'Мясо и птица'**
  String get auto_myasoIPtitsa;

  /// No description provided for @auto_bakaleya.
  ///
  /// In ru, this message translates to:
  /// **'Бакалея'**
  String get auto_bakaleya;

  /// No description provided for @auto_hlebIVypechka.
  ///
  /// In ru, this message translates to:
  /// **'Хлеб и выпечка'**
  String get auto_hlebIVypechka;

  /// No description provided for @auto_zamorozka.
  ///
  /// In ru, this message translates to:
  /// **'Заморозка'**
  String get auto_zamorozka;

  /// No description provided for @auto_sneki.
  ///
  /// In ru, this message translates to:
  /// **'Снеки'**
  String get auto_sneki;

  /// No description provided for @auto_bytovayaHimiya.
  ///
  /// In ru, this message translates to:
  /// **'Бытовая химия'**
  String get auto_bytovayaHimiya;

  /// No description provided for @auto_tovaryDlyaDoma.
  ///
  /// In ru, this message translates to:
  /// **'Товары для дома'**
  String get auto_tovaryDlyaDoma;

  /// No description provided for @auto_stranaProizvoditelya.
  ///
  /// In ru, this message translates to:
  /// **'Страна производителя'**
  String get auto_stranaProizvoditelya;

  /// No description provided for @auto_srokGodnosti.
  ///
  /// In ru, this message translates to:
  /// **'Срок годности'**
  String get auto_srokGodnosti;

  /// No description provided for @auto_vvediteNazvanieTovara.
  ///
  /// In ru, this message translates to:
  /// **'Введите название товара'**
  String get auto_vvediteNazvanieTovara;

  /// No description provided for @auto_ukazhiteSrokGodnosti.
  ///
  /// In ru, this message translates to:
  /// **'Укажите срок годности'**
  String get auto_ukazhiteSrokGodnosti;

  /// No description provided for @auto_vyberiteKategoriyuIzSp.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию из списка'**
  String get auto_vyberiteKategoriyuIzSp;

  /// No description provided for @auto_vvediteKorrektnuyuTsenu.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректную цену'**
  String get auto_vvediteKorrektnuyuTsenu;

  /// No description provided for @auto_minimalnoeKolichestvoDo.
  ///
  /// In ru, this message translates to:
  /// **'Минимальное количество должно быть больше 0'**
  String get auto_minimalnoeKolichestvoDo;

  /// No description provided for @auto_ukazhiteOstatokNaSklad.
  ///
  /// In ru, this message translates to:
  /// **'Укажите остаток на складе'**
  String get auto_ukazhiteOstatokNaSklad;

  /// No description provided for @auto_ostatokNeMozhetBytMen.
  ///
  /// In ru, this message translates to:
  /// **'Остаток не может быть меньше минимальной партии'**
  String get auto_ostatokNeMozhetBytMen;

  /// No description provided for @auto_vvediteVremyaDostavkiV.
  ///
  /// In ru, this message translates to:
  /// **'Введите время доставки в формате ЧЧ:ММ'**
  String get auto_vvediteVremyaDostavkiV;

  /// No description provided for @auto_ukazhiteGrafikDostavki.
  ///
  /// In ru, this message translates to:
  /// **'Укажите график доставки'**
  String get auto_ukazhiteGrafikDostavki;

  /// No description provided for @auto_vvediteMinimalnyySrokD.
  ///
  /// In ru, this message translates to:
  /// **'Введите минимальный срок доставки'**
  String get auto_vvediteMinimalnyySrokD;

  /// No description provided for @auto_maksimalnyySrokNeMozhe.
  ///
  /// In ru, this message translates to:
  /// **'Максимальный срок не может быть меньше минимального'**
  String get auto_maksimalnyySrokNeMozhe;

  /// No description provided for @auto_srokDostavkiSlishkomBo.
  ///
  /// In ru, this message translates to:
  /// **'Срок доставки слишком большой'**
  String get auto_srokDostavkiSlishkomBo;

  /// No description provided for @auto_vvediteVremyaOtsechkiV.
  ///
  /// In ru, this message translates to:
  /// **'Введите время отсечки в формате ЧЧ:ММ'**
  String get auto_vvediteVremyaOtsechkiV;

  /// No description provided for @auto_kaloriiDolzhnyBytNeotr.
  ///
  /// In ru, this message translates to:
  /// **'Калории должны быть неотрицательным числом'**
  String get auto_kaloriiDolzhnyBytNeotr;

  /// No description provided for @auto_belkiDolzhnyBytNeotrit.
  ///
  /// In ru, this message translates to:
  /// **'Белки должны быть неотрицательным числом'**
  String get auto_belkiDolzhnyBytNeotrit;

  /// No description provided for @auto_zhiryDolzhnyBytNeotrit.
  ///
  /// In ru, this message translates to:
  /// **'Жиры должны быть неотрицательным числом'**
  String get auto_zhiryDolzhnyBytNeotrit;

  /// No description provided for @auto_uglevodyDolzhnyBytNeot.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы должны быть неотрицательным числом'**
  String get auto_uglevodyDolzhnyBytNeot;

  /// No description provided for @auto_dobavteHotyaByOdnuFot.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одну фотографию'**
  String get auto_dobavteHotyaByOdnuFot;

  /// No description provided for @auto_sozdatTovar.
  ///
  /// In ru, this message translates to:
  /// **'Создать товар?'**
  String get auto_sozdatTovar;

  /// No description provided for @auto_izmeneniyaBudutOtpravle.
  ///
  /// In ru, this message translates to:
  /// **'Изменения будут отправлены на модерацию'**
  String get auto_izmeneniyaBudutOtpravle;

  /// No description provided for @auto_tovarBudetOtpravlenNa.
  ///
  /// In ru, this message translates to:
  /// **'Товар будет отправлен на модерацию'**
  String get auto_tovarBudetOtpravlenNa;

  /// No description provided for @auto_sozdat.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get auto_sozdat;

  /// No description provided for @auto_redaktirovanieTovara.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование товара'**
  String get auto_redaktirovanieTovara;

  /// No description provided for @auto_osnovnyeDannye.
  ///
  /// In ru, this message translates to:
  /// **'Основные данные'**
  String get auto_osnovnyeDannye;

  /// No description provided for @auto_zapolniteNazvanieOpisan.
  ///
  /// In ru, this message translates to:
  /// **'Заполните название, описание, страну и категорию товара.'**
  String get auto_zapolniteNazvanieOpisan;

  /// No description provided for @auto_nazvanieTovara.
  ///
  /// In ru, this message translates to:
  /// **'Название товара'**
  String get auto_nazvanieTovara;

  /// No description provided for @auto_naprimerKazahstan.
  ///
  /// In ru, this message translates to:
  /// **'Например, Казахстан'**
  String get auto_naprimerKazahstan;

  /// No description provided for @auto_naprimer12Mesyatsev.
  ///
  /// In ru, this message translates to:
  /// **'Например, 12 месяцев'**
  String get auto_naprimer12Mesyatsev;

  /// No description provided for @auto_tsenaIUsloviya.
  ///
  /// In ru, this message translates to:
  /// **'Цена и условия'**
  String get auto_tsenaIUsloviya;

  /// No description provided for @auto_minimalnyeKolichestvaI.
  ///
  /// In ru, this message translates to:
  /// **'Минимальные количества и доставка.'**
  String get auto_minimalnyeKolichestvaI;

  /// No description provided for @auto_tsenaZaEdinitsu.
  ///
  /// In ru, this message translates to:
  /// **'Цена за единицу'**
  String get auto_tsenaZaEdinitsu;

  /// No description provided for @auto_naprimer1450.
  ///
  /// In ru, this message translates to:
  /// **'Например, 1450'**
  String get auto_naprimer1450;

  /// No description provided for @auto_minimalnoeKolichestvo.
  ///
  /// In ru, this message translates to:
  /// **'Минимальное количество'**
  String get auto_minimalnoeKolichestvo;

  /// No description provided for @auto_vsegoKolichestvo.
  ///
  /// In ru, this message translates to:
  /// **'Всего количество'**
  String get auto_vsegoKolichestvo;

  /// No description provided for @auto_naprimer120.
  ///
  /// In ru, this message translates to:
  /// **'Например, 120'**
  String get auto_naprimer120;

  /// No description provided for @auto_sostavIHarakteristiki.
  ///
  /// In ru, this message translates to:
  /// **'Состав и характеристики'**
  String get auto_sostavIHarakteristiki;

  /// No description provided for @auto_neobyazatelnyeDannyeZap.
  ///
  /// In ru, this message translates to:
  /// **'Необязательные данные: заполняйте только то, что нужно.'**
  String get auto_neobyazatelnyeDannyeZap;

  /// No description provided for @auto_sostav.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get auto_sostav;

  /// No description provided for @auto_kaloriiKkal100g.
  ///
  /// In ru, this message translates to:
  /// **'Калории (ккал/100г)'**
  String get auto_kaloriiKkal100g;

  /// No description provided for @auto_belkiG100g.
  ///
  /// In ru, this message translates to:
  /// **'Белки (г/100г)'**
  String get auto_belkiG100g;

  /// No description provided for @auto_zhiryG100g.
  ///
  /// In ru, this message translates to:
  /// **'Жиры (г/100г)'**
  String get auto_zhiryG100g;

  /// No description provided for @auto_uglevodyG100g.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы (г/100г)'**
  String get auto_uglevodyG100g;

  /// No description provided for @auto_harakteristikiTovara.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики товара'**
  String get auto_harakteristikiTovara;

  /// No description provided for @auto_nazvanie.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get auto_nazvanie;

  /// No description provided for @auto_znachenie.
  ///
  /// In ru, this message translates to:
  /// **'Значение'**
  String get auto_znachenie;

  /// No description provided for @auto_udalitHarakteristiku.
  ///
  /// In ru, this message translates to:
  /// **'Удалить характеристику'**
  String get auto_udalitHarakteristiku;

  /// No description provided for @auto_dobavitHarakteristiku.
  ///
  /// In ru, this message translates to:
  /// **'Добавить характеристику'**
  String get auto_dobavitHarakteristiku;

  /// No description provided for @auto_fotografiiTovara.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии товара'**
  String get auto_fotografiiTovara;

  /// No description provided for @auto_dobavteNeskolkoFoto.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте несколько фото'**
  String get auto_dobavteNeskolkoFoto;

  /// No description provided for @auto_ozhidaemayaDataDostavki.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаемая дата доставки'**
  String get auto_ozhidaemayaDataDostavki;

  /// No description provided for @auto_poGrafiku.
  ///
  /// In ru, this message translates to:
  /// **'По графику'**
  String get auto_poGrafiku;

  /// No description provided for @auto_poSroku.
  ///
  /// In ru, this message translates to:
  /// **'По сроку'**
  String get auto_poSroku;

  /// No description provided for @auto_pokupatelUviditOzhidaem.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель увидит ожидаемую дату доставки.'**
  String get auto_pokupatelUviditOzhidaem;

  /// No description provided for @auto_vyberiteDniNedeli.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дни недели'**
  String get auto_vyberiteDniNedeli;

  /// No description provided for @auto_bystryyVybor.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый выбор'**
  String get auto_bystryyVybor;

  /// No description provided for @auto_vremyaDostavki.
  ///
  /// In ru, this message translates to:
  /// **'Время доставки'**
  String get auto_vremyaDostavki;

  /// No description provided for @auto_formatChchmm.
  ///
  /// In ru, this message translates to:
  /// **'Формат: ЧЧ:ММ'**
  String get auto_formatChchmm;

  /// No description provided for @auto_nekorrektnoeVremya.
  ///
  /// In ru, this message translates to:
  /// **'Некорректное время'**
  String get auto_nekorrektnoeVremya;

  /// No description provided for @auto_minimumDney.
  ///
  /// In ru, this message translates to:
  /// **'Минимум дней'**
  String get auto_minimumDney;

  /// No description provided for @auto_maksimumDney.
  ///
  /// In ru, this message translates to:
  /// **'Максимум дней'**
  String get auto_maksimumDney;

  /// No description provided for @auto_srokPriyomaZakazaNaSe.
  ///
  /// In ru, this message translates to:
  /// **'Срок приёма заказа на сегодня'**
  String get auto_srokPriyomaZakazaNaSe;

  /// No description provided for @auto_kategorii.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get auto_kategorii;

  /// No description provided for @auto_poiskKategorii.
  ///
  /// In ru, this message translates to:
  /// **'Поиск категории'**
  String get auto_poiskKategorii;

  /// No description provided for @auto_kategoriiNeNaydeny.
  ///
  /// In ru, this message translates to:
  /// **'Категории не найдены'**
  String get auto_kategoriiNeNaydeny;

  /// No description provided for @auto_pokazatMenshe.
  ///
  /// In ru, this message translates to:
  /// **'Показать меньше'**
  String get auto_pokazatMenshe;

  /// No description provided for @auto_foto.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get auto_foto;

  /// No description provided for @auto_kompaniya.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get auto_kompaniya;

  /// No description provided for @auto_vyNeAvtorizovanyPozhal.
  ///
  /// In ru, this message translates to:
  /// **'Вы не авторизованы. Пожалуйста, войдите.'**
  String get auto_vyNeAvtorizovanyPozhal;

  /// No description provided for @auto_neUdalosZagruzitStatis.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить статистику'**
  String get auto_neUdalosZagruzitStatis;

  /// No description provided for @auto_neUdalosSformirovatAir.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать AI-резюме'**
  String get auto_neUdalosSformirovatAir;

  /// No description provided for @auto_statistika.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get auto_statistika;

  /// No description provided for @auto_analitikaProdazh.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика продаж'**
  String get auto_analitikaProdazh;

  /// No description provided for @auto_obnovit.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get auto_obnovit;

  /// No description provided for @auto_vseVremya.
  ///
  /// In ru, this message translates to:
  /// **'Все время'**
  String get auto_vseVremya;

  /// No description provided for @auto_vybrat.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get auto_vybrat;

  /// No description provided for @auto_obshchayaVyruchka.
  ///
  /// In ru, this message translates to:
  /// **'Общая выручка'**
  String get auto_obshchayaVyruchka;

  /// No description provided for @auto_vyruchkaZaMesyats.
  ///
  /// In ru, this message translates to:
  /// **'Выручка за месяц'**
  String get auto_vyruchkaZaMesyats;

  /// No description provided for @auto_zaNedelyu.
  ///
  /// In ru, this message translates to:
  /// **'За неделю'**
  String get auto_zaNedelyu;

  /// No description provided for @auto_vsegoZakazov.
  ///
  /// In ru, this message translates to:
  /// **'Всего заказов'**
  String get auto_vsegoZakazov;

  /// No description provided for @auto_obzor.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get auto_obzor;

  /// No description provided for @auto_sredniyChek.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get auto_sredniyChek;

  /// No description provided for @auto_dinamikaVyruchki.
  ///
  /// In ru, this message translates to:
  /// **'Динамика выручки'**
  String get auto_dinamikaVyruchki;

  /// No description provided for @auto_netDannyh.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get auto_netDannyh;

  /// No description provided for @auto_dostavleny.
  ///
  /// In ru, this message translates to:
  /// **'Доставлены'**
  String get auto_dostavleny;

  /// No description provided for @auto_otpravleny.
  ///
  /// In ru, this message translates to:
  /// **'Отправлены'**
  String get auto_otpravleny;

  /// No description provided for @auto_podtverzhdeny.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждены'**
  String get auto_podtverzhdeny;

  /// No description provided for @auto_ozhidayut.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают'**
  String get auto_ozhidayut;

  /// No description provided for @auto_otmeneny.
  ///
  /// In ru, this message translates to:
  /// **'Отменены'**
  String get auto_otmeneny;

  /// No description provided for @auto_statusyZakazov.
  ///
  /// In ru, this message translates to:
  /// **'Статусы заказов'**
  String get auto_statusyZakazov;

  /// No description provided for @auto_etotMesyats.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get auto_etotMesyats;

  /// No description provided for @auto_proshlyyMesyats.
  ///
  /// In ru, this message translates to:
  /// **'Прошлый месяц'**
  String get auto_proshlyyMesyats;

  /// No description provided for @auto_srDostavka.
  ///
  /// In ru, this message translates to:
  /// **'Ср. доставка'**
  String get auto_srDostavka;

  /// No description provided for @auto_pokupateli.
  ///
  /// In ru, this message translates to:
  /// **'Покупатели'**
  String get auto_pokupateli;

  /// No description provided for @auto_vsego.
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get auto_vsego;

  /// No description provided for @auto_postoyannye.
  ///
  /// In ru, this message translates to:
  /// **'Постоянные'**
  String get auto_postoyannye;

  /// No description provided for @auto_novyeMes.
  ///
  /// In ru, this message translates to:
  /// **'Новые / мес.'**
  String get auto_novyeMes;

  /// No description provided for @auto_poslednieOtzyvy.
  ///
  /// In ru, this message translates to:
  /// **'Последние отзывы'**
  String get auto_poslednieOtzyvy;

  /// No description provided for @auto_aianaliz.
  ///
  /// In ru, this message translates to:
  /// **'AI-анализ'**
  String get auto_aianaliz;

  /// No description provided for @auto_generiruyuAianaliz.
  ///
  /// In ru, this message translates to:
  /// **'Генерирую AI-анализ…'**
  String get auto_generiruyuAianaliz;

  /// No description provided for @auto_appmessagedialogPodderzh.
  ///
  /// In ru, this message translates to:
  /// **'AppMessageDialog поддерживает максимум 3 действия'**
  String get auto_appmessagedialogPodderzh;

  /// No description provided for @auto_poiskPoPostavshchikam.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по поставщикам'**
  String get auto_poiskPoPostavshchikam;

  /// No description provided for @auto_neprochitannyhUvedomleni_1.
  ///
  /// In ru, this message translates to:
  /// **'непрочитанных уведомлений'**
  String get auto_neprochitannyhUvedomleni_1;

  /// No description provided for @auto_pishchevayaTsennost.
  ///
  /// In ru, this message translates to:
  /// **'Пищевая ценность'**
  String get auto_pishchevayaTsennost;

  /// No description provided for @auto_v100Grammah.
  ///
  /// In ru, this message translates to:
  /// **'В 100 граммах:'**
  String get auto_v100Grammah;

  /// No description provided for @auto_kalorii.
  ///
  /// In ru, this message translates to:
  /// **'Калории'**
  String get auto_kalorii;

  /// No description provided for @auto_belki.
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get auto_belki;

  /// No description provided for @auto_zhiry.
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get auto_zhiry;

  /// No description provided for @auto_uglevody.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы'**
  String get auto_uglevody;

  /// No description provided for @auto_dostavka.
  ///
  /// In ru, this message translates to:
  /// **'доставка'**
  String get auto_dostavka;

  /// No description provided for @auto_budni.
  ///
  /// In ru, this message translates to:
  /// **'будни'**
  String get auto_budni;

  /// No description provided for @auto_vyhodnye.
  ///
  /// In ru, this message translates to:
  /// **'выходные'**
  String get auto_vyhodnye;

  /// No description provided for @auto_kazhdyyDen.
  ///
  /// In ru, this message translates to:
  /// **'каждый день'**
  String get auto_kazhdyyDen;

  /// No description provided for @auto_pn_1.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get auto_pn_1;

  /// No description provided for @auto_vt.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get auto_vt;

  /// No description provided for @auto_sr.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get auto_sr;

  /// No description provided for @auto_cht.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get auto_cht;

  /// No description provided for @auto_pt.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get auto_pt;

  /// No description provided for @auto_sb.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get auto_sb;

  /// No description provided for @auto_vs.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get auto_vs;

  /// No description provided for @auto_sht.
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get auto_sht;

  /// No description provided for @auto_chitatVse.
  ///
  /// In ru, this message translates to:
  /// **'Читать все'**
  String get auto_chitatVse;

  /// No description provided for @auto_pokaNetOtzyvovStanteP.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отзывов. Станьте первым, кто оценит товар.'**
  String get auto_pokaNetOtzyvovStanteP;

  /// No description provided for @auto_postavshchika.
  ///
  /// In ru, this message translates to:
  /// **'поставщика'**
  String get auto_postavshchika;

  /// No description provided for @auto_izmenitOtvet.
  ///
  /// In ru, this message translates to:
  /// **'Изменить ответ'**
  String get auto_izmenitOtvet;

  /// No description provided for @auto_otvetitNaVopros.
  ///
  /// In ru, this message translates to:
  /// **'Ответить на вопрос'**
  String get auto_otvetitNaVopros;

  /// No description provided for @auto_vopros.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос:'**
  String get auto_vopros;

  /// No description provided for @auto_vashOtvet.
  ///
  /// In ru, this message translates to:
  /// **'Ваш ответ'**
  String get auto_vashOtvet;

  /// No description provided for @auto_otvetitNaOtzyv.
  ///
  /// In ru, this message translates to:
  /// **'Ответить на отзыв'**
  String get auto_otvetitNaOtzyv;

  /// No description provided for @auto_otzyv.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв:'**
  String get auto_otzyv;

  /// No description provided for @auto_pereezzhal.
  ///
  /// In ru, this message translates to:
  /// **'Переезжал'**
  String get auto_pereezzhal;

  /// No description provided for @auto_pokazat.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get auto_pokazat;

  /// No description provided for @auto_otkryt.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get auto_otkryt;

  /// No description provided for @auto_ovoshch.
  ///
  /// In ru, this message translates to:
  /// **'Овощи'**
  String get auto_ovoshch;

  /// No description provided for @auto_hleb.
  ///
  /// In ru, this message translates to:
  /// **'Хлеб'**
  String get auto_hleb;

  /// No description provided for @auto_myas.
  ///
  /// In ru, this message translates to:
  /// **'Мясо'**
  String get auto_myas;

  /// No description provided for @auto_zaDen.
  ///
  /// In ru, this message translates to:
  /// **'За день'**
  String get auto_zaDen;

  /// No description provided for @auto_nedelya.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get auto_nedelya;

  /// No description provided for @auto_mesyats.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get auto_mesyats;

  /// No description provided for @auto_kvartal.
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get auto_kvartal;

  /// No description provided for @auto_redaktirovatAdres.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать адрес'**
  String get auto_redaktirovatAdres;

  /// No description provided for @auto_otpravlyaem.
  ///
  /// In ru, this message translates to:
  /// **'Отправляем...'**
  String get auto_otpravlyaem;

  /// No description provided for @auto_sohranyaem.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем...'**
  String get auto_sohranyaem;

  /// No description provided for @auto_vvediteKodPodtverzhdeni.
  ///
  /// In ru, this message translates to:
  /// **'Введите код подтверждения'**
  String get auto_vvediteKodPodtverzhdeni;

  /// No description provided for @auto_tovarSnyatSPublikatsii.
  ///
  /// In ru, this message translates to:
  /// **'Товар снят с публикации'**
  String get auto_tovarSnyatSPublikatsii;

  /// No description provided for @auto_sohranitIzmeneniya.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get auto_sohranitIzmeneniya;

  /// No description provided for @auto_sozdanieTovara.
  ///
  /// In ru, this message translates to:
  /// **'Создание товара'**
  String get auto_sozdanieTovara;

  /// No description provided for @auto_neprochitannoeUvedomleni.
  ///
  /// In ru, this message translates to:
  /// **'непрочитанное уведомление'**
  String get auto_neprochitannoeUvedomleni;

  /// No description provided for @auto_neprochitannyhUvedomleni.
  ///
  /// In ru, this message translates to:
  /// **'непрочитанных уведомлений'**
  String get auto_neprochitannyhUvedomleni;

  /// No description provided for @auto_ezhednevno.
  ///
  /// In ru, this message translates to:
  /// **'Ежедневно'**
  String get auto_ezhednevno;

  /// No description provided for @auto_otvetit.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get auto_otvetit;
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
