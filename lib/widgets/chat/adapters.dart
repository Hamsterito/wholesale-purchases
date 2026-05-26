import '../../models/support_message.dart';
import 'chat_thread_view.dart';

/// Адаптер SupportMessage → ChatBubbleData. Состояние доставки всегда sent;
/// senderId берём из senderUserId, иначе из userId самого чата.
ChatBubbleData chatBubbleFromSupportMessage(SupportMessage m) {
  return ChatBubbleData(
    id: m.id,
    senderId: m.senderUserId ?? m.userId,
    body: m.text,
    createdAt: m.createdAt,
  );
}

List<ChatBubbleData> chatBubblesFromSupportMessages(
  Iterable<SupportMessage> messages,
) {
  return messages.map(chatBubbleFromSupportMessage).toList(growable: false);
}
