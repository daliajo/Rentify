import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WishlistService {
  WishlistService._internal() {
    _authSubscription = _auth.authStateChanges().listen(_handleUserChanged);
    _handleUserChanged(_auth.currentUser);
  }

  static final WishlistService _instance = WishlistService._internal();

  factory WishlistService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _wishlistSubscription;

  final ValueNotifier<Set<String>> _wishlistIds = ValueNotifier(<String>{});

  ValueListenable<Set<String>> get wishlistIds => _wishlistIds;

  void dispose() {
    _authSubscription.cancel();
    _wishlistSubscription?.cancel();
  }

  void _handleUserChanged(User? user) {
    _wishlistSubscription?.cancel();
    if (user == null) {
      _wishlistIds.value = <String>{};
      return;
    }

    _wishlistSubscription = _userWishlistRef(user.uid).snapshots().listen(
      (snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toSet();
        if (!setEquals(ids, _wishlistIds.value)) {
          _wishlistIds.value = ids;
        }
      },
      onError: (_) {
        _wishlistIds.value = _wishlistIds.value;
      },
    );
  }

  CollectionReference<Map<String, dynamic>> _userWishlistRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('wishlist');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> wishlistStream(String uid) {
    return _userWishlistRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  bool isWishlisted(String productId) {
    return _wishlistIds.value.contains(productId);
  }

  Future<void> toggleWishlist({
    required String productId,
    required Map<String, dynamic> productSnapshot,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const WishlistException(
          'Please sign in to manage your wishlist items.');
    }

    final docRef = _userWishlistRef(user.uid).doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.delete();
      return;
    }

    await docRef.set({
      'itemId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeWishlistItem(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const WishlistException(
          'Please sign in to manage your wishlist items.');
    }
    await _userWishlistRef(user.uid).doc(productId).delete();
  }
}

class WishlistException implements Exception {
  final String message;
  const WishlistException(this.message);

  @override
  String toString() => message;
}
