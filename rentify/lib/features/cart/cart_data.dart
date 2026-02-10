class CartItemModel {
  final String itemId;
  final String renterId;
  final String imageUrl;
  final String title;
  final double price;
  final double depositAmount;
  int selectedQuantity;
  int availableQuantity;
  int totalQuantity;
  int rentalDays;

  CartItemModel({
    required this.itemId,
    required this.renterId,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.depositAmount = 0.0,
    this.selectedQuantity = 1,
    this.availableQuantity = 1,
    this.totalQuantity = 1,
    this.rentalDays = 1,
  });

  void updateAvailability({
    required int newAvailable,
    required int newTotal,
  }) {
    totalQuantity = newTotal > 0 ? newTotal : 1;
    availableQuantity = newAvailable.clamp(0, totalQuantity);
    if (availableQuantity > 0 && selectedQuantity == 0) {
      selectedQuantity = 1;
    }
    if (availableQuantity > 0 &&
        selectedQuantity > availableQuantity &&
        availableQuantity >= 1) {
      selectedQuantity = availableQuantity;
    }
  }

  bool get isOutOfStock => availableQuantity <= 0;
}

List<CartItemModel> cartItems = [];
