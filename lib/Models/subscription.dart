class Subscription {
  final String id;
  final String userId; // Hôte
  final String plan; // 'monthly' ou 'semesterly'
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'expired', 'cancelled'
  final String stripeSubscriptionId; // ID Stripe pour gestion

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.price,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.stripeSubscriptionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      plan: data['plan'] ?? 'monthly',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'EUR',
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'])
          : DateTime.now(),
      endDate: data['end_date'] != null
          ? DateTime.parse(data['end_date'])
          : DateTime.now(),
      status: data['status'] ?? 'active',
      stripeSubscriptionId: data['stripe_subscription_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'plan': plan,
      'price': price,
      'currency': currency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'stripe_subscription_id': stripeSubscriptionId,
    };
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}
