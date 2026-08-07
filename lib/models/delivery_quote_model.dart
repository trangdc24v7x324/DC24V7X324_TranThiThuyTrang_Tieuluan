class DeliveryQuote {
  final String storeId;
  final String storeName;

  final double storeLatitude;
  final double storeLongitude;

  final double customerLatitude;
  final double customerLongitude;

  final double distanceKm;
  final double deliveryFee;
  final double deliveryRadiusKm;

  final bool isDeliverable;
  final String message;

  const DeliveryQuote({
    required this.storeId,
    required this.storeName,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.distanceKm,
    required this.deliveryFee,
    required this.deliveryRadiusKm,
    required this.isDeliverable,
    required this.message,
  });

  double totalWith(double subtotal) {
    return subtotal + deliveryFee;
  }
}
