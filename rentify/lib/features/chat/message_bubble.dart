import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool delivered;
  final bool seen;
  final Timestamp? createdAt;
  final String? replyToText;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.delivered,
    required this.seen,
    this.createdAt,
    this.replyToText,
    this.onLongPress,
  });

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final d = timestamp.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.deepOrange : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isMe ? const Radius.circular(18) : const Radius.circular(0),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(.2)
                        : Colors.black.withOpacity(.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    replyToText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.black45,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Icon(
                      seen
                          ? Icons.done_all
                          : delivered
                              ? Icons.done_all
                              : Icons.done,
                      size: 14,
                      color: seen ? Colors.blue : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
