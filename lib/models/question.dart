class Question {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String questionText;
  final DateTime createdAt;
  final bool isAnswered;
  final QuestionAnswer? answer;
  final String productName;
  final String productImage;

  Question({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.questionText,
    required this.createdAt,
    required this.isAnswered,
    this.answer,
    required this.productName,
    required this.productImage,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      questionText: json['questionText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isAnswered: json['isAnswered'] ?? false,
      answer: json['answer'] != null ? QuestionAnswer.fromJson(json['answer']) : null,
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'questionText': questionText,
        'createdAt': createdAt.toIso8601String(),
        'isAnswered': isAnswered,
        'answer': answer?.toJson(),
        'productName': productName,
        'productImage': productImage,
      };
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