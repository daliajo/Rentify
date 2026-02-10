import 'package:flutter/material.dart';
import 'package:rentify/features/renter/add_item_page.dart';
import 'package:rentify/features/account/account_page.dart';
import 'package:rentify/features/renter/renter_dashboard_content.dart';
import 'package:rentify/features/chat/chat_page.dart';

class RenterMain extends StatefulWidget {
  const RenterMain({super.key});

  @override
  State<RenterMain> createState() => _RenterMainState();
}

class _RenterMainState extends State<RenterMain> {
  int _currentIndex = 0;
  static const Color orange = Color(0xFFFF8A3D);

  final List<Widget> _pages = [
    const RenterDashboard(),
    const AddItemPage(),
    ChatPage(),
    const AccountPage(),
  ];

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return "Renter Dashboard";
      case 1:
        return "Add New Item";
      case 2:
        return "Messages";
      case 3:
        return "Account";
      default:
        return "Renter Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: orange,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Add Item',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
