import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RenterDashboard extends StatefulWidget {
  const RenterDashboard({super.key});

  @override
  State<RenterDashboard> createState() => _RenterDashboardState();
}

class _RenterDashboardState extends State<RenterDashboard> {
  final Color orange = const Color(0xFFFF8A3D);

  Stream<int> _getItemCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('rentify_items')
        .where('renterId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getRentedCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('renterId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double> _getEarningsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0.0);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('renterId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final amount = data['grandTotal'] ?? 0;

        if (amount is num) {
          total += amount.toDouble();
        } else if (amount is String) {
          final parsed = double.tryParse(amount);
          if (parsed != null) {
            total += parsed;
          }
        }
      }

      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<int>(
                stream: _getItemCountStream(),
                builder: (context, snapshot) {
                  return _buildSummaryCard(
                    "My Items",
                    (snapshot.data ?? 0).toString(),
                    Icons.inventory_2_outlined,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: _getRentedCountStream(),
                builder: (context, snapshot) {
                  return _buildSummaryCard(
                    "Rented",
                    (snapshot.data ?? 0).toString(),
                    Icons.assignment_turned_in,
                  );
                },
              ),
              StreamBuilder<double>(
                stream: _getEarningsStream(),
                builder: (context, snapshot) {
                  return _buildSummaryCard(
                    "Earnings",
                    "${(snapshot.data ?? 0).toStringAsFixed(2)} JOD",
                    Icons.payments_outlined,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 25),
          const Text(
            "My Items",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          user == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text(
                      "Please sign in to view your items.",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rentify_items')
                      .where('renterId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            "No items yet — tap 'Add New Item' to upload.",
                            style:
                                TextStyle(color: Colors.black54, fontSize: 15),
                          ),
                        ),
                      );
                    }

                    final items = snapshot.data!.docs;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.70,
                      ),
                      itemBuilder: (context, index) {
                        final doc = items[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final totalQty = _parseQuantity(data['totalQuantity']);
                        final availableQty = data['availableQuantity'] is int
                            ? data['availableQuantity']
                            : 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailsPage(
                                  itemId: doc.id,
                                  itemData: data,
                                ),
                              ),
                            );
                          },
                          child: _buildItemCard(
                            data['imageUrl'] ?? '',
                            data['name'] ?? '',
                            data['status'] ?? 'Available',
                            availableQty,
                            totalQty,
                          ),
                        );
                      },
                    );
                  },
                )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: orange, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildItemCard(
    String imageUrl,
    String name,
    String status,
    int availableQuantity,
    int totalQuantity,
  ) {
    final bool isRented = availableQuantity <= 0;
    final bool isAvailable = !isRented;
    final int safeAvailable = availableQuantity >= 0 ? availableQuantity : 0;
    final int safeTotal = totalQuantity > 0
        ? totalQuantity
        : (safeAvailable > 0 ? safeAvailable : 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 400,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 45),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isRented ? Icons.cancel : Icons.check_circle,
                      color: isRented ? Colors.redAccent : Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isRented ? "Rented" : "Available",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRented ? Colors.redAccent : Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Quantity: $safeAvailable of $safeTotal",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _parseQuantity(dynamic value, {int fallback = 1}) {
    if (value is num && value > 0) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }
}
