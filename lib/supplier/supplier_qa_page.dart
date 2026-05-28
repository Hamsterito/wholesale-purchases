import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/question.dart';
import '../models/review_entry.dart';
import '../models/product.dart';
import '../services/api/api_service.dart';
import '../services/storage/auth_storage.dart';
import '../widgets/product/rating_stars.dart';
import '../widgets/supplier/supplier_qa_answer_modal.dart';
import '../widgets/supplier/supplier_qa_response_modal.dart';
import '../widgets/expandable_text_block.dart';
import '../widgets/navigation/main_bottom_nav.dart';
import '../widgets/profile/user_avatar.dart';
import '../widgets/smooth_sheet.dart';
import '../utils/date_formatter.dart';
import '../theme/app_color_palette.dart';

class SupplierQAPage extends StatefulWidget {
  final String? productIdFilter;
  final Function(int)? onUnansweredCountChanged;

  const SupplierQAPage({
    super.key,
    this.productIdFilter,
    this.onUnansweredCountChanged,
  });

  @override
  State<SupplierQAPage> createState() => _SupplierQAPageState();
}

enum _PageState { loading, error, empty, data }

enum _TabType { questions, reviews }

// Типы элементов для ленивого рендеринга списка
sealed class _QAListItem {
  const _QAListItem();
}

final class _SectionHeaderItem extends _QAListItem {
  final String title;
  final int count;
  const _SectionHeaderItem(this.title, this.count);
}

final class _QuestionItem extends _QAListItem {
  final Question question;
  const _QuestionItem(this.question);
}

final class _ReviewItem extends _QAListItem {
  final ReviewEntry review;
  const _ReviewItem(this.review);
}

final class _AnsweredButtonItem extends _QAListItem {
  final List<Question> answeredQuestions;
  const _AnsweredButtonItem(this.answeredQuestions);
}

final class _EmptyTabItem extends _QAListItem {
  final String message;
  const _EmptyTabItem(this.message);
}

final class _LoadingMoreItem extends _QAListItem {
  const _LoadingMoreItem();
}

final class _SpacerItem extends _QAListItem {
  final double height;
  const _SpacerItem(this.height);
}

class _SupplierQAPageState extends State<SupplierQAPage> {
  final List<Question> _questions = [];
  final List<ReviewEntry> _reviews = [];
  // Индексы для O(1) поиска по id вместо O(n) indexWhere
  final Map<String, Question> _questionsById = {};
  final Map<String, ReviewEntry> _reviewsById = {};
  final Map<String, Product> _productMap = {};
  _PageState _pageState = _PageState.loading;
  String? _errorMessage;
  int _unansweredCount = 0;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  _TabType _selectedTab = _TabType.questions;

  // Кэш плоского списка элементов: пересобираем только при смене данных
  // или активной вкладки, иначе любой ребилд гонял _buildListItems заново.
  List<_QAListItem>? _cachedListItems;
  _TabType? _cachedListTab;

  // Кэш разделения вопросов на отвеченные и без ответа.
  // Без него _buildListItems делает два прохода .where(...).toList() на каждом ребилде.
  List<Question>? _cachedUnanswered;
  List<Question>? _cachedAnswered;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<_QAListItem> _getListItems() {
    if (_cachedListItems != null && _cachedListTab == _selectedTab) {
      return _cachedListItems!;
    }
    final items = _buildListItems();
    _cachedListItems = items;
    _cachedListTab = _selectedTab;
    return items;
  }

  void _invalidateListItemsCache() {
    _cachedListItems = null;
    _cachedListTab = null;
  }

  void _invalidateQuestionsSplitCache() {
    _cachedUnanswered = null;
    _cachedAnswered = null;
  }

  List<Question> get _unansweredQuestions {
    return _cachedUnanswered ??= _questions
        .where((q) => !q.isAnswered)
        .toList(growable: false);
  }

  List<Question> get _answeredQuestions {
    return _cachedAnswered ??= _questions
        .where((q) => q.isAnswered)
        .toList(growable: false);
  }

  void _onScroll() {
    if (_questions.isEmpty && _reviews.isEmpty) return;
    if (_isLoadingMore || !_hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadData(loadMore: true);
    }
  }

  Future<void> _loadData({bool loadMore = false}) async {
    if (_isLoadingMore && loadMore) return;

    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      setState(() {
        _errorMessage = 'Вы не авторизованы';
        _pageState = _PageState.error;
      });
      return;
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _pageState = _PageState.loading);
    }

    try {
      await Future.wait([
        _loadQuestions(userId, loadMore: loadMore),
        _loadReviews(userId, loadMore: loadMore),
      ]);

      if (mounted) {
        setState(() {
          _calculateUnansweredCount();
          if (_questions.isEmpty && _reviews.isEmpty) {
            _pageState = _PageState.empty;
          } else {
            _pageState = _PageState.data;
          }
          _errorMessage = null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _pageState = _PageState.error;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadSupplierProducts(int userId) async {
    try {
      final products = await ApiService.getSupplierProducts(userId: userId);
      for (final product in products) {
        _productMap[product.id] = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          imageUrls: product.imageUrls,
          rating: 0,
          reviewCount: 0,
          categories: [],
          nutritionalInfo: NutritionalInfo(
            calories: 0,
            protein: 0,
            fat: 0,
            carbohydrates: 0,
          ),
          ingredients: '',
          characteristics: {},
          suppliers: [],
          similarProducts: [],
          ratingDistribution: [],
        );
      }
    } catch (e) {
      debugPrint('Не удалось загрузить товары поставщика: $e');
    }
  }

  // Загружаем данные о товаре только когда они реально нужны (при открытии модала).
  // Если товар уже в кэше - сразу возвращаем, иначе подгружаем весь список
  // поставщика и заполняем кэш, чтобы следующие открытия были мгновенными.
  Future<void> _ensureProductLoaded(String productId) async {
    if (_productMap.containsKey(productId)) return;

    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    await _loadSupplierProducts(userId);
  }

  Future<void> _loadQuestions(int userId, {bool loadMore = false}) async {
    try {
      final data = await ApiService.getSupplierQuestions(
        userId: userId,
        page: loadMore ? _page : 1,
        limit: _limit,
      );

      final List<Question> fetched = (data['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      final filtered = widget.productIdFilter != null
          ? fetched.where((q) => q.productId == widget.productIdFilter).toList()
          : fetched;

      final total = data['total'] as int;

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _questions.clear();
            _questionsById.clear();
            _page = 1;
          }
          _questions.addAll(filtered);
          for (final q in filtered) {
            _questionsById[q.id] = q;
          }
          _hasMore = _questions.length < total;
          if (!loadMore) {
            _page = 2;
          } else {
            _page++;
          }
          _invalidateListItemsCache();
          _invalidateQuestionsSplitCache();
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки вопросов: $e');
      rethrow;
    }
  }

  Future<void> _loadReviews(int userId, {bool loadMore = false}) async {
    try {
      final data = await ApiService.getSupplierReviews(
        userId: userId,
        page: loadMore ? _page : 1,
        limit: _limit,
      );

      final List<ReviewEntry> fetched = (data['reviews'] as List)
          .map((r) => ReviewEntry.fromJson(r as Map<String, dynamic>))
          .toList();

      final filtered = widget.productIdFilter != null
          ? fetched.where((r) => r.productId == widget.productIdFilter).toList()
          : fetched;

      final total = data['total'] as int;

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _reviews.clear();
            _reviewsById.clear();
            _page = 1;
          }
          _reviews.addAll(filtered);
          for (final r in filtered) {
            _reviewsById[r.id] = r;
          }
          _hasMore = _reviews.length < total;
          if (!loadMore) {
            _page = 2;
          } else {
            _page++;
          }
          _invalidateListItemsCache();
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки отзывов: $e');
      rethrow;
    }
  }

  void _calculateUnansweredCount() {
    _unansweredCount = _questions.where((q) => !q.isAnswered).length;
    widget.onUnansweredCountChanged?.call(_unansweredCount);
  }

  Future<void> _showAnswerModal(Question question) async {
    await _ensureProductLoaded(question.productId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      builder: (context) => SupplierQAAnswerModal(
        question: question,
        product:
            _productMap[question.productId] ??
            Product(
              id: question.productId,
              name: question.productName,
              description: '',
              imageUrls: [question.productImage],
              rating: 0,
              reviewCount: 0,
              categories: [],
              nutritionalInfo: NutritionalInfo(
                calories: 0,
                protein: 0,
                fat: 0,
                carbohydrates: 0,
              ),
              ingredients: '',
              characteristics: {},
              suppliers: [],
              similarProducts: [],
              ratingDistribution: [],
            ),
        existingAnswer: question.answer?.answerText,
        onSubmit: (answerText) => question.isAnswered
            ? _editAnswer(question, answerText)
            : _submitAnswer(question, answerText),
      ),
    );
  }

  Future<void> _showResponseModal(ReviewEntry review) async {
    await _ensureProductLoaded(review.productId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      builder: (context) => SupplierQAResponseModal(
        review: review,
        product:
            _productMap[review.productId] ??
            Product(
              id: review.productId,
              name: review.productName,
              description: '',
              imageUrls: [review.productImage],
              rating: 0,
              reviewCount: 0,
              categories: [],
              nutritionalInfo: NutritionalInfo(
                calories: 0,
                protein: 0,
                fat: 0,
                carbohydrates: 0,
              ),
              ingredients: '',
              characteristics: {},
              suppliers: [],
              similarProducts: [],
              ratingDistribution: [],
            ),
        existingResponse: review.response?.responseText,
        onSubmit: (responseText) => review.response != null
            ? _editResponse(review, responseText)
            : _submitResponse(review, responseText),
      ),
    );
  }

  Future<void> _submitAnswer(Question question, String answerText) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: вы не авторизованы',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
      return;
    }

    try {
      final questionId = int.tryParse(question.id) ?? 0;
      await ApiService.answerQuestion(
        questionId: questionId,
        supplierUserId: userId,
        answerText: answerText,
      );

      if (mounted) {
        final existing = _questionsById[question.id];
        final questionIndex = existing != null
            ? _questions.indexOf(existing)
            : -1;
        if (questionIndex != -1) {
          final updatedQuestion = Question(
            id: question.id,
            productId: question.productId,
            userId: question.userId,
            userName: question.userName,
            questionText: question.questionText,
            createdAt: question.createdAt,
            isAnswered: true,
            answer: QuestionAnswer(
              id: '',
              questionId: question.id,
              supplierId: userId.toString(),
              supplierName: 'Поставщик',
              answerText: answerText,
              answeredAt: DateTime.now(),
            ),
            productName: question.productName,
            productImage: question.productImage,
          );

          setState(() {
            _questions[questionIndex] = updatedQuestion;
            _questionsById[updatedQuestion.id] = updatedQuestion;
            _calculateUnansweredCount();
            _invalidateListItemsCache();
            _invalidateQuestionsSplitCache();
          });
        }

        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.info,
            title: '',
            body: 'Ответ отправлен успешно',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: ${e.toString().replaceFirst('Exception: ', '')}',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    }
  }

  Future<void> _editAnswer(Question question, String newAnswerText) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: вы не авторизованы',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
      return;
    }

    try {
      await ApiService.updateQuestionAnswer(
        questionId: question.id,
        supplierUserId: userId,
        answerText: newAnswerText,
      );

      if (mounted) {
        final existing = _questionsById[question.id];
        final questionIndex = existing != null
            ? _questions.indexOf(existing)
            : -1;
        if (questionIndex != -1) {
          final updatedQuestion = Question(
            id: question.id,
            productId: question.productId,
            userId: question.userId,
            userName: question.userName,
            questionText: question.questionText,
            createdAt: question.createdAt,
            isAnswered: true,
            answer: QuestionAnswer(
              id: question.answer?.id ?? '',
              questionId: question.id,
              supplierId: userId.toString(),
              supplierName: question.answer?.supplierName ?? 'Поставщик',
              answerText: newAnswerText,
              answeredAt: DateTime.now(),
            ),
            productName: question.productName,
            productImage: question.productImage,
          );

          setState(() {
            _questions[questionIndex] = updatedQuestion;
            _questionsById[updatedQuestion.id] = updatedQuestion;
            _invalidateListItemsCache();
            _invalidateQuestionsSplitCache();
          });
        }

        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.info,
            title: '',
            body: 'Ответ обновлен успешно',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: ${e.toString().replaceFirst('Exception: ', '')}',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    }
  }

  Future<void> _submitResponse(ReviewEntry review, String responseText) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: вы не авторизованы',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
      return;
    }

    try {
      await ApiService.respondToReview(
        reviewId: review.id,
        supplierUserId: userId,
        responseText: responseText,
      );

      if (mounted) {
        final existingReview = _reviewsById[review.id];
        final reviewIndex = existingReview != null
            ? _reviews.indexOf(existingReview)
            : -1;
        if (reviewIndex != -1) {
          final updatedReview = ReviewEntry(
            id: review.id,
            orderId: review.orderId,
            orderItemId: review.orderItemId,
            productId: review.productId,
            productName: review.productName,
            productImage: review.productImage,
            reviewerName: review.reviewerName,
            rating: review.rating,
            reviewText: review.reviewText,
            createdAt: review.createdAt,
            response: ReviewResponse(
              id: '',
              reviewId: review.id,
              supplierId: userId.toString(),
              supplierName: 'Поставщик',
              responseText: responseText,
              respondedAt: DateTime.now(),
            ),
          );

          setState(() {
            _reviews[reviewIndex] = updatedReview;
            _reviewsById[updatedReview.id] = updatedReview;
            _invalidateListItemsCache();
          });
        }

        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.info,
            title: '',
            body: 'Ответ отправлен успешно',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: ${e.toString().replaceFirst('Exception: ', '')}',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    }
  }

  Future<void> _editResponse(ReviewEntry review, String newResponseText) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: вы не авторизованы',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
      return;
    }

    try {
      await ApiService.updateReviewResponse(
        reviewId: review.id,
        supplierUserId: userId,
        responseText: newResponseText,
      );

      if (mounted) {
        final existingReview = _reviewsById[review.id];
        final reviewIndex = existingReview != null
            ? _reviews.indexOf(existingReview)
            : -1;
        if (reviewIndex != -1) {
          final updatedReview = ReviewEntry(
            id: review.id,
            orderId: review.orderId,
            orderItemId: review.orderItemId,
            productId: review.productId,
            productName: review.productName,
            productImage: review.productImage,
            reviewerName: review.reviewerName,
            rating: review.rating,
            reviewText: review.reviewText,
            createdAt: review.createdAt,
            response: ReviewResponse(
              id: review.response?.id ?? '',
              reviewId: review.id,
              supplierId: userId.toString(),
              supplierName: review.response?.supplierName ?? 'Поставщик',
              responseText: newResponseText,
              respondedAt: DateTime.now(),
            ),
          );

          setState(() {
            _reviews[reviewIndex] = updatedReview;
            _reviewsById[updatedReview.id] = updatedReview;
            _invalidateListItemsCache();
          });
        }

        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.info,
            title: '',
            body: 'Ответ обновлен успешно',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessageSnackBar.show(
          context,
          Message(
            id: const Uuid().v4(),
            type: MessageType.notification,
            severity: MessageSeverity.error,
            title: '',
            body: 'Ошибка: ${e.toString().replaceFirst('Exception: ', '')}',
            timestamp: DateTime.now(),
            language: 'ru',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;

    return Scaffold(
      backgroundColor: palette.bgTop,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.bgTop, palette.bgBottom],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, palette),
                Expanded(child: _buildContent(palette)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorPalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.productIdFilter != null)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: palette.ink),
                  tooltip: 'Назад',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q&A',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    if (_unansweredCount > 0)
                      Text(
                        'Без ответов: $_unansweredCount',
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
                color: palette.accent,
                tooltip: 'Обновить',
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_TabType>(
              segments: [
                ButtonSegment(
                  value: _TabType.questions,
                  label: Text('Вопросы'),
                  icon: const Icon(Icons.help_outline),
                ),
                ButtonSegment(
                  value: _TabType.reviews,
                  label: Text('Отзывы'),
                  icon: const Icon(Icons.star_outline),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<_TabType> newSelection) {
                setState(() {
                  _selectedTab = newSelection.first;
                  _invalidateListItemsCache();
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: palette.bgBottom,
                foregroundColor: palette.muted,
                selectedForegroundColor: palette.card,
                selectedBackgroundColor: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorPalette palette) {
    switch (_pageState) {
      case _PageState.loading:
        return Center(child: CircularProgressIndicator(color: palette.accent));

      case _PageState.error:
        return RefreshIndicator(
          color: palette.accent,
          onRefresh: () => _loadData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _buildErrorBanner(_errorMessage ?? 'Неизвестная ошибка', palette),
              const SizedBox(height: 24),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _loadData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                  ),
                ),
              ),
            ],
          ),
        );

      case _PageState.empty:
        return RefreshIndicator(
          color: palette.accent,
          onRefresh: () => _loadData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [_buildEmptyState(palette)],
          ),
        );

      case _PageState.data:
        // Строим плоский список элементов один раз, чтобы ListView.builder
        // мог рендерить только видимые карточки
        final items = _getListItems();
        return RefreshIndicator(
          color: palette.accent,
          onRefresh: () => _loadData(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildListItemWidget(items[index], palette),
          ),
        );
    }
  }

  /// Формирует плоский список типизированных элементов для текущей вкладки.
  /// Разделение на типы позволяет itemBuilder строить виджеты лениво.
  List<_QAListItem> _buildListItems() {
    final items = <_QAListItem>[];

    if (_selectedTab == _TabType.questions) {
      final unanswered = _unansweredQuestions;
      final answered = _answeredQuestions;

      if (unanswered.isNotEmpty) {
        items.add(_SectionHeaderItem('Вопросы без ответов', unanswered.length));
        for (final q in unanswered) {
          items.add(_QuestionItem(q));
        }
        items.add(const _SpacerItem(12));
      }

      if (answered.isNotEmpty) {
        items.add(_AnsweredButtonItem(answered));
      }

      if (unanswered.isEmpty && answered.isEmpty) {
        items.add(const _EmptyTabItem('Нет вопросов'));
      }
    } else {
      if (_reviews.isNotEmpty) {
        items.add(_SectionHeaderItem('Отзывы', _reviews.length));
        for (final r in _reviews) {
          items.add(_ReviewItem(r));
        }
      } else {
        items.add(const _EmptyTabItem('Нет отзывов'));
      }
    }

    if (_isLoadingMore) {
      items.add(const _LoadingMoreItem());
    }

    return items;
  }

  Widget _buildListItemWidget(_QAListItem item, AppColorPalette palette) {
    return switch (item) {
      _SectionHeaderItem(:final title, :final count) => _buildSectionHeader(
        title,
        count,
        palette,
      ),
      _QuestionItem(:final question) => Padding(
        key: ValueKey('q_${question.id}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildQuestionCard(question, palette),
      ),
      _ReviewItem(:final review) => Padding(
        key: ValueKey('r_${review.id}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildReviewCard(review, palette),
      ),
      _AnsweredButtonItem(:final answeredQuestions) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _navigateToAnsweredQuestions(answeredQuestions),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              'Отвеченные вопросы (${answeredQuestions.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      _EmptyTabItem(:final message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
        ),
      ),
      _LoadingMoreItem() => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: palette.accent),
        ),
      ),
      _SpacerItem(:final height) => SizedBox(height: height),
    };
  }

  Widget _buildSectionHeader(String title, int count, AppColorPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.accentMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, AppColorPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: question.userAvatarUrl,
                displayName: question.userName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDate(question.createdAt),
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
              if (!question.isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Без ответа',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ExpandableTextBlock(
            question.questionText.trim().isEmpty
                ? 'Без текста'
                : question.questionText.trim(),
            textStyle: TextStyle(fontSize: 14, color: palette.ink, height: 1.4),
            actionColor: palette.accent,
            collapsedMaxLines: 3,
            moreLabel: 'Подробнее',
            lessLabel: 'Свернуть',
          ),
          if (question.isAnswered && question.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.line.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 14,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ответ продавца',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpandableTextBlock(
                    question.answer!.answerText,
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: palette.ink,
                      height: 1.4,
                    ),
                    actionColor: palette.accent,
                    collapsedMaxLines: 2,
                    moreLabel: 'Подробнее',
                    lessLabel: 'Свернуть',
                  ),
                ],
              ),
            ),
          ] else if (!question.isAnswered) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAnswerModal(question),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Ответить'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewEntry review, AppColorPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: review.userAvatarUrl,
                displayName: review.reviewerName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDate(review.createdAt),
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
              RatingStars(
                rating: review.rating.toDouble(),
                filledColor: palette.star,
                emptyColor: palette.muted.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpandableTextBlock(
            review.reviewText.trim().isEmpty
                ? 'Без текста'
                : review.reviewText.trim(),
            textStyle: TextStyle(fontSize: 14, color: palette.ink, height: 1.4),
            actionColor: palette.accent,
            collapsedMaxLines: 3,
            moreLabel: 'Подробнее',
            lessLabel: 'Свернуть',
          ),
          if (review.response != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accentMist,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.line.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 14,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ответ продавца',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpandableTextBlock(
                    review.response!.responseText,
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: palette.ink,
                      height: 1.4,
                    ),
                    actionColor: palette.accent,
                    collapsedMaxLines: 2,
                    moreLabel: 'Подробнее',
                    lessLabel: 'Свернуть',
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showResponseModal(review),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Ответить'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, AppColorPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: palette.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: palette.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorPalette palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: palette.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == _TabType.questions ? 'Нет вопросов' : 'Нет отзывов',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == _TabType.questions
                ? 'Покупатели еще не задавали вопросы'
                : 'Покупатели еще не оставляли отзывы',
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
        ],
      ),
    );
  }

  void _navigateToAnsweredQuestions(List<Question> answeredQuestions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AnsweredQuestionsPage(
          questions: answeredQuestions,
          palette: context.colorPalette,
        ),
      ),
    );
  }
}

class _AnsweredQuestionsPage extends StatelessWidget {
  final List<Question> questions;
  final AppColorPalette palette;

  const _AnsweredQuestionsPage({
    required this.questions,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.bgTop,
      appBar: AppBar(
        backgroundColor: palette.card,
        title: Text(
          'Отвеченные вопросы',
          style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: palette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.bgTop, palette.bgBottom],
                ),
              ),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.line.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            avatarUrl: question.userAvatarUrl,
                            displayName: question.userName,
                            radius: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.userName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: palette.ink,
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatDate(question.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Отвечено',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: palette.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ExpandableTextBlock(
                        question.questionText.trim().isEmpty
                            ? 'Без текста'
                            : question.questionText.trim(),
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: palette.ink,
                          height: 1.4,
                        ),
                        actionColor: palette.accent,
                        collapsedMaxLines: 3,
                        moreLabel: 'Подробнее',
                        lessLabel: 'Свернуть',
                      ),
                      if (question.answer != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.accentMist,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: palette.line.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.store_rounded,
                                    size: 14,
                                    color: palette.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ответ продавца',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: palette.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ExpandableTextBlock(
                                question.answer!.answerText,
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: palette.ink,
                                  height: 1.4,
                                ),
                                actionColor: palette.accent,
                                collapsedMaxLines: 2,
                                moreLabel: 'Подробнее',
                                lessLabel: 'Свернуть',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
