import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String _adminEmail = 'ddaliayousef16@gmail.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signUp({
    required String email,
    required String password,
    required BuildContext context,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      await user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'email': email,
        'emailVerified': false,
        'role': 'customer',
        'accountStatus': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📧 Verification email sent!")),
      );

      Navigator.pushReplacementNamed(context, '/verifyEmail');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please verify your email before logging in."),
          ),
        );

        Navigator.pushReplacementNamed(context, '/verifyEmail');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to determine user account.")),
        );
        Navigator.pushReplacementNamed(context, '/roleSelection');
        return;
      }

      await redirectUserBasedOnRole(context, user);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Google sign-in did not return a user.")),
        );
        return;
      }

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final exists = await userDoc.get();

      if (!exists.exists) {
        await userDoc.set({
          'firstName': (user.displayName ?? '').split(' ').first,
          'lastName': (user.displayName != null &&
                  user.displayName!.split(' ').length > 1)
              ? user.displayName!.split(' ').last
              : '',
          'email': user.email ?? '',
          'emailVerified': true,
          'role': 'customer',
          'accountStatus': 'active',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signed in with Google")),
      );

      await redirectUserBasedOnRole(context, user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> redirectUserBasedOnRole(BuildContext context, User user) async {
    try {
      if (user.email == _adminEmail) {
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final status =
          (data?['accountStatus'] as String?)?.toLowerCase() ?? 'active';

      if (status == 'blocked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Your account has been blocked by the administrator."),
          ),
        );
        await _auth.signOut();
        await _googleSignIn.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        return;
      }

      final role = (data?['role'] as String?)?.trim();
      final normalizedRole =
          (role == null || role.isEmpty) ? 'customer' : role.toLowerCase();

      if (normalizedRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/roleSelection');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load role: $e")),
      );
      Navigator.pushReplacementNamed(context, '/roleSelection');
    }
  }
}
