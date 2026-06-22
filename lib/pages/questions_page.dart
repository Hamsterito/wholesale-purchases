import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import 'dart:math' as math;
import '../core/ui/theme/app_dimensions.dart';
import '../services/api/api_service.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import '../services/storage/auth_storage.dart';
import '../theme/app_color_palette.dart';
import '../widgets/pages/question_card.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import '../widgets/smart_image.dart';
import '../widgets/smooth_sheet.dart';

enum _PageState { loading, error, empty, data }

class QuestionsPage extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;

  const QuestionsPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.productImage,
  });

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  // Только текущая + следующая страница хранятся в памяти
  final List<Question> _questions = [];
  _PageState _pageState = _PageState.loading;
  String _errorMessage = '';
  int _totalQuestions = 0;

  // Номер следующей страницы для загрузки
  int _nextPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Смещение первого элемента в _questions относительно всего списка
  // (нужно для корректного отображения позиции при виртуальном скролле)
  int _windowOffset = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_questions.isEmpty || _isLoadingMore || !_hasMore) return;
    // Загружаем следующую страницу при достижении 80% списка
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      _fetchQuestions(loadMore: true);
    }
  }

  Future<void> _fetchQuestions({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;

    if (!loadMore) {
      setState(() => _pageState = _PageState.loading);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final pageToLoad = loadMore ? _nextPage : 1;
      final data = await ApiService.getProductQuestions(
        productId: widget.productId,
        page: pageToLoad,
        limit: _limit,
      );

      final List<Question> fetched = (data['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      final total = data['total'] as int;

      if (mounted) {
        setState(() {
          _totalQuestions = total;

          if (!loadMore) {
            // Первая загрузка: сбрасываем окно
            _questions.clear();
            _windowOffset = 0;
            _nextPage = 2;
          } else {
            // Подгрузка следующей страницы: выбрасываем старые страницы,
            // оставляем только текущую + новую (две страницы в памяти)
            if (_questions.length > _limit) {
              final removed = _questions.length - _limit;
              _questions.removeRange(0, removed);
              _windowOffset += removed;
            }
            _nextPage = pageToLoad + 1;
          }

          _questions.addAll(fetched);
          _hasMore = (_windowOffset + _questions.length) < total;

          if (!loadMore) {
            _pageState = _questions.isEmpty
                ? _PageState.empty
                : _PageState.data;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.l10n.questionsErrorLoading(e.toString());
          _pageState = _PageState.error;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _showAskModal() {
    _questionController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: smoothBottomSheetController(context),
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AskQuestionModal(
        productId: widget.productId,
        productName: widget.productName,
        productImage: widget.productImage,
        questionController: _questionController,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchQuestions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? theme.scaffoldBackgroundColor
        : palette.bgTop;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: pageBackground,
      body: Stack(
        children: [
          if (isDark)
            Positioned.fill(child: ColoredBox(color: pageBackground))
          else
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
          Column(
            children: [
              _buildHeader(context, palette),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: _buildBody(palette),
                ),
              ),
            ],
          ),
        ],
      ),
floatingActionButton: FloatingActionButton.extended(
         onPressed: _showAskModal,
         backgroundColor: palette.accent,
         foregroundColor: Colors.white,
         icon: const Icon(Icons.help_outline),
         label: Text(context.l10n.questionAskButton),
       ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: null),
    ),
  );
}

  Widget _buildHeader(BuildContext context, AppColorPalette palette) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: palette.ink),
            tooltip: context.l10n.getString('auto_nazad'),
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
                  context.l10n.getString('auto_voprosyOTovare'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.questionsTotalCount(_totalQuestions),
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColorPalette palette) {
    switch (_pageState) {
      case _PageState.loading:
        return const Center(child: CircularProgressIndicator());

      case _PageState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: palette.muted),
              const SizedBox(height: 16),
              Text(
                context.l10n.getString('auto_oshibka'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: palette.muted),
                ),
              ),
              const SizedBox(height: 24),
ElevatedButton(
                 onPressed: () => _fetchQuestions(),
                 child: Text(context.l10n.retry),
               ),
            ],
          ),
        );

      case _PageState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 48, color: palette.muted),
              const SizedBox(height: 16),
              Text(
                context.l10n.getString('auto_netVoprosov'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.getString('auto_budtePervymKtoZadastV'),
                style: TextStyle(fontSize: 14, color: palette.muted),
              ),
              const SizedBox(height: 24),
FilledButton.icon(
                 onPressed: _showAskModal,
                 icon: const Icon(Icons.help_outline),
                 label: Text(context.l10n.questionAskButton),
               ),
            ],
          ),
        );

      case _PageState.data:
        return RefreshIndicator(
          onRefresh: () => _fetchQuestions(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _questions.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _questions.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final question = _questions[index];
              return KeyedSubtree(
                // Стабильный ключ предотвращает лишние перестройки при сдвиге окна
                key: ValueKey(question.id),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuestionCard(question: question, palette: palette),
                ),
              );
            },
          ),
        );
    }
  }
}

class _AskQuestionModal extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;
  final TextEditingController questionController;
  final VoidCallback onSuccess;

  const _AskQuestionModal({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.questionController,
    required this.onSuccess,
  });

  @override
  State<_AskQuestionModal> createState() => _AskQuestionModalState();
}

class _AskQuestionModalState extends State<_AskQuestionModal> {
  bool _isSubmitting = false;
  String? _validationError;
  String? _submissionError;

  static const int _minLength = 10;
  static const int _maxLength = 250;

  @override
  void initState() {
    super.initState();
    _validateInput();
  }

  void _validateInput() {
    final text = widget.questionController.text.trim();
    setState(() {
      if (text.isEmpty) {
        _validationError = null;
      } else if (text.length < _minLength) {
        _validationError =
            context.l10n.questionsMinCharsError(_minLength, text.length);
      } else {
        _validationError = null;
      }
      _submissionError = null;
    });
  }

  bool get _isValid {
    final text = widget.questionController.text.trim();
    return text.length >= _minLength && text.length <= _maxLength;
  }

  Future<void> _submitQuestion() async {
    if (!_isValid || _isSubmitting) return;

    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      if (mounted) {
        setState(() {
          _submissionError = context.l10n.getString('auto_vyNeAvtorizovany');
        });
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.askQuestion(
        productId: widget.productId,
        userId: userId,
        questionText: widget.questionController.text.trim(),
      );

      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submissionError = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colorPalette;
    final questionText = widget.questionController.text;
    final answerLength = questionText.length;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: math.max(MediaQuery.viewInsetsOf(context).bottom, AppDimensions.minBottomSafePadding),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  context.l10n.getString('auto_zadatVopros'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),

              // Product preview
              if (widget.productImage.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SmartImage(
                          path: widget.productImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.getString('auto_tovar'),
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.productName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: palette.line, height: 1),
              ],

              // Question input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.getString('auto_vashVopros'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.questionController,
                      onChanged: (_) => _validateInput(),
                      maxLines: 5,
                      maxLength: _maxLength,
                      enabled: !_isSubmitting,
                      style: TextStyle(color: palette.ink),
                      decoration: InputDecoration(
                        hintText:
                            context.l10n.questionsEnterPrompt(_minLength),
                        hintStyle: TextStyle(color: palette.muted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: palette.accent,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: palette.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: palette.error,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: palette.bgTop,
                        contentPadding: const EdgeInsets.all(12),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$answerLength/$_maxLength',
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                        if (_validationError != null)
                          Text(
                            _validationError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Error message
              if (_submissionError != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.error.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: palette.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: palette.line),
                        ),
child: Text(
                           context.l10n.cancel,
                           style: TextStyle(color: palette.ink),
                         ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isSubmitting
                          ? FilledButton(
                              onPressed: null,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accent,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : FilledButton(
                              onPressed: _isValid ? _submitQuestion : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.accent,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: Text(context.l10n.send),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
