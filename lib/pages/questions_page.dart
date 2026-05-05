import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../widgets/question_card.dart';
import '../widgets/main_bottom_nav.dart';

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
  final List<Question> _questions = [];
  bool _isLoading = true;
  int _totalQuestions = 0;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchQuestions(loadMore: true);
    }
  }

  Future<void> _fetchQuestions({bool loadMore = false}) async {
    if (_isLoading || (!_hasMore && loadMore)) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProductQuestions(
        productId: widget.productId,
        page: loadMore ? _page : 1,
        limit: _limit,
      );
      final List<Question> fetched = (data['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      final total = data['total'] as int;
      if (mounted) {
        setState(() {
          _totalQuestions = total;
          if (!loadMore) _questions.clear();
          _questions.addAll(fetched);
          _hasMore = _questions.length < total;
          _page = loadMore ? _page + 1 : 2;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAskModal() {
    _questionController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.productImage.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.productImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _questionController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Введите ваш вопрос...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: ElevatedButton(
                onPressed: () async {
                  final text = _questionController.text.trim();
                  if (text.length < 10) return;
                  Navigator.pop(ctx);
                  await ApiService.askQuestion(
                    productId: widget.productId,
                    userId: 1,
                    questionText: text,
                  );
                  _fetchQuestions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6288D5),
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вопросы о товаре'),
        actions: [
          TextButton(
            onPressed: _showAskModal,
            child: const Text('Задать вопрос'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$_totalQuestions вопросов',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchQuestions(),
        child: _questions.isEmpty && !_isLoading
            ? Center(
                child: Text(
                  'Пока нет вопросов. Задайте первый вопрос!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _questions.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _questions.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return QuestionCard(question: _questions[index]);
                },
              ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: null),
    );
  }
}