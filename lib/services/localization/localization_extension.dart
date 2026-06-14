import 'package:flutter/material.dart';

import '../../models/currency.dart';
import '../../models/language.dart';
import '../store/app_settings.dart';
import 'app_localizations.dart';
import 'currency_formatter.dart';

/// Расширение для удобного доступа к локализации в виджетах
extension LocalizationExtension on BuildContext {
  /// Получает текущие локализации
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Получает текущий язык
  LanguageCode get currentLanguage => AppSettings.language.value.code;

  /// Получает текущую валюту
  CurrencyCode get currentCurrency => AppSettings.currency.value.code;

  /// Форматирует сумму в текущей валюте
  String formatCurrency(double amount, {int decimalDigits = 2}) {
    return CurrencyFormatter.formatAmount(
      amount,
      currentCurrency,
      decimalDigits: decimalDigits,
      language: currentLanguage,
    );
  }

  /// Форматирует число в текущем языке
  String formatNumber(double amount, {int decimalDigits = 2}) {
    return CurrencyFormatter.formatNumber(
      amount,
      decimalDigits: decimalDigits,
      language: currentLanguage,
    );
  }

  /// Форматирует целое число с разделителями
  String formatInteger(int number) {
    return CurrencyFormatter.formatInteger(
      number,
      language: currentLanguage,
    );
  }

  /// Форматирует процент
  String formatPercent(double percent, {int decimalDigits = 2}) {
    return CurrencyFormatter.formatPercent(
      percent,
      decimalDigits: decimalDigits,
      language: currentLanguage,
    );
  }

  /// Конвертирует и форматирует сумму
  String convertCurrency(
    double amount,
    CurrencyCode fromCurrency,
    CurrencyCode toCurrency, {
    int decimalDigits = 2,
  }) {
    return CurrencyFormatter.convertAndFormat(
      amount,
      fromCurrency,
      toCurrency,
      decimalDigits: decimalDigits,
      language: currentLanguage,
    );
  }
}

/// Расширения для кратких имён переводов (shorthand properties)
extension LocalizationShorthand on AppLocalizations {
  // Settings page
  String get appearance => getString('settings_appearance');
  String get darkMode => getString('settings_dark_mode');
  String get useDarkTheme => getString('settings_use_dark_theme');
  String get languageAndRegion => getString('settings_language_region');
  String get languageLabel => getString('settings_language_label');
  String get currency => getString('settings_currency');
  String currencyName(String code) => getString('settings_currency_name', params: {'code': code});
  String get security => getString('settings_security');
  String get changePassword => getString('settings_change_password');
  String get twoFactorAuthentication => getString('settings_two_factor_auth');
  String get about => getString('settings_about');
  String get appVersion => getString('settings_app_version');

  // Navigation
  String get home => getString('nav_home');
  String get statistics => getString('nav_statistics');
  String get moderation => getString('nav_moderation');
  String get chats => getString('nav_chats');
  String get moderators => getString('nav_moderators');

  // Supplier products
  String get deleteProductConfirm => getString('supplier_delete_product_confirm');
  String get supplierProfileTitle => getString('supplier_profile_title');

  // Templates
  String get templateSaveTitle => getString('template_save_title');
  String get templateOverwrite => getString('template_overwrite');
  String get templateSaveAnother => getString('template_save_another');
  String get templateRenameTitle => getString('template_rename_title');
  String get templateApplyConfirm => getString('template_apply_confirm');
  String get templateAddToCart => getString('template_add_to_cart');
  String get replaceCart => getString('template_replace_cart');
  String get replaceCartConfirm => getString('template_replace_cart_confirm');
  String get templateNameLabel => getString('template_name_label');
  String get templateNameError => getString('template_name_error');
  String get templateDuplicateExists => getString('template_duplicate_exists');

  // Common buttons
  String get ok => getString('common_ok');
  String get cancel => getString('common_cancel');
  String get save => getString('common_save');
  String get delete => getString('common_delete');
  String get edit => getString('common_edit');
  String get loading => getString('common_loading');
  String get error => getString('common_error');
  String get success => getString('common_success');
String get noData => getString('common_no_data');
   String get tryAgain => getString('common_try_again');
   String get retry => getString('common_retry');
   String get send => getString('common_send');
   String get backTooltip => getString('common_back');
   String get next => getString('common_next');
   String get close => getString('common_close');
   String get add => getString('common_add');
   String get search => getString('common_search');
   String get confirm => getString('common_confirm');
   String get unitShort => getString('common_unit_short');
   String get undo => getString('common_undo');

   // Navigation tabs
  String get catalog => getString('catalog_title');
  String get cart => getString('cart_title');
  String get orders => getString('order_title');
  String get products => getString('supplier_products');
  String get profile => getString('profile_title');
  String get settings => getString('profile_settings');

  // Auth
  String get authLoginTitle => getString('auth_login_title');
  String get authRegisterTitle => getString('auth_register_title');
  String get authForgotPassword => getString('auth_forgot_password');
  String get authResetPasswordTitle => getString('auth_reset_password_title');
  String get authEmailLabel => getString('auth_email_label');
  String get authPasswordLabel => getString('auth_password_label');
  String get authNameLabel => getString('auth_name_label');
  String get authLogout => getString('auth_logout');

  // Supplier
  String get myProducts => getString('supplier_products');
  String get buyerOrders => getString('supplier_orders');
  String get approved => getString('supplier_apprved');
  String get rejected => getString('supplier_rejected');
  String get pending => getString('supplier_pending');
  String get noTitle => getString('supplier_no_title');
  String get noDescription => getString('supplier_no_description');
  String get moreLabel => getString('common_more');
  String get lessLabel => getString('common_less');

  // Reviews quick tags
  String get quickTagFastDelivery => getString('review_quick_fast_delivery');
  String get quickTagGoodPrice => getString('review_quick_good_price');
  String get quickTagQualityPackaging => getString('review_quick_quality_packaging');
  String get quickTagFreshProduct => getString('review_quick_fresh_product');
  String get quickTagPoliteCourier => getString('review_quick_polite_courier');
  String get noReviewText => getString('review_no_text');

  // Errors and messages
  String get unauthorizedError => getString('error_auth_required');
  String get notAuthorized => getString('error_auth_required');
  String get networkError => getString('error_network');
  String get failedToLoadProducts => getString('supplier_error_load_products');
  String get failedToLoadOrders => getString('supplier_error_load_orders');
  String get loginRequired => getString('supplier_login_required');
  String get productSentForModeration => getString('supplier_product_sent_moderation');
  String get productChangesSentForModeration => getString('supplier_changes_sent_moderation');
  String get deleteProduct => getString('supplier_delete_product');
  String get product => getString('supplier_product');
  String get productRemovedFromPublication => getString('supplier_removed_from_publication');
  String get productDeleted => getString('supplier_product_deleted');
  String get couldNotDeleteProduct => getString('supplier_error_delete_product');

  // Orders
  String get emptyOrdersMessageNoOrders => getString('supplier_orders_empty_no_orders');
  String get emptyOrdersMessageActive => getString('supplier_orders_empty_active');
  String get emptyOrdersMessageHistory => getString('supplier_orders_empty_history');
  String get emptyOrdersMessagePeriod => getString('supplier_orders_empty_period');
  String get sessionExpired => getString('auth_session_expired');
  String get statusChangeStep => getString('supplier_status_change_step');
  String get statusUpdated => getString('supplier_status_updated');
  String get statusUpdateFailed => getString('supplier_status_update_failed');
  String get statusConfirmChange => getString('supplier_status_confirm_change');
  String get orderPrefix => getString('supplier_order_prefix');
  String get from => getString('supplier_from');
  String get to => getString('supplier_to');

  // Periods
  String get periodDay => getString('supplier_period_day');
  String get periodWeek => getString('supplier_period_week');
  String get periodMonth => getString('supplier_period_month');
  String get periodQuarter => getString('supplier_period_quarter');

  // Tabs
  String get activeOrdersTab => getString('supplier_active_orders_tab');
  String get historyOrdersTab => getString('supplier_history_orders_tab');

  // Other
  String get filterLabel => getString('supplier_filter_label');
  String get exportToExcel => getString('supplier_export_excel');
  String get productsInOrder => getString('supplier_products_in_order');
  String get topProducts => getString('supplier_top_products');
  String get recentOrders => getString('supplier_recent_orders');

  // QA
  String get back => getString('common_back');
  String get qaTitle => getString('qa_title');
  String get qaQuestionsTab => getString('qa_questions_tab');
  String get qaReviewsTab => getString('qa_reviews_tab');
  String get qaQuestionsWithoutAnswers => getString('qa_questions_without_answers');
  String get qaAnsweredQuestions => getString('qa_answered_questions');
  String get qaNoQuestions => getString('qa_no_questions');
  String get qaNoReviews => getString('qa_no_reviews');
  String get qaNoText => getString('qa_no_text');
  String get qaSellerAnswer => getString('qa_seller_answer');
  String get qaWithoutAnswer => getString('qa_without_answer');
  String get qaAnswerSentSuccess => getString('qa_answer_sent_success');
  String get qaAnswerUpdatedSuccess => getString('qa_answer_updated_success');
  String get qaNotAuthorized => getString('qa_not_authorized');
  String get qaRefresh => getString('qa_refresh');
  String get qaRetry => getString('qa_retry');
  String get qaExpand => getString('qa_expand');
  String get qaCollapse => getString('qa_collapse');
  String get qaRespond => getString('qa_respond');
  String get qaCustomersNoQuestions => getString('qa_customers_no_questions');
  String get qaCustomersNoReviews => getString('qa_customers_no_reviews');
  String get qaNoAnswer => getString('qa_no_answer');
  String qaErrorWithDetailsMsg(String details) => getString('qa_error_with_details', params: {'details': details});
  String unansweredQuestions(int count) => getString('supplier_unanswered_questions', params: {'count': count});

  // Reviews page
  String get reviewsTitle => getString('profile_reviews_title');
  String get reviewsEmpty => getString('profile_reviews_empty');
  String get reviewsPendingTitle => getString('profile_reviews_pending_title');
  String get reviewsPendingSubtitle => getString('profile_reviews_pending_subtitle');
  String get reviewsPendingButton => getString('profile_reviews_leave_review');
  String get reviewsTotalCount => getString('profile_reviews_total_count', params: {'count': ''});
  String reviewsTotalCountWith(int count) => getString('profile_reviews_total_count', params: {'count': count.toString()});
  String get reviewsSectionTitle => getString('profile_reviews_section_title');
  String get reviewsSectionSubtitleEmpty => getString('profile_reviews_section_subtitle_empty');
  String reviewsSectionSubtitleTotal(int count) => getString('profile_reviews_section_subtitle_total', params: {'count': count.toString()});
  String get reviewsRateProduct => getString('profile_reviews_rate_product');
  String get reviewsAddDetails => getString('profile_reviews_add_details');
  String get reviewsPlaceholder => getString('product_review_hint');
  String get reviewsEditButton => getString('profile_reviews_edit_button');
  String get reviewsDeleteButton => getString('profile_reviews_delete_button');
  String get reviewsSending => getString('profile_reviews_sending');
  String get reviewsSaveButton => getString('profile_reviews_save_button');
  String get reviewsSavedSuccess => getString('profile_reviews_saved_success');
  String get reviewsSaveError => getString('profile_reviews_save_error');
  String get reviewsLoginRequired => getString('profile_reviews_login_required');
  String get reviewsRatingRequired => getString('profile_reviews_rating_required');
  String get reviewsSubmitSuccess => getString('profile_reviews_submit_success');
  String get reviewsSubmitError => getString('profile_reviews_submit_error');
  String get reviewsDeleteConfirm => getString('profile_reviews_delete_confirm');
  String get reviewsDeleteSuccess => getString('profile_reviews_delete_success');
  String get reviewsDeleteError => getString('profile_reviews_delete_error');
  String get reviewsCloseDialog => getString('profile_reviews_close_dialog');
  String get reviewsCancelButton => getString('profile_reviews_cancel_button');
  String get reviewsChangeButton => getString('profile_reviews_change_button');
  String get reviewsOrderLabel => getString('profile_reviews_order_label', params: {'orderId': ''});
  String reviewsOrderLabelWith(String orderId) => getString('profile_reviews_order_label', params: {'orderId': orderId});

  // Similar products
  String get similarProducts => getString('product_similar');

  // Templates
  String get addProductsToCart => getString('template_add_to_cart');

  // Product wizard
  String get optional => getString('wizard_optional');
  String get ordersCutoffTime => getString('wizard_orders_cutoff_time');
  String get invalidTime => getString('wizard_invalid_time');
  String get selectCategoryFromCatalog => getString('wizard_select_category');

  // Settings
  String get enabled => getString('settings_enabled');
  String get disabled => getString('settings_disabled');

  // Order status labels and messages
  String get statusAssembling => getString('supplier_status_assembling');
  String get statusInTransit => getString('supplier_status_in_transit');
  String get statusDelivered => getString('supplier_status_delivered');
  String get statusAccepted => getString('supplier_status_accepted');
  String get statusCancelled => getString('supplier_status_cancelled');
  String get orderProgress => getString('supplier_order_progress');
  String getCurrentStatus(String status) => getString('supplier_current_status', params: {'status': status});
  String get orderConfirmedByBuyer => getString('supplier_order_confirmed_by_buyer');
  String get waitingBuyerConfirmation => getString('supplier_waiting_buyer_confirmation');
  String get exportSuccess => getString('supplier_export_success');
  String exportError(String error) => getString('supplier_export_error', params: {'error': error});

  // Order items and addresses
  String get orderItemsLabel => getString('supplier_products_in_order');
  String get orderItemsEmpty => getString('supplier_order_items_empty');
  String get orderTotalLabel => getString('supplier_order_total_label');
  String get deliveryAddressLabel => getString('supplier_delivery_address_label');
  String get addressNotSpecified => getString('supplier_address_not_specified');
  String get orderStatusLabel => getString('supplier_order_status_label');
  String get goodsPositionsLabel => getString('supplier_goods_positions_label');
  String get unitsCountLabel => getString('supplier_units_count_label');
  String get unitsCountShort => getString('units_count_short');
  String get itemsCountShort => getString('items_count_short');
  String get confirmedLabel => getString('supplier_confirmed_label');

  // Answered label
  String get answeredLabel => getString('answered_label');
  String get supplierDefaultLabel => getString('supplier_label');

  // Unknown error
  String get unknownError => getString('unknown_error');

  // Price and checkout
  String get price => getString('price');
  String get checkout => getString('checkout');

  // Review additional keys
  String get reviewSending => getString('review_sending');
  String get reviewNoText => getString('review_no_text');
  String get reviewYourText => getString('review_your_text');
  String get reviewRateProduct => getString('review_rate_product');
  String get reviewAddDetails => getString('review_add_details');
  String get reviewShareFeedback => getString('review_share_feedback');
  String get reviewSaveButton => getString('review_save_button');
  String get reviewEditButton => getString('review_edit_button');
  String get reviewDeleteButton => getString('review_delete_button');
  String get reviewCancelButton => getString('review_cancel_button');
  String get reviewChangeButton => getString('review_change_button');
  String get reviewLeaveButton => getString('review_leave_button');
  String get reviewSubmitButton => getString('review_submit_button');
  String get reviewDeleteConfirm => getString('review_delete_confirm');
  String get reviewCloseDialog => getString('review_close_dialog');
  String get errorAuthRequiredLabel => getString('error_auth_required');
  String get reviewSendingText => getString('review_sending_text');
  String get reviewSaveDraft => getString('review_save_draft');
  String get reviewEditDraft => getString('review_edit_draft');
  String get reviewDeleteDraft => getString('review_delete_draft');
  String get reviewCancelDraft => getString('review_cancel_draft');
  String get reviewChangeDraft => getString('review_change_draft');
  String get reviewLeaveDraft => getString('review_leave_draft');
  String get reviewSubmitDraft => getString('review_submit_draft');
  String get reviewThankYou => getString('review_thank_you');
  String get reviewNoQuestionsEmpty => getString('review_no_questions_empty');
  String get confirmDelete => getString('confirm_delete');
  String get confirmCancel => getString('confirm_cancel');
  String get cannotBeUndone => getString('cannot_be_undone');

  // Home page
  String get homeTitle => getString('home_title');
  String get homeAllTab => getString('home_all_tab');
  String get homeSearchHint => getString('home_search_hint');
  String get homeRetryButton => getString('home_retry_button');
  String homeLoadingError(String error) => getString('home_loading_error', params: {'error': error});
  String get homeNoProducts => getString('home_no_products');

// Filters sheet
   String get filtersSheetTitle => getString('filters_sheet_title');
   String get filtersResetButton => getString('filters_reset_button');
   String get filterPriceTitle => getString('filter_price_title');
   String get filterPriceFrom => getString('filter_price_from');
   String get filterPriceTo => getString('filter_price_to');
   String get filterSortTitle => getString('filter_sort_title');
   String get filterSortPrice => getString('filter_sort_price');
   String get filterSortRating => getString('filter_sort_rating');
   String get filterOrderTitle => getString('filter_order_title');
   String get filterOrderAsc => getString('filter_order_asc');
   String get filterOrderDesc => getString('filter_order_desc');
String get filterRatingTitle => getString('filter_rating_title');
    String get filterRatingFrom => getString('filter_rating_from');
    String filterShowButton(int count) => getString('filter_show_button', params: {'count': count.toString()});
    String get filterDiscounted => getString('filter_discounted');

// Date Range Picker
     String get dateRangePickerTitle => getString('date_range_picker_title');
     String get dateRangePickerClear => getString('date_range_picker_clear');
     String get dateRangePickerToday => getString('date_range_picker_today');
     String get dateRangePickerWeek => getString('date_range_picker_week');
     String get dateRangePickerMonth => getString('date_range_picker_month');
     String get dateRangePickerQuarter => getString('date_range_picker_quarter');
     String get selectDateRange => getString('select_date_range');
     String get monthJanuary => getString('month_january');
    String get monthFebruary => getString('month_february');
    String get monthMarch => getString('month_march');
    String get monthApril => getString('month_april');
    String get monthMay => getString('month_may');
    String get monthJune => getString('month_june');
    String get monthJuly => getString('month_july');
    String get monthAugust => getString('month_august');
    String get monthSeptember => getString('month_september');
    String get monthOctober => getString('month_october');
    String get monthNovember => getString('month_november');
    String get monthDecember => getString('month_december');

  // Templates Sheet
    String get templatesSheetTitle => getString('templates_sheet_title');
    String get templatesSheetNoTemplates => getString('templates_sheet_no_templates');
    String get templatesSheetCollapse => getString('templates_sheet_collapse');
    String get templatesSheetExpand => getString('templates_sheet_expand');
    String get templatesSheetActions => getString('templates_sheet_actions');
    String get templatesSheetRename => getString('templates_sheet_rename');
    String get templatesSheetDelete => getString('templates_sheet_delete');
String get templatesSheetAddToCart => getString('templates_sheet_add_to_cart');
     String get templatesSheetPositionShort => getString('templates_sheet_position_short');
     String get templatesSheetUnitShort => getString('templates_sheet_unit_short');
     String get templatesSheetHide => getString('templates_sheet_hide');

   // Supplier
     String get supplierSelected => getString('supplier_selected');
     String get supplierSelect => getString('supplier_select');
     String get supplierUnitShort => getString('supplier_unit_short');
     String get supplierDeliveryDefault => getString('supplier_delivery_default');

// Product Card
      String productAddedToFavorites(String product) => getString('product_card_added_to_favorites');
      String get productRemovedFromFavorites => getString('product_card_removed_from_favorites');
      String productAddedToCart(String product, int quantity) => getString('product_card_add_to_cart');
      String get productOutOfStock => getString('product_card_out_of_stock');
      String get productQuantityTitle => getString('product_card_quantity_title');
      String productMinQuantity(int count) => getString('product_card_min_quantity');
      String get productEveryday => getString('product_card_everyday');
      String get productWeekdays => getString('product_card_weekdays');
      String get productWeekend => getString('product_card_weekend');
      String productQuantity(int count) => getString('product_card_quantity', params: {'count': count.toString()});

      // Weekdays
      String get weekdayMonday => getString('weekday_monday');
      String get weekdayTuesday => getString('weekday_tuesday');
      String get weekdayWednesday => getString('weekday_wednesday');
      String get weekdayThursday => getString('weekday_thursday');
      String get weekdayFriday => getString('weekday_friday');
      String get weekdaySaturday => getString('weekday_saturday');
      String get weekdaySunday => getString('weekday_sunday');
      String get weekdayMonShort => getString('weekday_mon_short');
      String get weekdayTueShort => getString('weekday_tue_short');
      String get weekdayWedShort => getString('weekday_wed_short');
      String get weekdayThuShort => getString('weekday_thu_short');
      String get weekdayFriShort => getString('weekday_fri_short');
      String get weekdaySatShort => getString('weekday_sat_short');
      String get weekdaySunShort => getString('weekday_sun_short');

// Additional UI strings
   String get supportChatTitle => getString('support_chat_title');
   String get supportChatsTitle => getString('support_chats_title');
   String get supplierResetButton => getString('supplier_reset_button');
   String get supplierProfileReset => getString('supplier_profile_reset');
String supplierProfilePreviewShow(int count) => getString('supplier_profile_preview_show', params: {'count': count.toString()});
   String get moderationTitle => getString('moderator_title');
   String get moderatorTitle => getString('moderator_title_profile');
   String get createChatTitle => getString('create_chat_title');
   String get createChatConfirm => getString('create_chat_confirm');
   String get createChatButton => getString('create_chat_button');
   String get closeChatTitle => getString('close_chat_title');
   String get closeChatButton => getString('close_chat_button');
   String get suppliersListTitle => getString('suppliers_list_title');
   String get suppliersLoadFailed => getString('suppliers_load_failed');
   String get sessionExpiredLoginAgain => getString('session_expired_login_again');
   String get chatOpenFailed => getString('chat_open_failed');
   String get chatCreateFailed => getString('chat_create_failed');
   String get searchNoResults => getString('search_no_results');
   String searchNoResultsFor(String query) => getString('search_no_results_for', params: {'query': query});
   String get suppliersCatalogAccessDenied => getString('suppliers_catalog_access_denied');
   String get questionAskButton => getString('question_ask_button');
   String get noButton => getString('no_button');
   String get cancelOrderTitle => getString('cancel_order_title');
   String get cancelOrderMessage => getString('cancel_order_message');
   String get cancelOrderButton => getString('cancel_order_button');
   String get acceptOrderButton => getString('accept_order_button');
   String get orderHistoryEmpty => getString('order_history_empty');
   String get favoritesTabProducts => getString('favorites_tab_products');
   String get favoritesTabCompanies => getString('favorites_tab_companies');
   String get changePasswordSuccessTitle => getString('change_password_success_title');
   String get changePasswordSuccessMessage => getString('change_password_success_message');
   String get changePasswordDoneButton => getString('change_password_done_button');
   String get paymentCardDeleteTitle => getString('payment_card_delete_title');
   String get paymentCardDeleteButton => getString('common_delete');
   String get commonDeleteButton => getString('common_delete');
   String get addressAddButton => getString('address_add_button');
   String get moderationApproveButton => getString('moderation_approve_button');
   String get moderationApproveProduct => getString('moderation_approve_product');
   String get moderationRejectProduct => getString('moderation_reject_product');
   String get moderationRejectHint => getString('moderation_reject_hint');
   String get moderationCommentHint => getString('moderation_comment_hint');
   String get moderationProductApproved => getString('moderation_product_approved');
   String get moderationProductRejected => getString('moderation_product_rejected');
   String get moderationUpdateError => getString('moderation_update_error');
   String get twoFactorDisableTitle => getString('two_factor_disable_title');
   String get twoFactorDisableButton => getString('two_factor_disable_button');
   String get moderatorManagementTitle => getString('moderator_management_title');
   String get moderatorDeleteTitle => getString('moderator_delete_title');
   String get moderatorDeleteButton => getString('common_delete');
   String get moderatorAddButton => getString('moderator_add_button');
   String get moderatorLoginButton => getString('moderator_login_button');
   String get twoFactorCopyAll => getString('two_factor_copy_all');
   String get twoFactorSaveFile => getString('two_factor_save_file');
   String get addModeratorTitle => getString('add_moderator_title');

   // Chat
   String get chatEmptyTitle => getString('chat_empty_title');
   String get chatEmptyHint => getString('chat_empty_hint');
   String get chatRetrySend => getString('chat_retry_send');
   String get suppliersNotFound => getString('suppliers_not_found');
   String get chatToday => getString('chat_today');
   String get chatYesterday => getString('chat_yesterday');
   String get chatBuyerDefault => getString('chat_buyer_default');
   String get chatNoReviewText => getString('chat_no_review_text');

  // QA strings added
  String qaMinimumCharacters(int minLength, int currentLength) => getString('qa_minimum_characters', params: {'minLength': minLength, 'currentLength': currentLength});
  String qaEnterAnswerMinimum(int minLength) => getString('qa_enter_answer_minimum', params: {'minLength': minLength});
  String avatarLoadError(String url, String error) => getString('avatar_load_error', params: {'url': url, 'error': error});
  String qaAnswerFromSupplier(String supplierName) => getString('qa_answer_from_supplier', params: {'supplierName': supplierName});
  
  // Ratings and nutrition
  String ratingsCountParentheses(int count) => getString('ratings_count_parentheses', params: {'count': count});
  String ratingsCountColon(int count) => getString('ratings_count_colon', params: {'count': count});
  String nutritionCaloriesUnit(String value) => getString('nutrition_calories_unit', params: {'value': value});
  String nutritionGramsUnit(String value) => getString('nutrition_grams_unit', params: {'value': value});
  
  // Templates
  String templatesSheetRenameTemplate(String name) => getString('templates_sheet_rename_template', params: {'name': name});
  String templatesSheetDeleteTemplate(String name) => getString('templates_sheet_delete_template', params: {'name': name});
  String templatesSheetAddToCartTemplate(String name) => getString('templates_sheet_add_to_cart_template', params: {'name': name});
  
  // Supplier statistics
  String supplierStatsDays(String days) => getString('supplier_stats_days', params: {'days': days});
  String supplierStatsUnitsSold(int count) => getString('supplier_stats_units_sold', params: {'count': count});
  String supplierStatsRepeatBuyers(String percentage) => getString('supplier_stats_repeat_buyers', params: {'percentage': percentage});
  String supplierStatsReviews(int count) => getString('supplier_stats_reviews', params: {'count': count});
  String supplierStatsOrderPrefix(String orderId) => getString('supplier_stats_order_prefix', params: {'orderId': orderId});
  
  // Wizard and products
  String wizardErrorPriceMax(String max) => getString('wizard_error_price_max', params: {'max': max});
  String wizardErrorMinQuantityMax(String max) => getString('wizard_error_min_quantity_max', params: {'max': max});
  String wizardErrorStockMax(String max) => getString('wizard_error_stock_max', params: {'max': max});
  String wizardErrorCaloriesMax(String max) => getString('wizard_error_calories_max', params: {'max': max});
  String wizardErrorProteinMax(String max) => getString('wizard_error_protein_max', params: {'max': max});
  String wizardErrorFatMax(String max) => getString('wizard_error_fat_max', params: {'max': max});
  String wizardErrorCarbsMax(String max) => getString('wizard_error_carbs_max', params: {'max': max});
  String wizardShowAllCategories(int count) => getString('wizard_show_all_categories', params: {'count': count});
  String wizardStepIndicator(int current, int total) => getString('wizard_step_indicator', params: {'current': current, 'total': total});
  
  String supplierProductsStockQuantity(int count) => getString('supplier_products_stock_quantity', params: {'count': count});
  String supplierProductsMinQuantity(int count) => getString('supplier_products_min_quantity', params: {'count': count});
  
  String supplierOrdersOrderNumber(String orderId) => getString('supplier_orders_order_number', params: {'orderId': orderId});
  String supplierOrdersItemsCount(int count) => getString('supplier_orders_items_count', params: {'count': count});
  
  // Pages
  String reviewsCountPrefix(int count) => getString('reviews_count_prefix', params: {'count': count});
  String questionsErrorLoading(String error) => getString('questions_error_loading', params: {'error': error});
  String questionsTotalCount(int count) => getString('questions_total_count', params: {'count': count});
  String questionsMinCharsError(int minLength, int current) => getString('questions_min_chars_error', params: {'minLength': minLength, 'current': current});
  String questionsEnterPrompt(int minLength) => getString('questions_enter_prompt', params: {'minLength': minLength});
  String productDetailAddedToCart(String name) => getString('product_added_to_cart', params: {'name': name});
  String productDetailRemovedFromCart(String name) => getString('product_removed_from_cart', params: {'name': name});
  String productTabReviews(int count) => getString('product_tab_reviews', params: {'count': count});
  String productTabQuestions(int count) => getString('product_tab_questions', params: {'count': count});
  String productPricePerUnit(String price) => getString('product_price_per_unit', params: {'price': price});
  String productInStock(int count) => getString('product_in_stock', params: {'count': count});
  String productReviewsLabel(int count) => getString('product_reviews_label', params: {'count': count});
  String orderHistoryOrderNumber(String id) => getString('order_history_order_number', params: {'id': id});
  String orderHistoryItemsCount(int count) => getString('order_history_items_count', params: {'count': count});
  String orderHistoryUnitsCount(int count) => getString('order_history_units_count', params: {'count': count});
  String orderHistoryReceivedItems(int received, int total) => getString('order_history_received_items', params: {'received': received, 'total': total});
  String orderHistorySupplierName(String name) => getString('order_history_supplier_name', params: {'name': name});
  String orderHistoryExportError(String error) => getString('order_history_export_error', params: {'error': error});
  String errorLoadingProducts(String error) => getString('error_loading_products', params: {'error': error});
}
