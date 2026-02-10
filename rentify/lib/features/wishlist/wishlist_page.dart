import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../cart/cart_data.dart';
import '../store/product_detail_page.dart';
import 'wishlist_service.dart';
import 'widgets/wishlist_toggle_button.dart';

const kOrange = Color(0xFFFF7A00);

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _WishlistScaffold(
        body: Center(
          child: Text(
            'Please sign in to see your wishlist.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final wishlistService = WishlistService();
    return _WishlistScaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: wishlistService.wishlistStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No items in wishlist",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final items = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${items.length} Items',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'in wishlist',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final doc = items[index];

                      return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('rentify_items')
                            .doc(doc.id)
                            .get(),
                        builder: (context, itemSnap) {
                          if (itemSnap.connectionState ==
                                  ConnectionState.done &&
                              (!itemSnap.hasData || !itemSnap.data!.exists)) {
                            WishlistService().removeWishlistItem(doc.id);
                            return const SizedBox.shrink();
                          }

                          if (!itemSnap.hasData) {
                            return const SizedBox.shrink();
                          }

                          final data = itemSnap.data!.data()!;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailPage(productId: doc.id),
                                ),
                              );
                            },
                            child: _WishlistCard(
                              productId: doc.id,
                              data: data,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;

  const _WishlistCard({
    required this.productId,
    required this.data,
  });

  @override
  State<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends State<_WishlistCard> {
  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data["imageUrl"] ?? "";
    final priceValue = widget.data["price"];
    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0.0;
    final priceLabel = "${price.toStringAsFixed(2)} JOD/day";
    final name = widget.data["name"] ?? "Unnamed Item";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 35),
                          );
                        },
                      )
                    : Container(
                        height: 160,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 35),
                      ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: WishlistToggleButton(
                  productId: widget.productId,
                  productSnapshot: widget.data,
                  background: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kOrange,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _addToCart(context),
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: kOrange,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      final itemDoc = await FirebaseFirestore.instance
          .collection("rentify_items")
          .doc(widget.productId)
          .get();

      if (!itemDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item not found'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final itemData = itemDoc.data()!;
      final itemId = widget.productId;
      final renterId = itemData["renterId"]?.toString() ?? "";

      if (renterId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add item: missing renter information.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final itemExists = cartItems.any(
        (item) => item.itemId == itemId,
      );

      if (itemExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item already in cart'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      int _parseQuantity(dynamic value, {int fallback = 1}) {
        if (value is num && value > 0) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null && parsed > 0) return parsed;
        }
        return fallback;
      }

      final totalQuantity =
          _parseQuantity(itemData["totalQuantity"] ?? itemData["quantity"]);
      final availableQuantity = _parseQuantity(
        itemData["availableQuantity"],
        fallback: totalQuantity,
      );

      if (availableQuantity <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This item is out of stock.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      double depositAmount = 0.0;
      final deposit = itemData["depositAmount"];
      if (deposit is num && deposit > 0) {
        depositAmount = deposit.toDouble();
      } else {
        final pricePerDay = itemData["price"];
        final depositRate = itemData["depositRate"];
        if (pricePerDay is num &&
            depositRate is num &&
            pricePerDay > 0 &&
            depositRate > 0) {
          depositAmount = pricePerDay.toDouble() * depositRate.toDouble();
        }
      }

      final imageUrl = widget.data["imageUrl"] ?? "";
      final name = widget.data["name"] ?? "Unnamed Item";
      final priceValue = widget.data["price"];
      final price = priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue?.toString() ?? '') ?? 0.0;

      cartItems.add(
        CartItemModel(
          itemId: itemId,
          renterId: renterId,
          imageUrl: imageUrl,
          title: name,
          price: price,
          depositAmount: depositAmount,
          availableQuantity: availableQuantity,
          totalQuantity: totalQuantity,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added to cart'),
          backgroundColor: kOrange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class _WishlistScaffold extends StatelessWidget {
  const _WishlistScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            color: kOrange,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
