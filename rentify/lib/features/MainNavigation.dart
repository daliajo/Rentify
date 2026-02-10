import 'package:flutter/material.dart';
import 'Home/homepage.dart';
import 'account/account_page.dart';
import 'wishlist/wishlist_page.dart';
import 'cart/cart_page.dart';
import 'chat/chat_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Homepage(),
    CartPage(),
    WishlistPage(),
    ChatPage(),
    AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepOrangeAccent;

    return WillPopScope(
      onWillPop: () async {
      
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.black,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border), label: 'Wishlist'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
