class Question {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String questionText;
  final DateTime createdAt;
  final bool isAnswered;
  final QuestionAnswer? answer;
  final String productName;
  final String productNameKk;
  final String productImage;

  Question({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.questionText,
    required this.createdAt,
    required this.isAnswered,
    this.answer,
    required this.productName,
    this.productNameKk = '',
    required this.productImage,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: _parseAvatarUrl(json['userAvatarUrl']),
      questionText: json['questionText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isAnswered: json['isAnswered'] ?? false,
      answer: json['answer'] != null ? QuestionAnswer.fromJson(json['answer']) : null,
      productName: json['productName'] ?? '',
      productNameKk: json['productNameKk'] ?? json['product_name_kk'] ?? '',
      productImage: json['productImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'questionText': questionText,
        'createdAt': createdAt.toIso8601String(),
        'isAnswered': isAnswered,
        'answer': answer?.toJson(),
        'productName': productName,
        'productNameKk': productNameKk,
        'productImage': productImage,
      };
}

extension QuestionLocalization on Question {
  String localizedProductName(dynamic context) {
    try {
      final lang = (context as dynamic).currentLanguage;
      if (lang?.toString() == 'LanguageCode.kazakh' && productNameKk.trim().isNotEmpty) {
        return productNameKk;
      }
    } catch (_) {}
    return productName;
  }
}

// Пустую строку трактуем как отсутствие аватарки - бекенд может прислать "" вместо null.
String? _parseAvatarUrl(dynamic value) {
  final str = value?.toString().trim() ?? '';
  return str.isEmpty ? null : str;
}

class QuestionAnswer {
  final String id;
  final String questionId;
  final String? supplierId;
  final String supplierName;
  final String answerText;
  final DateTime answeredAt;

  QuestionAnswer({
    required this.id,
    required this.questionId,
    required this.supplierId,
    required this.supplierName,
    required this.answerText,
    required this.answeredAt,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
        id: json['id'] ?? '',
        questionId: json['questionId'] ?? '',
        supplierId: json['supplierId']?.toString(),
        supplierName: json['supplierName'] ?? '',
        answerText: json['answerText'] ?? '',
        answeredAt: DateTime.parse(json['answeredAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'answerText': answerText,
        'answeredAt': answeredAt.toIso8601String(),
      };
}
