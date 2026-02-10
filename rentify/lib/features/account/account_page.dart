import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'help_support_page.dart';
import '../renter/renter_main.dart';
import '../MainNavigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import 'change_password_page.dart';
import 'about_rentify_page.dart';

class AccountPage extends StatefulWidget {
  final bool showScaffold;
  const AccountPage({super.key, this.showScaffold = false});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isRenterMode = false; 
  static const primaryColor = Colors.deepOrangeAccent;

  @override
  void initState() {
    super.initState();
    _loadMode(); 
  }

  
  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'customer';
    setState(() {
      _isRenterMode = (role == 'renter');
    });
  }

  Future<void> _saveMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final role = value ? 'renter' : 'customer';
    await prefs.setString('userRole', role);

    if (!mounted) return;

    if (value) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RenterMain()),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Center(
              child: Image.asset(
                "assets/images/logoo.png",
                width: 55,
              ),
            ),
          ),

        
          if (widget.showScaffold)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Account",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Account",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),

          const SizedBox(height: 20),

          
          const Text(
            "Account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),

          _buildTile(
            context,
            icon: Icons.person_outline,
            title: "Edit Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),

          const SizedBox(height: 25),

          const Text(
            "Preferences",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                _isRenterMode ? "Renter Mode" : "Customer Mode",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "Current Mode: ${_isRenterMode ? "Renter" : "Customer"}",
                style: const TextStyle(color: Colors.black54),
              ),
              secondary: Icon(
                _isRenterMode
                    ? Icons.home_work_outlined
                    : Icons.shopping_bag_outlined,
                color: primaryColor,
              ),
              value: _isRenterMode,
              activeColor: primaryColor,
              onChanged: (value) async {
                setState(() => _isRenterMode = value);
                await _saveMode(value);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? "Switched to Renter Mode"
                        : "Switched to Customer Mode"),
                    backgroundColor: primaryColor,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 25),

          const Text(
            "Support",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _buildTile(
            context,
            icon: Icons.info_outline,
            title: "About Rentify",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutRentifyPage(),
                ),
              );
            },
          ),

          _buildTile(
            context,
            icon: Icons.help_outline,
            title: "Help & FAQ",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HelpSupportPage()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.logout_outlined,
            title: "Log Out",
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();

              await prefs.remove('isRenterMode');
              await prefs.remove('userRole');

              await FirebaseAuth.instance.signOut();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (Route<dynamic> route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You have been logged out"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (widget.showScaffold) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: content,
      );
    }
    return content;
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color iconColor = Colors.deepOrange,
    Color textColor = Colors.black87,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 18, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      dense: true,
    );
  }
}
