import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../chat/chat_service.dart';
import '../chat/chat_screen.dart';
import '../cart/cart_data.dart';
import '../wishlist/widgets/wishlist_toggle_button.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  bool hasRentedItem = false;

  static const Color kOrange = Color(0xFFFF7A00);

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _checkRentalStatus();
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('rentify_items')
        .doc(widget.productId)
        .get();

    if (!doc.exists) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      productData = doc.data();
      isLoading = false;
    });
  }

  Future<void> _checkRentalStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .where('itemId', isEqualTo: widget.productId)
        .limit(1)
        .get();

    setState(() {
      hasRentedItem = snap.docs.isNotEmpty;
    });
  }


  bool get isRented {
    final qty = productData?['availableQuantity'];
    return qty is int && qty <= 0;
  }

  String get imageUrl => productData?['imageUrl'] ?? '';
  String get name => productData?['name'] ?? 'Unnamed Item';
  String get description => productData?['description'] ?? '';
  double get price => (productData?['price'] as num?)?.toDouble() ?? 0;

  double get deposit {
    final direct = productData?['depositAmount'];
    if (direct is num && direct > 0) return direct.toDouble();

    final rate = productData?['depositRate'];
    if (rate is num && rate > 0) return price * rate;

    return 0;
  }

  bool get isOwner {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return productData?['renterId'] == user.uid;
  }

  int get availableQuantity {
    final v = productData?['availableQuantity'];
    if (v is int) return v;
    return 1;
  }

  int get totalQuantity {
    final v = productData?['totalQuantity'];
    if (v is int) return v;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                height: 200,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : Container(color: Colors.grey.shade300),
              ),
            ),

            const SizedBox(height: 25),

            Text(name,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

            const SizedBox(height: 6),

            Text('$price JOD/day',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),

            if (deposit > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Security Deposit (Refundable): ${deposit.toStringAsFixed(2)} JOD',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              availableQuantity > 0
                  ? 'Available: $availableQuantity of $totalQuantity'
                  : 'Out of stock',
              style: TextStyle(
                color: availableQuantity > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

            Text(description, style: const TextStyle(color: Colors.black54)),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: WishlistToggleButton(
                productId: widget.productId,
                productSnapshot: {
                  'name': name,
                  'price': price,
                  'imageUrl': imageUrl,
                  'renterId': productData?['renterId'] ?? '',
                },
                size: 28,
                background: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (isRented || isOwner) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRented ? Colors.grey : kOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  isOwner
                      ? 'Your Item'
                      : isRented
                          ? 'Currently Rented'
                          : 'Add To Cart',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat, color: kOrange),
                label: const Text(
                  'Contact Renter',
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kOrange, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: isOwner ? null : _contactRenter,
              ),
            ),

            if (hasRentedItem) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _showReviewDialog,
                  child: const Text('Leave a Review'),
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            const Text('Reviews',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),
            _ReviewsSection(itemId: widget.productId),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't rent your own item")),
      );
      return;
    }

    final available = (productData?['availableQuantity'] ??
        productData?['quantity'] ??
        1) as int;
    final total =
        (productData?['totalQuantity'] ?? productData?['quantity'] ?? 1) as int;

    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item is fully rented')),
      );
      return;
    }

    final existingIndex =
        cartItems.indexWhere((item) => item.itemId == widget.productId);

    if (existingIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item already in cart')),
      );
      return;
    }

    cartItems.add(
      CartItemModel(
        itemId: widget.productId,
        renterId: productData?['renterId'],
        imageUrl: imageUrl,
        title: name,
        price: price,
        depositAmount: deposit,
        availableQuantity: available,
        totalQuantity: total,
        selectedQuantity: 1,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added to cart')),
    );
  }

  Future<void> _contactRenter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final renterId = productData?['renterId'];
    if (renterId == null || renterId == user.uid) return;

    final chatId = await ChatService().getOrCreateChat(renterId: renterId);

    final renterSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(renterId)
        .get();

    String renterName = 'Renter';
    String renterAvatar = '';

    if (renterSnap.exists) {
      final renter = renterSnap.data()!;
      final first = renter['firstName'] ?? '';
      final last = renter['lastName'] ?? '';

      renterName =
          ('$first $last').trim().isEmpty ? 'Renter' : ('$first $last').trim();

      renterAvatar = renter['profileImage'] ?? '';
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          name: renterName,
          avatar: renterAvatar,
        ),
      ),
    );
  }

  Future<void> _showReviewDialog() async {
    int rating = 5;
    final controller = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('itemId', isEqualTo: widget.productId)
        .where('customerId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (orderSnap.docs.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setStarState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStarState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('reviews').add({
                  'itemId': widget.productId,
                  'userId': user.uid,
                  'rating': rating,
                  'comment': controller.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String itemId;

  const _ReviewsSection({required this.itemId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No reviews yet');
        }

        final reviews = snapshot.data!.docs;

        return Column(
          children: reviews.map((doc) {
            final r = doc.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(r['userId'])
                  .get(),
              builder: (context, userSnap) {
                final user = userSnap.data?.data() as Map<String, dynamic>?;

                final name =
                    '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'
                        .trim();

                final avatar = user?['profileImage'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null || avatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(name.isEmpty ? 'User' : name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          r['rating'],
                          (_) => const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(r['comment'] ?? ''),
                    ],
                  ),
                  trailing: r['userId'] == currentUserId
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editReview(context, doc);
                            } else if (value == 'delete') {
                              _deleteReview(context, doc.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : null,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _deleteReview(BuildContext context, String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review deleted')),
    );
  }

  void _editReview(BuildContext context, QueryDocumentSnapshot doc) {
    int rating = doc['rating'];
    final controller = TextEditingController(text: doc['comment']);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setStarState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStarState(() => rating = index + 1);
                        },
                      );
                    }),
                  );
                },
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Edit your review',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await doc.reference.update({
                  'rating': rating,
                  'comment': controller.text.trim(),
                });

                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
