import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'chat_service.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Center(
                child: Image.asset("assets/images/logoo.png", width: 50),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.chatListStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data!.docs;
                    if (chats.isEmpty) {
                      return const Center(child: Text("No chats yet"));
                    }

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat =
                            chats[index].data() as Map<String, dynamic>;

                        final isCustomer = chat['customerId'] == currentUserId;
                        final deletedFor = chat['deletedFor'] ?? {};

                        if (deletedFor[isCustomer ? 'customer' : 'renter'] ==
                            true) {
                          return const SizedBox.shrink();
                        }

                        final unread = chat['unreadCount']
                                ?[isCustomer ? 'customer' : 'renter'] ??
                            0;

                        final otherUserId =
                            isCustomer ? chat['renterId'] : chat['customerId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(otherUserId)
                              .get(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const SizedBox(height: 70);
                            }

                            final user =
                                userSnap.data!.data() as Map<String, dynamic>?;

                            final firstName =
                                (user?['firstName'] ?? '').toString();
                            final lastName =
                                (user?['lastName'] ?? '').toString();

                            final displayName =
                                ('$firstName $lastName').trim().isEmpty
                                    ? 'User'
                                    : ('$firstName $lastName').trim();

                            final profileImage =
                                user?['profileImage'] as String?;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onLongPress: () {
                                  _showDeleteDialog(
                                    context,
                                    chats[index].id,
                                    isCustomer,
                                  );
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        chatId: chats[index].id,
                                        name: displayName,
                                        avatar: profileImage ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: profileImage != null &&
                                                profileImage.isNotEmpty
                                            ? NetworkImage(profileImage)
                                            : null,
                                        child: profileImage == null ||
                                                profileImage.isEmpty
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.grey,
                                                size: 28,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                if (unread > 0)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.deepOrange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      unread.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              chat['lastMessage'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black54,
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
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String chatId, bool isCustomer) {
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
                  .doc(chatId)
                  .update({
                'deletedFor.${isCustomer ? 'customer' : 'renter'}': true,
              });
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
