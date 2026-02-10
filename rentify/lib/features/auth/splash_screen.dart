import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rentify/features/auth/login.dart';
import 'package:rentify/features/auth/signup.dart';
import 'package:flutter/gestures.dart';
import 'auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final buttonColor = Colors.grey[200];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF8C00),
              Color(0xFFFFB347),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/logo.png",
                width: 180,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 80),

              Text(
                "Smart Rentals, Simplified",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: () async {
                  await _authService.signInWithGoogle(context);
                },
                icon: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 2),
                  child: Image.asset(
                    "assets/images/google_logo.png",
                    height:
                        20, 
                  ),
                ),
                label: const Text(
                  "Sign up with Google",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(280, 50),
                  elevation: 4,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.mail_outline, color: Colors.black),
                label: const Text(
                  " Sign up with Email",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(280, 50),
                  elevation: 4,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  children: [
                    TextSpan(
                      text: "Sign In",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                    ),
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
