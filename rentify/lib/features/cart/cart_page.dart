import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cart/checkout.dart';
import '../cart/cart_data.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color accent = const Color(0xFFFF6A00);
  bool _isSyncingInventory = false;

  double get subtotal {
    double sum = 0;
    for (var item in cartItems) {
      sum += item.price * item.selectedQuantity;
    }
    return sum;
  }

  double get totalDeposit {
    double sum = 0;
    for (var item in cartItems) {
      sum += item.depositAmount * item.selectedQuantity;
    }
    return sum;
  }

  
  double get total => subtotal + totalDeposit;

  bool get _hasInvalidQuantities {
    return cartItems.any((item) =>
        item.availableQuantity <= 0 ||
        item.selectedQuantity < 1 ||
        item.selectedQuantity > item.availableQuantity);
  }

  @override
  void initState() {
    super.initState();
    _refreshCartAvailability();
  }

  Future<void> _refreshCartAvailability({bool manual = false}) async {
    if (_isSyncingInventory) return;
    if (!mounted) return;
    setState(() => _isSyncingInventory = true);

    final removedItems = <String>[];
    final firestore = FirebaseFirestore.instance;

    for (final item in List<CartItemModel>.from(cartItems)) {
      try {
        final doc =
            await firestore.collection('rentify_items').doc(item.itemId).get();
        if (!doc.exists) {
          cartItems.remove(item);
          removedItems.add(item.title);
          continue;
        }

        final data = doc.data()!;
        final totalQuantity =
            _parseQuantity(data['totalQuantity'] ?? data['quantity'] ?? 1);
        final availableQuantity = _parseQuantity(
          data['availableQuantity'],
          fallback: totalQuantity,
        );

        if (availableQuantity <= 0) {
          cartItems.remove(item);
          removedItems.add(item.title);
          continue;
        }

        item.updateAvailability(
          newAvailable: availableQuantity,
          newTotal: totalQuantity,
        );
      } catch (e) {
      }
    }

    if (!mounted) return;
    setState(() => _isSyncingInventory = false);

    if (removedItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removedItems.length == 1
                ? "${removedItems.first} is no longer available."
                : "Some items were removed because they are no longer available.",
          ),
        ),
      );
    } else if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory synced.")),
      );
    }
  }

  int _parseQuantity(dynamic value, {int fallback = 1}) {
    if (value is num && value > 0) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cart',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.06),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: cartItems.isEmpty ? null : () => _refreshCartAvailability(manual: true),
            icon: _isSyncingInventory
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 35, right: 12),
            child: TextButton(
              onPressed: () {
                setState(() {
                  cartItems.clear();
                });
              },
              child: const Text(
                'Remove All',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : Column(
              children: [
                // ITEMS LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItem(
                        image: item.imageUrl,
                        title: item.title,
                        price: item.price,
                        deposit: item.depositAmount,
                        quantity: item.selectedQuantity,
                        availableQuantity: item.availableQuantity,
                        onRemove: () {
                          setState(() {
                            cartItems.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
                ),

    
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      children: [
                        PriceRow(
                          title: "Item Price",
                          amount: "${subtotal.toStringAsFixed(2)} JOD",
                        ),
                        PriceRow(
                          title: "Security Deposit (Refundable)",
                          amount: "${totalDeposit.toStringAsFixed(2)} JOD",
                        ),
                        const Divider(height: 18),
                        PriceRow(
                          title: "Total Payable",
                          amount: "${total.toStringAsFixed(2)} JOD",
                          emphasize: true,
                        ),
                        const SizedBox(height: 12),

                      
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty || _hasInvalidQuantities
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CheckoutPage()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hasInvalidQuantities)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      "Please adjust quantities based on available stock.",
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final String image;
  final String title;
  final double price;
  final double deposit;
  final int quantity;
  final int availableQuantity;
  final VoidCallback onRemove;

  const _CartItem({
    required this.image,
    required this.title,
    required this.price,
    required this.deposit,
    required this.quantity,
    required this.availableQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFFF6A00);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image,
              height: 55,
              width: 55,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // TITLE
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${price.toStringAsFixed(2)} JOD/day",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Text(
                "Deposit: ${deposit.toStringAsFixed(2)} JOD (refundable)",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Qty: $quantity",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                availableQuantity > 0
                    ? "Available: $availableQuantity"
                    : "Out of stock",
                style: TextStyle(
                  fontSize: 11.5,
                  color:
                      availableQuantity > 0 ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        "Remove",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class PriceRow extends StatelessWidget {
  final String title;
  final String amount;
  final bool emphasize;

  const PriceRow({
    required this.title,
    required this.amount,
    this.emphasize = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final leftStyle = emphasize
        ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
        : const TextStyle(color: Colors.black, fontWeight: FontWeight.w500);

    final rightStyle = const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: leftStyle)),
          Text(amount, style: rightStyle),
        ],
      ),
    );
  }
}
