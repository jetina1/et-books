import 'dart:convert';
import 'dart:developer';
import 'package:et_books/config.dart';
import 'package:et_books/screens/pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String userId;
  final String bookId;
  final double amount;
  final String pdfUrl;

  const PaymentScreen({
    super.key,
    required this.userId,
    required this.bookId,
    required this.amount,
    required this.pdfUrl,
    required bookTitle,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? checkoutUrl;
  late final WebViewController _controller;
  late final String txRef; // Declare txRef as a class-level variable
  // static const String apiUrl = "https://your-api-url.com";

  @override
  void initState() {
    super.initState();

    // Initialize txRef once during the widget lifecycle
    txRef =
        "${widget.userId}-${widget.bookId}-${DateTime.now().millisecondsSinceEpoch}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint("Finished loading URL: $url");
            if (url.contains("success")) {
              handlePaymentResult(success: true);
            } else if (url.contains("failure")) {
              handlePaymentResult(success: false);
            } else if (url.contains("test-payment-receipt")) {
              verifyPayment();
            }
          },
        ),
      );
    _controller.clearCache(); // Ensure the WebView cache is cleared
    initializePayment();
  }

  Future<void> initializePayment() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      if (token == null) {
        logError("Token not found.");
        showMessage("Token not found. Please log in again.");
        return;
      }

      // Fetch user details
      final userResponse = await http.get(
        Uri.parse("$apiUrl/auth/user"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (userResponse.statusCode != 200) {
        logError(
            "Failed to fetch user details. Status Code: ${userResponse.statusCode}");
        showMessage("Failed to fetch user details.");
        return;
      }

      final userData = jsonDecode(userResponse.body);
      final String email = userData["email"];
      final String fullName = userData["name"];

      // Initialize payment
      final paymentResponse = await http.post(
        Uri.parse("$apiUrl/payment/initialize"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": widget.amount,
          "email": email,
          "fullname": fullName,
          "txRef": txRef, // Use the same txRef
          "callbackUrl": "$apiUrl/payment/webhook",
          "bookId": widget.bookId,
          "userId": widget.userId,
        }),
      );

      if (paymentResponse.statusCode != 200) {
        logError(
            "Payment initialization failed. Status Code: ${paymentResponse.statusCode}");
        showMessage("Payment initialization failed.");
        return;
      }

      final paymentData = jsonDecode(paymentResponse.body);
      setState(() {
        checkoutUrl = paymentData["data"]["checkout_url"];
      });

      if (checkoutUrl != null) {
        _controller.loadRequest(Uri.parse(checkoutUrl!));
      } else {
        logError("Checkout URL is null.");
        showMessage("Failed to retrieve payment URL.");
      }
    } catch (e, stacktrace) {
      logError(
          "An error occurred during payment initialization: $e\n$stacktrace");
      showMessage("An unexpected error occurred. Please try again.");
    }
  }

  Future<void> verifyPayment() async {
    try {
      final verificationResponse = await http.post(
        Uri.parse("$apiUrl/payment/verify"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "txRef": txRef, // Use the same txRef for verification
          "userId": widget.userId,
          "bookId": widget.bookId,
        }),
      );

      if (verificationResponse.statusCode == 200) {
        final result = jsonDecode(verificationResponse.body);
        if (result["message"] == "Payment verified, book granted.") {
          showMessage("Payment verified. Enjoy your book!");

          // Navigate to PDF screen after successful payment
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => PdfScreen(
              // pdfUrl: 'https://lamerbook.com/public$widget.pdfUrl',
              pdfUrl: 'https://lamerbook.com/public/${widget.pdfUrl}',

              bookId: int.parse(widget.bookId),
              userId: int.parse(widget.userId),
            ),
          ));
        } else {
          logError("Payment verification returned: ${result["message"]}");
          showMessage("Payment verification failed.");
        }
      } else {
        showMessage("Verification failed. Please try again.");
      }
    } catch (e, stacktrace) {
      logError(
          "An error occurred during payment verification: $e\n$stacktrace");
      showMessage("An unexpected error occurred. Please try again.");
    }
  }

  void handlePaymentResult({required bool success}) {
    if (success) {
      showMessage("Payment successful! Verifying...");
      verifyPayment();
    } else {
      showMessage("Payment failed. Please try again.");
    }
  }

  void logError(String message) {
    log(message);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
      ),
      body: checkoutUrl != null
          ? WebViewWidget(controller: _controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
