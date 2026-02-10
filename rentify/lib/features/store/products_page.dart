import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_page.dart';
import 'item_status_service.dart';
import '../wishlist/widgets/wishlist_toggle_button.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedSort;
  String? searchQuery;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    ItemStatusService().updateExpiredRentals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> applyFiltersAndSort() {
    Query query = FirebaseFirestore.instance.collection("rentify_items");

    switch (selectedSort) {
      case "Newest":
        query = query.orderBy("createdAt", descending: true);
        break;
      case "Lowest - Highest Price":
        query = query.orderBy("price", descending: false);
        break;
      case "Highest - Lowest Price":
        query = query.orderBy("price", descending: true);
        break;
      default:
        query = query.orderBy("createdAt", descending: true);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot> applySearchFilter(
      List<QueryDocumentSnapshot> docs) {
    if (searchQuery == null || searchQuery!.isEmpty) return docs;

    final q = searchQuery!.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data["name"] ?? "").toString().toLowerCase();
      final available = _extractAvailableQuantity(data);
      final status = (data["status"] ?? "available").toString().toLowerCase();
      final validStatus = available != null ? true : status == "available";
      return name.contains(q) && validStatus;
    }).toList();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                    Image.asset("assets/images/logoo.png", width: 50),
                  ],
                ),
              ),

              TextFormField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.isEmpty ? null : value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search items",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              searchQuery = null;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showSortOptions(context),
                    child: _pillButton(
                      Icons.keyboard_arrow_down,
                      selectedSort ?? "Sort by",
                      Colors.deepOrange,
                      Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: applyFiltersAndSort(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var items = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final available = _extractAvailableQuantity(data);
                      if (available != null) return true;
                      final status = (data["status"] ?? "available")
                          .toString()
                          .toLowerCase();
                      return status == "available";
                    }).toList();

                    items = applySearchFilter(items);

                    if (items.isEmpty) {
                      return const Center(child: Text("No items found."));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.90,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final doc = items[index];
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
                          child: _buildProductCard(
                            productId: doc.id,
                            data: doc.data() as Map<String, dynamic>,
                          ),
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

  Widget _pillButton(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg)),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return _buildBottomSheet(
          title: "Sort by",
          options: const [
            "Newest",
            "Lowest - Highest Price",
            "Highest - Lowest Price",
          ],
          onSelect: (option) {
            setState(() => selectedSort = option);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildProductCard({
    required String productId,
    required Map<String, dynamic> data,
  }) {
    final imageUrl = data["imageUrl"] ?? "";
    final title = data["name"] ?? "Unnamed Item";
    final priceValue = data["price"];
    final priceLabel =
        "${(priceValue is num ? priceValue : double.tryParse(priceValue.toString()) ?? 0).toStringAsFixed(2)} JOD/day";

    final snapshotForWishlist = {
      ...data,
      'renterId': data['renterId'] ?? '',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: WishlistToggleButton(
                    productId: productId,
                    productSnapshot: snapshotForWishlist,
                    size: 22,
                    background: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet({
    required String title,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange)),
          const SizedBox(height: 20),
          ...options.map(
            (option) => ListTile(
              title: Center(child: Text(option)),
              onTap: () => onSelect(option),
            ),
          ),
        ],
      ),
    );
  }

  int _parseQuantity(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  int? _extractAvailableQuantity(Map<String, dynamic> data) {
    if (!data.containsKey("availableQuantity")) return null;
    return _parseQuantity(
      data["availableQuantity"],
      fallback: _parseQuantity(data["totalQuantity"], fallback: 0),
    );
  }
}
