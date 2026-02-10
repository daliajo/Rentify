import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_bubble.dart';
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String name;
  final String avatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.name,
    required this.avatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  String? _replyToText;

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
    _markMessagesDelivered();
  }

  Future<void> _markMessagesDelivered() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .get();

    for (var d in snap.docs) {
      if (d['senderId'] != uid && d['delivered'] == false) {
        await d.reference.update({'delivered': true});
      }
    }
  }

  Future<void> _markChatAsRead() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final snap = await chatRef.get();
    if (!snap.exists) return;
    final customerId = snap['customerId'];
    final isCustomer = customerId == uid;
    await chatRef.update({
      'unreadCount.${isCustomer ? 'customer' : 'renter'}': 0,
    });
  }

  Future<void> _markMessagesSeen() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .get();

    for (var d in snap.docs) {
      if (d['senderId'] != uid && d['seen'] == false) {
        await d.reference.update({'seen': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),

            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  widget.avatar.isNotEmpty ? NetworkImage(widget.avatar) : null,
              child: widget.avatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey, size: 20)
                  : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                onTap: () {
                  Future.microtask(() {
                    _showDeleteDialogFromChatScreen();
                  });
                },
                child: const Text('Delete chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.messageStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesSeen();
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[docs.length - 1 - index].data()
                        as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;

                    return Dismissible(
                      key: ValueKey(docs[docs.length - 1 - index].id),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) async {
                        setState(() {
                          _replyToText = data['text'];
                        });
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child:
                            const Icon(Icons.reply, color: Colors.deepOrange),
                      ),
                      child: MessageBubble(
                        text: data['text'],
                        isMe: isMe,
                        delivered: data['delivered'] ?? false,
                        seen: data['seen'] ?? false,
                        createdAt: data['createdAt'],
                        replyToText: data['replyToText'],
                        onLongPress: () {
                          setState(() => _replyToText = data['text']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_replyToText != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: $_replyToText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _replyToText = null),
                  ),
                ],
              ),
            ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepOrange),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'delivered': false,
      'seen': false,
      'replyToText': _replyToText,
    });

    setState(() => _replyToText = null);
    _controller.clear();
  }

  void _showDeleteDialogFromChatScreen() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final chatSnap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    if (!chatSnap.exists) return;

    final customerId = chatSnap['customerId'];
    final isCustomer = customerId == uid;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete chat?"),
        content: const Text("This will remove the chat only for you."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .update({
                'deletedFor.${isCustomer ? 'customer' : 'renter'}': true,
              });

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
