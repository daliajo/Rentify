import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isEmailSent = false;
  bool _isResending = false;
  DateTime? _lastEmailSentTime;

  static const Duration _throttleDuration = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationStatus();
    _sendVerificationEmail();
    _startEmailCheckLoop();
  }

  Future<void> _checkEmailVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await user.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        if (!mounted) return;
        _navigateAfterVerification(updatedUser);
      }
    } catch (e) {
      print("Error checking initial verification status: $e");
    }
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No user is currently logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_lastEmailSentTime != null) {
      final timeSinceLastSend = DateTime.now().difference(_lastEmailSentTime!);
      if (timeSinceLastSend < _throttleDuration) {
        final remainingSeconds =
            (_throttleDuration - timeSinceLastSend).inSeconds;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Please wait $remainingSeconds seconds before requesting another email."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isResending = true;
    });

    try {
      await user.sendEmailVerification();

      setState(() {
        _isEmailSent = true;
        _lastEmailSentTime = DateTime.now();
        _isResending = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email sent. Please check your inbox."),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isResending = false;
      });

      if (!mounted) return;

      String errorMessage = "Failed to send verification email.";
      if (e.code == 'too-many-requests') {
        errorMessage =
            "Too many requests. Please wait a few minutes before trying again.";
      } else if (e.code == 'user-not-found') {
        errorMessage = "User account not found. Please log out and try again.";
      } else if (e.message != null) {
        errorMessage = "Error: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _isResending = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send verification email: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _startEmailCheckLoop() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        await user.reload();

        final updatedUser = _auth.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          timer.cancel();
          if (!mounted) return;

          _navigateAfterVerification(updatedUser);
        }
      } catch (e) {
        print("Error checking email verification: $e");
      }
    });
  }

  Future<void> _navigateAfterVerification(User user) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email verified successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      await _authService.redirectUserBasedOnRole(context, user);
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/roleSelection');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFFF8A3D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 90, color: orange),
                const SizedBox(height: 20),

                const Text(
                  "Verify Your Email",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text(
                  "We've sent a verification link to your email.\n"
                  "Please click the link to activate your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withOpacity(0.65),
                      height: 1.5),
                ),

                const SizedBox(height: 30),

                if (_isEmailSent)
                  Text(
                    "Email sent ✔",
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 40),

                TextButton(
                  onPressed: _isResending ? null : _sendVerificationEmail,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : const Text(
                          "Resend email",
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () async {
                    try {
                      await _auth.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to sign out: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Wrong email? Log out",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
