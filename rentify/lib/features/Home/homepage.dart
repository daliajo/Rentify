import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../categories/categories_page.dart';
import '../store/products_page.dart';
import '../store/product_detail_page.dart';
import '../wishlist/widgets/wishlist_toggle_button.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final Color lightOrange = const Color(0xFFFF8A3D);

  String? _selectedCategory;
  String searchQuery = "";

  final List<_CategoryOption> _categoryOptions = const [
    _CategoryOption(
      label: "Fashion",
      assetPath: "assets/icons/fashion.png",
      filterValue: "Fashion & Apparel",
    ),
    _CategoryOption(
      label: "Electronics",
      assetPath: "assets/icons/responsive.png",
      filterValue: "Electronics",
    ),
    _CategoryOption(
      label: "Equipment",
      assetPath: "assets/icons/tools.png",
      filterValue: "Equipment and Tools",
    ),
    _CategoryOption(
      label: "Living",
      assetPath: "assets/icons/sofa.png",
      filterValue: "Spaces & Living",
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getDiscoverItems() {
    Query query = FirebaseFirestore.instance.collection("rentify_items");

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      query = query.where("category", isEqualTo: _selectedCategory);
    }

    return query.orderBy("createdAt", descending: true).limit(10).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            // LOGO
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 10),
              child: Center(
                child: Image.asset("assets/images/logoo.png", width: 50),
              ),
            ),

            // SEARCH BAR
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Search here",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = "";
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 24, color: Colors.black),
                ),
              ],
            ),

          
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoriesPage()),
                    );
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _categoryOptions.map(_buildCategoryChip).toList(),
            ),

            const SizedBox(height: 25),

          
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Discover Items",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductsPage()),
                    );
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

          
            StreamBuilder<QuerySnapshot>(
              stream: getDiscoverItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final status =
                      (data["status"] ?? "available").toString().toLowerCase();
                  if (status != "available") return false;

                  final name = (data["name"] ?? "").toString().toLowerCase();

                  return name.contains(searchQuery);
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text("No items found."));
                }

                items = items.take(4).toList();

                final canLeft = _scrollController.hasClients &&
                    _scrollController.offset > 0;
                final canRight = _scrollController.hasClients &&
                    (_scrollController.position.maxScrollExtent -
                            _scrollController.offset >
                        5);

                return SizedBox(
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                      productId: doc.id,
                                    ),
                                  ),
                                );
                              },
                              child: _buildDealCard(
                                productId: doc.id,
                                data: data,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (canLeft)
                        Positioned(
                          left: 8,
                          child: _buildArrow(Icons.arrow_back_ios_new, -200),
                        ),
                      if (canRight)
                        Positioned(
                          right: 8,
                          child: _buildArrow(Icons.arrow_forward_ios, 200),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  
  Widget _buildCategoryChip(_CategoryOption option) {
    final isSelected = _selectedCategory == option.filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : option.filterValue;
        });
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected
                  ? lightOrange.withOpacity(0.15)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? lightOrange : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(option.assetPath),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? lightOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildArrow(IconData icon, double offset) {
    return GestureDetector(
      onTap: () {
        _scrollController.animateTo(
          _scrollController.offset + offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.25),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }


  Widget _buildDealCard({
    required String productId,
    required Map<String, dynamic> data,
  }) {
    final imageUrl = data["imageUrl"] ?? "";
    final title = data["name"] ?? "";
    final priceValue = data["price"];
    final category = data["subcategory"] ?? "";
    final priceLabel =
        "${(priceValue is num ? priceValue : double.tryParse(priceValue.toString()) ?? 0).toStringAsFixed(2)} JOD/day";

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 180,
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: WishlistToggleButton(
                        productId: productId,
                        productSnapshot: data,
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
                    Text(category,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String label;
  final String assetPath;
  final String filterValue;

  const _CategoryOption({
    required this.label,
    required this.assetPath,
    required this.filterValue,
  });
}
