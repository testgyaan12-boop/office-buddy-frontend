/// Non-web fallback: web checkout is not supported on this platform.
Future<void> openWebCheckout({
  required Map<String, Object?> options,
  required void Function(String orderId, String paymentId, String signature) onSuccess,
  required void Function(String message) onError,
  required void Function() onDismiss,
}) {
  throw UnsupportedError('Razorpay web checkout is only supported on web');
}
