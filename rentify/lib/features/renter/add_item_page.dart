import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  File? _selectedImage;
  Uint8List? _webImageBytes;

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();

  String? selectedCategory;
  String? selectedSubcategory;
  bool _isLoading = false;

  final orange = const Color(0xFFFF8A3D);

  final Map<String, String> categoryIcons = {
    "Fashion & Apparel": "👗",
    "Electronics": "💻",
    "Equipment and Tools": "🧰",
    "Spaces & Living": "🏠",
  };

  final Map<String, Map<String, String>> subcategoryIcons = {
    "Fashion & Apparel": {
      "Clothing": "👕",
      "Footwear": "👟",
      "Bags & Clutches": "👜",
    },
    "Electronics": {
      "Displays": "🖥️",
      "Audio Gear": "🎧",
      "Cameras & Tripods": "📷",
      "Projectors": "📽️",
    },
    "Equipment and Tools": {
      "Power Tools": "🔨",
      "Hand Tools": "🔧",
      "Cleaning & Household Equipment": "🧹",
    },
    "Spaces & Living": {
      "Events & Venues": "🎪",
      "Outdoor": "⛺",
    },
  };

  final Map<String, List<double>> priceRanges = {
    "Fashion & Apparel": [10, 40],
    "Electronics": [10, 20],
    "Equipment and Tools": [5, 20],
    "Spaces & Living": [10, 30],
  };

  // Deposit rate ranges by category
  Map<String, double> getDepositRateRange(String? category) {
    switch (category) {
      case "Electronics":
        return {"min": 0.40, "max": 0.60};
      case "Equipment and Tools":
        // Check if it's Power Tools subcategory
        if (selectedSubcategory == "Power Tools") {
          return {"min": 0.30, "max": 0.50};
        }
        return {"min": 0.20, "max": 0.40};
      case "Spaces & Living":
        return {"min": 0.20, "max": 0.40};
      case "Fashion & Apparel":
        return {"min": 0.10, "max": 0.25};
      default:
        return {"min": 0.20, "max": 0.40};
    }
  }

  // Calculate deposit rate based on category (returns average of range)
  double calculateDepositRate(String? category) {
    final range = getDepositRateRange(category);
    final min = range["min"]!;
    final max = range["max"]!;
    return (min + max) / 2; // Use average of range
  }

  // Calculate deposit amount from price per day
  double calculateDepositAmount(double pricePerDay, String? category) {
    final rate = calculateDepositRate(category);
    return pricePerDay * rate;
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        _selectedImage = null;
      });
    } else {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        format: CompressFormat.jpeg,
      );

      setState(() {
        _selectedImage =
            compressedXFile != null ? File(compressedXFile.path) : null;
        _webImageBytes = null;
      });
    }
  }

  Future<bool> _showPriceWarningDialog(double min, double max) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Price Outside Range",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent,
                ),
              ),
              content: Text(
                "Suggested price: $min–$max JOD/day.\nDo you want to continue?",
                style: const TextStyle(fontSize: 15),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _webImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    final totalQuantity = int.tryParse(quantityCtrl.text.trim()) ?? 0;
    if (totalQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity")),
      );
      return;
    }

    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid price per day")),
      );
      return;
    }

    if (selectedCategory != null) {
      final range = priceRanges[selectedCategory]!;
      final min = range[0];
      final max = range[1];

      if (price < min || price > max) {
        final continueAnyway = await _showPriceWarningDialog(min, max);
        if (!continueAnyway) return;
      }
    }

    final depositAmount = calculateDepositAmount(price, selectedCategory);

    setState(() => _isLoading = true);

    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();

      final fileName = "item_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child("items/$fileName");

      if (kIsWeb) {
        await ref.putData(
          _webImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(_selectedImage!);
      }

      final imageUrl = await ref.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;

      final docRef =
          FirebaseFirestore.instance.collection("rentify_items").doc();
      await docRef.set({
        "renterId": user!.uid,
        "name": nameCtrl.text.trim(),
        "price": price,
        "depositAmount": depositAmount,
        "category": selectedCategory,
        "subcategory": selectedSubcategory,
        "description": descCtrl.text.trim(),
        "imageUrl": imageUrl,
        "status": "available",
        "totalQuantity": totalQuantity,
        "availableQuantity": totalQuantity,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item uploaded successfully!")),
      );

      nameCtrl.clear();
      priceCtrl.clear();
      descCtrl.clear();
      quantityCtrl.clear();
      setState(() {
        _selectedImage = null;
        _webImageBytes = null;
        selectedCategory = null;
        selectedSubcategory = null;
      });
    } catch (e) {
      debugPrint("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _webImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                _webImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate,
                                        color: Colors.grey, size: 50),
                                    SizedBox(height: 10),
                                    Text(
                                      "Tap to upload image",
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 14),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: categoryIcons.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Text(categoryIcons[c]!,
                                      style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text(c),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCategory = v;
                        selectedSubcategory = null;
                      });
                    },
                    decoration: _inputDecoration("Select Category"),
                    validator: (v) => v == null ? "Select a category" : null,
                  ),
                  if (selectedCategory != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Suggested price: ${priceRanges[selectedCategory]![0]}–${priceRanges[selectedCategory]![1]} JOD/day",
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedSubcategory,
                      items: subcategoryIcons[selectedCategory]!
                          .entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Row(children: [
                                Text(entry.value,
                                    style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Text(entry.key),
                              ]),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedSubcategory = v),
                      decoration: _inputDecoration("Select Subcategory"),
                      validator: (v) =>
                          v == null ? "Select a subcategory" : null,
                    ),
                  ],
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDecoration("Item Name"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter item name" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: _inputDecoration("Price per day (JOD)"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter price";
                      final price = double.tryParse(v);
                      if (price == null) return "Enter a valid number";
                      return null;
                    },
                  ),
                  if (selectedCategory != null &&
                      priceCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final price =
                            double.tryParse(priceCtrl.text.trim()) ?? 0;
                        if (price > 0) {
                          final depositRate =
                              calculateDepositRate(selectedCategory);
                          final depositAmount =
                              calculateDepositAmount(price, selectedCategory);
                          final range = getDepositRateRange(selectedCategory);
                          return Text(
                            "Security Deposit: ${depositAmount.toStringAsFixed(2)} JOD (${(depositRate * 100).toStringAsFixed(0)}% of price per day, range: ${(range["min"]! * 100).toStringAsFixed(0)}%-${(range["max"]! * 100).toStringAsFixed(0)}%)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SizedBox(height: 18),
                  const Text(
                    "Quantity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: quantityCtrl,
                    decoration: _inputDecoration("Enter available quantity"),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter quantity";
                      final qty = int.tryParse(v);
                      if (qty == null || qty <= 0) {
                        return "Enter a valid quantity";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: _inputDecoration("Description"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Colors.orange.shade200,
                        elevation: 5,
                      ),
                      onPressed: _isLoading ? null : _saveItem,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Item",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    );
  }
}
