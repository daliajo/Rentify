import 'package:flutter/material.dart';

import '../wishlist_service.dart';

class WishlistToggleButton extends StatelessWidget {
  const WishlistToggleButton({
    super.key,
    required this.productId,
    required this.productSnapshot,
    this.size = 26,
    this.background,
    this.activeColor = const Color(0xFFFF7A00),
    this.inactiveColor = Colors.black54,
  });

  final String productId;
  final Map<String, dynamic> productSnapshot;
  final double size;
  final Color? background;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final service = WishlistService();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: service.wishlistIds,
      builder: (_, ids, __) {
        final isSaved = ids.contains(productId);
        return Material(
          color: background ?? Colors.white.withOpacity(0.85),
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            tooltip: isSaved ? 'Remove from wishlist' : 'Add to wishlist',
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? activeColor : inactiveColor,
              size: size,
            ),
            onPressed: () async {
              try {
                await service.toggleWishlist(
                  productId: productId,
                  productSnapshot: productSnapshot,
                );
              } on WishlistException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to update wishlist: $e')),
                );
              }
            },
          ),
        );
      },
    );
  }
}


