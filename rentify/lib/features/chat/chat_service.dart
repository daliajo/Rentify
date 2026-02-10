import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> chatListStream() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> messageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = _auth.currentUser!.uid;
    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatSnap = await chatRef.get();
    final chat = chatSnap.data()!;

    final customerId = chat['customerId'];
    final isCustomer = customerId == uid;

    await chatRef.collection('messages').add({
      'text': text,
      'senderId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'delivered': false,
      'seen': false,
    });

    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.${isCustomer ? 'renter' : 'customer'}':
          FieldValue.increment(1),
    });
  }

  Future<String> getOrCreateChat({
    required String renterId,
  }) async {
    final uid = _auth.currentUser!.uid;

    final customerQuery = await _firestore
        .collection('chats')
        .where('customerId', isEqualTo: uid)
        .where('renterId', isEqualTo: renterId)
        .limit(1)
        .get();

    if (customerQuery.docs.isNotEmpty) {
      final chatId = customerQuery.docs.first.id;

      await _firestore.collection('chats').doc(chatId).update({
        'deletedFor.customer': false,
        'deletedFor.renter': false,
      });

      return chatId;
    }

    final doc = await _firestore.collection('chats').add({
      'customerId': uid,
      'renterId': renterId,
      'participants': [uid, renterId],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'deletedFor': {
        'customer': false,
        'renter': false,
      },
      'unreadCount': {
        'customer': 0,
        'renter': 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
}
