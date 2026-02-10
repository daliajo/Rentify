import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/MainNavigation.dart';
import 'features/auth/splash_screen.dart';
import 'features/renter/renter_main.dart';
import 'features/auth/login.dart';
import 'features/auth/signup.dart';
import 'features/auth/role_selection_page.dart';
import 'features/auth/verify_email_page.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/admin/admin_users_page.dart';
import 'features/wishlist/wishlist_service.dart';
import 'features/store/item_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    //initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('en');

    WishlistService();

    //update expired rentals on app startup
    await ItemStatusService().updateExpiredRentals();

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "⚠️ Firebase initialization failed.\nCheck your config.\n\n$e",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainNavigation(),
        '/renterMain': (context) => const RenterMain(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpScreen(),
        '/roleSelection': (context) => const RoleSelectionPage(),
        '/verifyEmail': (context) => const VerificationPage(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/users': (context) => const AdminUsersPage(),
      },
    );
  }
}

//auth wrapper to handle initial routing based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        //show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: _getRenterMode(),
            builder: (context, modeSnapshot) {
              if (modeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              //return appropriate main screen based on mode
              return modeSnapshot.data == true
                  ? const RenterMain()
                  : const MainNavigation();
            },
          );
        }

        //user is not logged in, show splash screen
        return const SplashScreen();
      },
    );
  }

  Future<bool> _getRenterMode() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'customer';
    return role == 'renter';
  }
}
