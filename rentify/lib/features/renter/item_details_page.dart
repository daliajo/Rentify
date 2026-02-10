import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ItemDetailsPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const ItemDetailsPage(
      {super.key, required this.itemId, required this.itemData});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final Color orange = const Color(0xFFFF8A3D);
  final picker = ImagePicker();

  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController descCtrl;
  late int totalQuantity;
  late int availableQuantity;

  bool isEditingName = false;
  bool isEditingPrice = false;
  bool isEditingDesc = false;
  bool isUpdating = false;

  File? _selectedImage;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.itemData['name']);
    priceCtrl =
        TextEditingController(text: widget.itemData['price'].toString());
    descCtrl = TextEditingController(text: widget.itemData['description']);
    totalQuantity = _parseQuantity(
        widget.itemData['totalQuantity'] ?? widget.itemData['quantity']);
    availableQuantity = _parseQuantity(
      widget.itemData['availableQuantity'],
      fallback: totalQuantity,
    );
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isUpdating = true);

    try {
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
      } else {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            "${tempDir.path}/updated_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final compressed = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          quality: 75,
          minWidth: 800,
          format: CompressFormat.jpeg,
        );
        bytes = await compressed!.readAsBytes();
      }

      final ref = FirebaseStorage.instance.ref().child(
          "items/item_${widget.itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final newUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('rentify_items')
          .doc(widget.itemId)
          .update({'imageUrl': newUrl});

      setState(() {
        widget.itemData['imageUrl'] = newUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Image updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update image: $e")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> _updateField(String field, String value) async {
    try {
      setState(() => isUpdating = true);
      await FirebaseFirestore.instance
          .collection('rentify_items')
          .doc(widget.itemId)
          .update({field: value});

      widget.itemData[field] = value;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('rentify_items')
          .doc(widget.itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Item deleted")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.itemData;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: orange,
        title: const Text("Item Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: isUpdating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['imageUrl'] ?? '',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) => const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 80, color: Colors.grey)),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: CircleAvatar(
                              backgroundColor: orange,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _pickAndUploadImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        label: "Name",
                        controller: nameCtrl,
                        isEditing: isEditingName,
                        onEditToggle: () =>
                            setState(() => isEditingName = !isEditingName),
                        onSave: () =>
                            _updateField("name", nameCtrl.text.trim()),
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        label: "Price (JOD/day)",
                        controller: priceCtrl,
                        isEditing: isEditingPrice,
                        keyboardType: TextInputType.number,
                        onEditToggle: () =>
                            setState(() => isEditingPrice = !isEditingPrice),
                        onSave: () =>
                            _updateField("price", priceCtrl.text.trim()),
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        label: "Description",
                        controller: descCtrl,
                        isEditing: isEditingDesc,
                        maxLines: 4,
                        onEditToggle: () =>
                            setState(() => isEditingDesc = !isEditingDesc),
                        onSave: () =>
                            _updateField("description", descCtrl.text.trim()),
                      ),
                      const SizedBox(height: 20),
                      _buildQuantityCard(),
                      const SizedBox(height: 20),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: const Text("Delete Item",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _deleteItem,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQuantityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quantity",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Quantity: $availableQuantity of ${totalQuantity > 0 ? totalQuantity : availableQuantity}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: availableQuantity > 0 ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isUpdating ? null : _promptUpdateQuantity,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: const Text("Update total quantity"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptUpdateQuantity() async {
    final controller = TextEditingController(text: totalQuantity.toString());
    final newTotal = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Quantity"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Total quantity",
            hintText: "Enter new total quantity",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Quantity must be greater than 0")),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newTotal == null || newTotal <= 0) return;
    await _updateQuantity(newTotal);
  }

  Future<void> _updateQuantity(int newTotal) async {
    try {
      setState(() => isUpdating = true);
      final reserved = totalQuantity > availableQuantity
          ? totalQuantity - availableQuantity
          : 0;
      int newAvailable = newTotal - reserved;
      if (newAvailable < 0) newAvailable = 0;
      if (newAvailable > newTotal) newAvailable = newTotal;

      await FirebaseFirestore.instance
          .collection('rentify_items')
          .doc(widget.itemId)
          .update({
        'totalQuantity': newTotal,
        'availableQuantity': newAvailable,
        'status': newAvailable > 0 ? 'available' : 'rented',
      });

      setState(() {
        totalQuantity = newTotal;
        availableQuantity = newAvailable;
        widget.itemData['totalQuantity'] = newTotal;
        widget.itemData['availableQuantity'] = newAvailable;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Quantity updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update quantity: $e")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  int _parseQuantity(dynamic value, {int fallback = 1}) {
    if (value is num && value > 0) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType? keyboardType,
    int maxLines = 1,
    required VoidCallback onEditToggle,
    required VoidCallback onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        isEditing
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save",
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(controller.text,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black87)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: onEditToggle,
                  ),
                ],
              ),
      ],
    );
  }
}
