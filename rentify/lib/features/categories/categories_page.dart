import 'package:flutter/material.dart';
import '../store/products_page.dart';

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  Widget build(BuildContext context) {
    final Color accent = Colors.deepOrangeAccent;
    final Color lightGrey = Colors.grey.shade100;
    final Color darkText = Colors.black87;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Categories",
                    style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Image.asset("assets/images/logoo.png", width: 40),
                ],
              ),
            ),

            const SizedBox(height: 10),

      
            Divider(
              color: Colors.grey.shade300,
              thickness: 1,
              height: 20,
            ),

          
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.05,
                  children: [
                    _buildCategoryCard(
                      "Fashion & Apparel",
                      "assets/icons/fashion.png",
                      [
                        "Clothing",
                        "Footwear",
                        "Bags & Clutches",
                      ],
                      accent,
                      darkText,
                      lightGrey,
                    ),
                    _buildCategoryCard(
                      "Electronics",
                      "assets/icons/responsive.png",
                      [
                        "Displays",
                        "Audio Gear",
                        "Cameras & Tripods",
                        "Projectors",
                      ],
                      accent,
                      darkText,
                      lightGrey,
                    ),
                    _buildCategoryCard(
                      "Equipment and Tools",
                      "assets/icons/tools.png",
                      [
                        "Power Tools",
                        "Hand Tools",
                        "Cleaning & Household Equipment",
                      ],
                      accent,
                      darkText,
                      lightGrey,
                    ),
                    _buildCategoryCard(
                      "Spaces & Living",
                      "assets/icons/sofa.png",
                      [
                        "Events & Venues",
                        "Outdoor",
                      ],
                      accent,
                      darkText,
                      lightGrey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String iconPath,
    List<String> subcategories,
    Color accent,
    Color textColor,
    Color background,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                const SizedBox(height: 15),
                ...subcategories.map(
                  (sub) => ListTile(
                    leading: const Icon(Icons.chevron_right),
                    title: Text(
                      sub,
                      style: const TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.grid_view,
                      color: Colors.deepOrangeAccent),
                  title: Text(
                    "View All in $title",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(2, 3),
              blurRadius: 5,
            )
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Image.asset(iconPath, width: 38, height: 38),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "${subcategories.length} Subcategories",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
