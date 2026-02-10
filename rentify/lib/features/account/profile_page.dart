import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _profileImageUrl;
  File? _newImageFile;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _emailController.text = user.email ?? "";

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _profileImageUrl = data['profileImage'];
      }
    } catch (e) {
      debugPrint("❌ Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _newImageFile = File(picked.path);
    });
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imgUrl = _profileImageUrl;

      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures/${user.uid}.jpg");

        await ref.putFile(_newImageFile!);
        imgUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'profileImage': imgUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save changes"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child:
                            Image.asset("assets/images/logoo.png", width: 50),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                          const Text(
                            "User Profile",
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _newImageFile != null
                                ? FileImage(_newImageFile!)
                                : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                        as ImageProvider
                                    : const AssetImage(
                                        "assets/images/profile.png")),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildField(
                        label: "First Name",
                        controller: _firstNameController,
                        validator: (v) =>
                            v!.isEmpty ? "First name is required" : null,
                      ),
                      _buildField(
                        label: "Last Name",
                        controller: _lastNameController,
                        validator: (v) =>
                            v!.isEmpty ? "Last name is required" : null,
                      ),
                      _buildField(
                        label: "E-mail",
                        controller: _emailController,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Email is required";
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          return emailRegex.hasMatch(v)
                              ? null
                              : "Enter a valid email";
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 54, 20, 7),
              )),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            ),
          ),
        ],
      ),
    );
  }
}
