import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../cart/cart_data.dart';
import 'checkout_location_picker.dart';
import '../MainNavigation.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color accent = const Color(0xFFFFA64D);
  final DateFormat _englishDateFormatter = DateFormat('d MMMM yyyy', 'en');

  double get subtotal => cartItems.fold(
      0, (sum, item) => sum + (item.price * item.selectedQuantity));

  double get totalDeposit => cartItems.fold(
      0, (sum, item) => sum + (item.depositAmount * item.selectedQuantity));

  double get shipping =>
      (shippingOption == 'delivery' && cartItems.isNotEmpty) ? 3.00 : 0.00;

  double get total => rentalCost + totalDeposit + shipping;
  double get rentalCost => _rentalDays > 0 ? _totalCost : 0.0;
  double get pricePerDay => cartItems.fold(
      0, (sum, item) => sum + (item.price * item.selectedQuantity));
  bool get _hasInvalidQuantities => cartItems.any((item) =>
      item.selectedQuantity < 1 ||
      item.selectedQuantity > item.availableQuantity);

  String? selectedAddress;
  LatLng? _shippingLatLng;
  String? selectedPaymentMethod = 'cash';
  String selectedPaymentLabel = 'Cash on Delivery';
  bool _isPlacingOrder = false;
  String shippingOption = 'pickup';
  DateTime? _startDate;
  DateTime? _endDate;
  int _rentalDays = 0;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _updateRentalSummary();
  }

  void _handleQuantityChange(CartItemModel item, int newQuantity) {
    if (newQuantity < 1) return;
    if (item.availableQuantity > 0 && newQuantity > item.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Only ${item.availableQuantity} units are available for ${item.title}."),
        ),
      );
      return;
    }
    setState(() {
      item.selectedQuantity = newQuantity;
      _updateRentalSummary();
    });
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
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(.06),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.black87),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Back',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  if (shippingOption == 'delivery')
                    _TileCard(
                      label: 'Delivery Address',
                      value: selectedAddress ?? 'Add Delivery Address',
                      onTap: () => _pickAddress(context),
                    ),
                  const SizedBox(height: 16),
                  _TileCard(
                    label: 'Payment Method',
                    value: selectedPaymentMethod != null
                        ? selectedPaymentLabel
                        : 'Select Payment Method',
                    onTap: () => _pickPayment(context),
                  ),
                  const SizedBox(height: 16),
                  _ShippingOptionCard(
                    selectedOption: shippingOption,
                    onOptionChanged: (option) {
                      setState(() {
                        shippingOption = option;
                        if (option == 'pickup') {
                          selectedAddress = null;
                          _shippingLatLng = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _CartItemsReview(
                    items: cartItems,
                    onQuantityChanged: (item, qty) =>
                        _handleQuantityChange(item, qty),
                  ),
                  const SizedBox(height: 16),
                  _RentalPeriodCard(
                    startDateLabel: _formattedDate(_startDate),
                    endDateLabel: _formattedDate(_endDate),
                    rentalDays: _rentalDays,
                    pricePerDay: pricePerDay,
                    totalCost: _totalCost,
                    onStartTap: _pickStartDate,
                    onEndTap: _pickEndDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceRow(
                      title: 'Rental Cost',
                      amount: '${rentalCost.toStringAsFixed(2)} JOD'),
                  const SizedBox(height: 8),
                  _PriceRow(
                      title: 'Price per Day',
                      amount: '${pricePerDay.toStringAsFixed(2)} JOD'),
                  const SizedBox(height: 8),
                  _PriceRow(
                      title: 'Security Deposit (Refundable)',
                      amount: '${totalDeposit.toStringAsFixed(2)} JOD'),
                  const SizedBox(height: 8),
                  _PriceRow(
                      title: shippingOption == 'delivery'
                          ? 'Delivery Cost'
                          : 'Shipping Cost',
                      amount: '${shipping.toStringAsFixed(2)} JOD'),
                  const SizedBox(height: 8),
                  const Divider(height: 32),
                  _PriceRow(
                      title: 'Total Payable',
                      amount: '${total.toStringAsFixed(2)} JOD',
                      emphasize: true),
                  const SizedBox(height: 16),
                  const _RefundPolicyInfo(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 54,
            child: _BottomPill(
              background: accent,
              leftText: '${total.toStringAsFixed(2)} JOD',
              rightText: 'Place Order',
              onPressed: () {
                if (cartItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your cart is empty.')),
                  );
                  return;
                }
                if (_hasInvalidQuantities) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please adjust quantities before checkout.')),
                  );
                  return;
                }
                if (shippingOption == 'delivery' && _shippingLatLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a delivery location.')),
                  );
                  return;
                }
                if (selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a payment method.')),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  builder: (c) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Confirm Order',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          _ConfirmRow(
                            left: 'Shipping',
                            right: shippingOption == 'pickup'
                                ? 'Pickup (Free)'
                                : 'Delivery (${shipping.toStringAsFixed(2)} JOD)',
                          ),
                          _ConfirmRow(
                            left: 'Payment',
                            right: selectedPaymentLabel,
                          ),
                          _ConfirmRow(
                            left: 'Rental Cost',
                            right: '${rentalCost.toStringAsFixed(2)} JOD',
                          ),
                          _ConfirmRow(
                            left: 'Security Deposit',
                            right: '${totalDeposit.toStringAsFixed(2)} JOD',
                          ),
                          _ConfirmRow(
                            left: 'Shipping Cost',
                            right: '${shipping.toStringAsFixed(2)} JOD',
                          ),
                          const Divider(height: 24),
                          _ConfirmRow(
                            left: 'Total Payable',
                            right: '${total.toStringAsFixed(2)} JOD',
                            emphasize: true,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isPlacingOrder
                                  ? null
                                  : () {
                                      Navigator.pop(c);
                                      _placeOrder();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _isPlacingOrder
                                    ? 'Processing...'
                                    : 'Confirm Order',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAddress(BuildContext context) async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutLocationPickerPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _shippingLatLng = result;
        selectedAddress =
            'Lat ${result.latitude.toStringAsFixed(5)}, Lng ${result.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _pickPayment(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PayTile(
                icon: Icons.money_outlined,
                title: 'Cash on Delivery',
                subtitle: 'Pay when item arrives',
                onTap: () => Navigator.pop(c, 'cash'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedPaymentMethod = result;
        selectedPaymentLabel = 'Cash on Delivery';
      });
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.')),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    if (shippingOption == 'delivery' && _shippingLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery location.')),
      );
      return;
    }

    if (selectedPaymentMethod != 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only cash payments are supported.')),
      );
      return;
    }

    if (_startDate == null || _endDate == null || _rentalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid rental period.')),
      );
      return;
    }

    if (_hasInvalidQuantities) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Requested quantity exceeds available stock.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final ordersCollection = firestore.collection('orders');
      final itemCount = cartItems.length;
      final perItemShipping = itemCount == 0 ? 0.0 : shipping / itemCount;

      final Timestamp startTimestamp = Timestamp.fromDate(_startDate!);
      final Timestamp endTimestamp = Timestamp.fromDate(_endDate!);

      await firestore.runTransaction((transaction) async {
        final pendingWrites = <_PendingOrderWrite>[];

        for (final item in cartItems) {
          if (item.itemId.isEmpty || item.renterId.isEmpty) {
            throw Exception(
                'Missing item details for "${item.title}". Please remove and re-add it.');
          }

          final itemRef =
              firestore.collection('rentify_items').doc(item.itemId);
          final snapshot = await transaction.get(itemRef);

          if (!snapshot.exists) {
            throw Exception('${item.title} is no longer available.');
          }

          final itemData = snapshot.data()!;
          final totalQuantity = _parseQuantity(itemData['totalQuantity']);
          final availableQuantity = _parseQuantity(
            itemData['availableQuantity'],
            fallback: totalQuantity,
          );

          if (availableQuantity < item.selectedQuantity) {
            throw Exception(
                'Requested quantity exceeds available stock for ${item.title}.');
          }

          final newAvailable = availableQuantity - item.selectedQuantity;
          transaction.update(itemRef, {
            'availableQuantity': newAvailable,
            'totalQuantity': totalQuantity,
            'status': newAvailable > 0 ? 'available' : 'rented',
          });

          final orderRef = ordersCollection.doc();
          final pricePerDay = item.price;
          final rentalDays = _rentalDays;
          final totalPrice = pricePerDay * rentalDays * item.selectedQuantity;
          final depositTotal = item.depositAmount * item.selectedQuantity;
          final shippingShare =
              shippingOption == 'delivery' ? perItemShipping : 0.0;

          pendingWrites.add(
            _PendingOrderWrite(
              ref: orderRef,
              data: {
                'itemId': item.itemId,
                'customerId': user.uid,
                'renterId': item.renterId,
                'selectedQuantity': item.selectedQuantity,
                'startDate': startTimestamp,
                'endDate': endTimestamp,
                'paymentStatus': 'pending',
                'grandTotal': totalPrice + depositTotal + shippingShare,
                'createdAt': FieldValue.serverTimestamp(),
              },
            ),
          );
        }

        for (final pending in pendingWrites) {
          transaction.set(pending.ref, pending.data);
        }
      });

      cartItems.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order placed successfully. Please pay in cash when the item arrives.',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('Requested quantity exceeds')
          ? 'Requested quantity exceeds available stock.'
          : 'Failed to place order: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  Widget _ConfirmRow({
    required String left,
    required String right,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: emphasize
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 15,
                    )
                  : const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
            ),
          ),
          Text(
            right,
            style: emphasize
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 15,
                  )
                : const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontSize: 14,
                  ),
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return _englishDateFormatter.format(date);
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime initialDate = _startDate ?? today;
    final DateTime firstDate = today;
    final DateTime lastDate = DateTime(2029, 12, 31);
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('en'),
    );
    if (pickedStartDate != null && pickedStartDate != _startDate) {
      setState(() {
        _startDate = pickedStartDate;
        if (_endDate != null && (_endDate!.isBefore(pickedStartDate))) {
          _endDate = null;
        }
        _updateRentalSummary();
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the start date first.')),
      );
      return;
    }

    final DateTime initialDate = _endDate ?? _startDate!;
    final DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(_startDate!) ? _startDate! : initialDate,
      firstDate: _startDate!,
      lastDate: DateTime(2029, 12, 31),
      locale: const Locale('en'),
    );

    if (pickedEndDate != null && pickedEndDate != _endDate) {
      setState(() {
        _endDate = pickedEndDate;
        _updateRentalSummary();
      });
    }
  }

  void _updateRentalSummary() {
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      if (days > 0) {
        _rentalDays = days;
        _totalCost = pricePerDay * _rentalDays;
        return;
      }
    }
    _rentalDays = 0;
    _totalCost = 0.0;
  }
}

class _PendingOrderWrite {
  const _PendingOrderWrite({required this.ref, required this.data});

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}

class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 6),
                    Text(value,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemsReview extends StatelessWidget {
  const _CartItemsReview({
    required this.items,
    required this.onQuantityChanged,
  });

  final List<CartItemModel> items;
  final void Function(CartItemModel item, int newQuantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Items in Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => _CheckoutItemTile(
            item: item,
            onQuantityChanged: (qty) => onQuantityChanged(item, qty),
          ),
        ),
      ],
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  const _CheckoutItemTile({
    required this.item,
    required this.onQuantityChanged,
  });

  final CartItemModel item;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final canAdjustQuantity = item.availableQuantity > 1;
    final isAtMax =
        canAdjustQuantity && item.selectedQuantity >= item.availableQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} JOD/day',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  'Security Deposit: ${item.depositAmount.toStringAsFixed(2)} JOD (refundable)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  item.availableQuantity > 0
                      ? 'Available: ${item.availableQuantity} of ${item.totalQuantity}'
                      : 'Out of stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.availableQuantity > 0
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                canAdjustQuantity
                    ? Row(
                        children: [
                          _CheckoutQtyButton(
                            icon: Icons.remove,
                            onTap: item.selectedQuantity > 1
                                ? () =>
                                    onQuantityChanged(item.selectedQuantity - 1)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Qty: ${item.selectedQuantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _CheckoutQtyButton(
                            icon: Icons.add,
                            onTap: isAtMax
                                ? null
                                : () => onQuantityChanged(
                                    item.selectedQuantity + 1),
                          ),
                        ],
                      )
                    : Text(
                        'Qty: ${item.selectedQuantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutQtyButton extends StatelessWidget {
  const _CheckoutQtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : Colors.black,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.title,
    required this.amount,
    this.emphasize = false,
  });

  final String title;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(amount,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BottomPill extends StatelessWidget {
  const _BottomPill({
    required this.leftText,
    required this.rightText,
    required this.background,
    required this.onPressed,
  });

  final String leftText;
  final String rightText;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(leftText,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(rightText,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingOptionCard extends StatelessWidget {
  const _ShippingOptionCard({
    required this.selectedOption,
    required this.onOptionChanged,
  });

  final String selectedOption;
  final Function(String) onOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Option',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOptionChanged('pickup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedOption == 'pickup'
                            ? Colors.deepOrange
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedOption == 'pickup'
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'pickup',
                            groupValue: selectedOption,
                            onChanged: (value) => onOptionChanged(value!),
                            activeColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup from renter',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selectedOption == 'pickup'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Free',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedOption == 'pickup'
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOptionChanged('delivery'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedOption == 'delivery'
                            ? Colors.deepOrange
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedOption == 'delivery'
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'delivery',
                            groupValue: selectedOption,
                            onChanged: (value) => onOptionChanged(value!),
                            activeColor: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selectedOption == 'delivery'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '3.00 JOD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedOption == 'delivery'
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundPolicyInfo extends StatefulWidget {
  const _RefundPolicyInfo();

  @override
  State<_RefundPolicyInfo> createState() => _RefundPolicyInfoState();
}

class _RefundPolicyInfoState extends State<_RefundPolicyInfo> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Icon(
          Icons.info_outline,
          color: Colors.blue.shade700,
          size: 20,
        ),
        title: Text(
          'Security Deposit Policy',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
        subtitle: _isExpanded
            ? null
            : Text(
                'Tap to view refund policy',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                ),
              ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Text(
            'The Security Deposit is fully refundable after inspection.\n\n'
            'Deductions may apply for:\n'
            '• Damages beyond normal wear\n'
            '• Missing accessories or parts\n'
            '• Excessive cleaning required\n'
            '• Late returns\n\n'
            'Refunds are issued within 24–48 hours after item inspection.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalPeriodCard extends StatelessWidget {
  const _RentalPeriodCard({
    required this.startDateLabel,
    required this.endDateLabel,
    required this.rentalDays,
    required this.pricePerDay,
    required this.totalCost,
    required this.onStartTap,
    required this.onEndTap,
  });

  final String startDateLabel;
  final String endDateLabel;
  final int rentalDays;
  final double pricePerDay;
  final double totalCost;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Period',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    value: startDateLabel,
                    onTap: onStartTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    value: endDateLabel,
                    onTap: onEndTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
