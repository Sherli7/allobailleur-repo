/// RefundService stub — cloud functions are not available in this static
/// analysis run. Implement the real service when Firebase Cloud Functions
/// are added to the project dependencies.
class RefundService {
  Future<Map<String, dynamic>> requestRefund({
    required String paymentIntentId,
    int? amount,
    String reason = 'requested_by_customer',
  }) async {
    // Return a predictable failure map so callers can handle gracefully.
    return {
      'success': false,
      'message': 'Refund service unavailable in this build',
    };
  }

  /// Placeholder stream for refund status.
  Stream<dynamic> listenRefundStatus(String bookingId) {
    return const Stream.empty();
  }
}
