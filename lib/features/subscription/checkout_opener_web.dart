import 'dart:js_interop';

@JS('Razorpay')
extension type _RazorpayJS._(JSObject _) implements JSObject {
  external _RazorpayJS(JSObject options);
  external void open();
  external void on(String event, JSFunction callback);
}

/// Opens Razorpay Checkout.js on web. Callbacks run on success / failure / dismiss.
Future<void> openWebCheckout({
  required Map<String, Object?> options,
  required void Function(String orderId, String paymentId, String signature) onSuccess,
  required void Function(String message) onError,
  required void Function() onDismiss,
}) async {
  void jsHandler(JSAny? response) {
    final map = response?.dartify();
    if (map is Map) {
      onSuccess(
        map['razorpay_order_id']?.toString() ?? '',
        map['razorpay_payment_id']?.toString() ?? '',
        map['razorpay_signature']?.toString() ?? '',
      );
    } else {
      onError('Invalid payment response');
    }
  }

  void jsFailed(JSAny? response) {
    String message = 'Payment failed';
    final map = response?.dartify();
    if (map is Map) {
      final error = map['error'];
      if (error is Map && error['description'] != null) {
        message = error['description'].toString();
      }
    }
    onError(message);
  }

  void jsDismiss() => onDismiss();

  final merged = Map<String, Object?>.of(options)
    ..['handler'] = jsHandler.toJS
    ..['modal'] = <String, Object?>{'ondismiss': jsDismiss.toJS};

  final checkout = _RazorpayJS(merged.jsify() as JSObject);
  checkout.on('payment.failed', jsFailed.toJS);
  checkout.open();
}
