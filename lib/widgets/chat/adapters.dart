import '../../models/support_message.dart';
import 'chat_thread_view.dart';

/// Адаптер SupportMessage → ChatBubbleData. Состояние доставки всегда sent;
/// senderId берём из senderUserId, иначе из userId самого чата.
/// senderName приходит снаружи - в SupportMessage его нет, а UserAvatar
/// нужен для placeholder-инициала, если у собеседника нет картинки.
ChatBubbleData chatBubbleFromSupportMessage(
  SupportMessage m, {
  String senderName = '',
}) {
  return ChatBubbleData(
    id: m.id,
    senderId: m.senderUserId ?? m.userId,
    body: m.text,
    createdAt: m.createdAt,
    avatarUrl: m.senderAvatarUrl,
    senderName: senderName,
  );
}

List<ChatBubbleData> chatBubblesFromSupportMessages(
  Iterable<SupportMessage> messages, {
  String counterpartName = '',
}) {
  return messages
      .map((m) => chatBubbleFromSupportMessage(m, senderName: counterpartName))
      .toList(growable: false);
}
