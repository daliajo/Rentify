import 'package:cloud_firestore/cloud_firestore.dart';

class ItemStatusService {
  static final ItemStatusService _instance = ItemStatusService._internal();
  factory ItemStatusService() => _instance;
  ItemStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateExpiredRentals() async {
    try {
      final now = Timestamp.now();

      final expiredOrders = await _firestore
          .collection('orders')
          .where('endDate', isLessThan: now)
          .get();

      if (expiredOrders.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      final restockMap = <String, int>{};
      final ordersToComplete = <DocumentReference<Map<String, dynamic>>>[];

      for (final orderDoc in expiredOrders.docs) {
        final orderData = orderDoc.data();
        final itemId = orderData['itemId'] as String?;
        final qty = (orderData['selectedQuantity'] as num?)?.toInt() ?? 1;

        if (itemId != null && itemId.isNotEmpty) {
          restockMap[itemId] = (restockMap[itemId] ?? 0) + qty;
          ordersToComplete.add(orderDoc.reference);
        }
      }

      for (final entry in restockMap.entries) {
        final itemId = entry.key;
        final itemRef = _firestore.collection('rentify_items').doc(itemId);
        final itemDoc = await itemRef.get();

        if (itemDoc.exists && entry.value > 0) {
          final itemData = itemDoc.data();
          final totalQuantity = _parseQuantity(itemData?['totalQuantity']);
          final availableQuantity = _parseQuantity(
            itemData?['availableQuantity'],
            fallback: totalQuantity,
          );
          final newAvailable =
              (availableQuantity + entry.value).clamp(0, totalQuantity);

          batch.update(itemRef, {
            'availableQuantity': newAvailable,
            'totalQuantity': totalQuantity,
            'status': newAvailable > 0 ? 'available' : 'rented',
          });
        }
      }

      for (final orderRef in ordersToComplete) {
        batch.update(orderRef, {'paymentStatus': 'completed'});
      }

      if (restockMap.isNotEmpty || ordersToComplete.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error updating expired rentals: $e');
    }
  }

  Future<bool> isItemAvailable(String itemId) async {
    try {
      final itemDoc =
          await _firestore.collection('rentify_items').doc(itemId).get();

      if (!itemDoc.exists) return false;

      final itemData = itemDoc.data();
      final status = (itemData?['status'] ?? '').toString().toLowerCase();

      final availableQuantity = _parseQuantity(
        itemData?['availableQuantity'],
        fallback: _parseQuantity(itemData?['totalQuantity'], fallback: 0),
      );

      if (availableQuantity > 0) return true;

      if (status == 'available') return true;

      if (status == 'rented') {
        final now = Timestamp.now();
        final activeOrders = await _firestore
            .collection('orders')
            .where('itemId', isEqualTo: itemId)
            .where('endDate', isGreaterThan: now)
            .where('paymentStatus', isEqualTo: 'pending')
            .limit(1)
            .get();

        return activeOrders.docs.isEmpty;
      }

      return false;
    } catch (e) {
      print('Error checking item availability: $e');
      return false;
    }
  }

  int _parseQuantity(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }
}
