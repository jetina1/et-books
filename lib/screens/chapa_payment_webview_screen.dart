import 'package:et_books/config.dart';
import 'package:et_books/screens/pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentScreen extends StatefulWidget {
  final String amount;
  final String bookTitle;
  final String bookId;
  final String pdfUrl;
  final String userId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.bookTitle,
    required this.bookId,
    required this.pdfUrl,
    required this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? checkoutUrl;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains("success")) {
              handlePaymentResult(success: true);
            } else if (url.contains("failure")) {
              handlePaymentResult(success: false);
            }
          },
        ),
      );
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
      final String userId = userData["id"].toString();
      final String email = userData["email"];
      final String fullName = userData["name"];

      final txRef =
          "$userId${widget.bookId}${DateTime.now().millisecondsSinceEpoch}";

      // Initialize payment
      final paymentResponse = await http.post(
        Uri.parse("$apiUrl/payment/initialize"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": widget.amount,
          "email": email,
          "fullname": fullName,
          "txRef": txRef,
          "callbackUrl": "$secureApiUrl/payment/webhook",
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

  void handlePaymentResult({required bool success}) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "Payment Successful!" : "Payment Failed!"),
    ));

    if (success) {
      await verifyPayment();
    }
  }

  Future<void> verifyPayment() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("auth_token");

      if (token == null) {
        logError("Token not found during payment verification.");
        showMessage("Token not found. Please log in again.");
        return;
      }

      final verificationResponse = await http.post(
        Uri.parse("$apiUrl/payment/payment/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "txRef":
              "${widget.userId}${widget.bookId}${DateTime.now().millisecondsSinceEpoch}", // Correctly using the transaction reference
          "userId": widget.userId, // Correct user ID
          "bookId": widget.bookId, // Correct book ID
        }),
      );

      if (verificationResponse.statusCode != 200) {
        logError(
            "Payment verification failed. Status Code: ${verificationResponse.statusCode}");
        showMessage("Verification failed. Please try again.");
        return;
      }

      final result = jsonDecode(verificationResponse.body);
      if (result["message"] == "Payment verified, book granted.") {
        showMessage("Payment verified. Enjoy your book!");
        // Navigate to PDF screen without using named parameters
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => PdfScreen(
            // bookId: widget.bookId,
            // bookTitle: widget.bookTitle,
            pdfUrl: '',
          ),
        ));
      } else {
        logError("Payment verification returned: ${result["message"]}");
        showMessage("Payment verification failed.");
      }
    } catch (e, stacktrace) {
      logError(
          "An error occurred during payment verification: $e\n$stacktrace");
      showMessage("An unexpected error occurred. Please try again.");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void logError(String error) {
    debugPrint("ERROR: $error");
    // Optionally, send the error to a logging service or save locally.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pay for ${widget.bookTitle}"),
      ),
      body: checkoutUrl == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:et_books/config.dart';

// class PaymentScreen extends StatefulWidget {
//   final String amount;
//   final String bookTitle;
//   final String bookId;

//   const PaymentScreen({
//     super.key,
//     required this.amount,
//     required this.bookTitle,
//     required this.bookId,
//   });

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   String? checkoutUrl;
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (url) {
//             if (url.contains("success")) {
//               handlePaymentResult(success: true);
//             } else if (url.contains("failure")) {
//               handlePaymentResult(success: false);
//             }
//           },
//         ),
//       );
//     initializePayment();
//   }

//   Future<void> initializePayment() async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       final String? token = prefs.getString("token");

//       if (token == null) {
//         logError("Token not found.");
//         showMessage("Token not found. Please log in again.");
//         return;
//       }

//       final userResponse = await http.get(
//         Uri.parse("$apiUrl/auth/user"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );

//       if (userResponse.statusCode != 200) {
//         logError(
//             "Failed to fetch user details. Status Code: ${userResponse.statusCode}");
//         showMessage("Failed to fetch user details.");
//         return;
//       }

//       final userData = jsonDecode(userResponse.body);
//       final String userId = userData["id"].toString();
//       final String email = userData["email"];
//       final String fullName = userData["name"];

//       final txRef =
//           "$userId-${widget.bookId}-${DateTime.now().millisecondsSinceEpoch}";

//       final paymentResponse = await http.post(
//         Uri.parse("$apiUrl/payment/initialize"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "amount": widget.amount,
//           "email": email,
//           "fullname": fullName,
//           "txRef": txRef,
//           "callbackUrl": "$secureApiUrl/payment/webhook",
//           "bookId": widget.bookId,
//           "userId": userId,
//         }),
//       );

//       if (paymentResponse.statusCode != 200) {
//         logError(
//             "Payment initialization failed. Status Code: ${paymentResponse.statusCode}");
//         showMessage("Payment initialization failed.");
//         return;
//       }

//       final paymentData = jsonDecode(paymentResponse.body);
//       setState(() {
//         checkoutUrl = paymentData["data"]["checkout_url"];
//       });

//       if (checkoutUrl != null) {
//         _controller.loadRequest(Uri.parse(checkoutUrl!));
//       } else {
//         logError("Checkout URL is null.");
//         showMessage("Failed to retrieve payment URL.");
//       }
//     } catch (e, stacktrace) {
//       logError(
//           "An error occurred during payment initialization: $e\n$stacktrace");
//       showMessage("An unexpected error occurred. Please try again.");
//     }
//   }

//   void handlePaymentResult({required bool success}) async {
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(success ? "Payment Successful!" : "Payment Failed!"),
//     ));

//     if (success) {
//       await verifyPayment();
//     }
//   }

//   Future<void> verifyPayment() async {
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       final String? token = prefs.getString("auth_token");

//       if (token == null) {
//         logError("Token not found during payment verification.");
//         showMessage("Token not found. Please log in again.");
//         return;
//       }

//       final verificationResponse = await http.post(
//         Uri.parse("$apiUrl/payment/payment/verify"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "txRef": "$checkoutUrl", // Reference from payment initialization
//           "userId": widget.bookId,
//           "bookId": widget.bookId,
//         }),
//       );

//       if (verificationResponse.statusCode != 200) {
//         logError(
//             "Payment verification failed. Status Code: ${verificationResponse.statusCode}");
//         showMessage("Verification failed. Please try again.");
//         return;
//       }

//       final result = jsonDecode(verificationResponse.body);
//       if (result["message"] == "Payment verified, book granted.") {
//         showMessage("Payment verified. Enjoy your book!");
//         // Navigate to book details or PDF screen
//       } else {
//         logError("Payment verification returned: ${result["message"]}");
//         showMessage("Payment verification failed.");
//       }
//     } catch (e, stacktrace) {
//       logError(
//           "An error occurred during payment verification: $e\n$stacktrace");
//       showMessage("An unexpected error occurred. Please try again.");
//     }
//   }

//   void showMessage(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   void logError(String error) {
//     debugPrint("ERROR: $error");
//     // Optionally, send the error to a logging service or save locally.
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Pay for ${widget.bookTitle}"),
//       ),
//       body: checkoutUrl == null
//           ? const Center(child: CircularProgressIndicator())
//           : WebViewWidget(controller: _controller),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:et_books/config.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PaymentScreen extends StatefulWidget {
//   final String amount;
//   final String bookTitle;
//   final String bookId;

//   const PaymentScreen({
//     super.key,
//     required this.amount,
//     required this.bookTitle,
//     required this.bookId,
//   });

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   String? checkoutUrl;
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (url) {
//             if (url.contains("success")) {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                 content: Text("Payment Successful!"),
//               ));
//             } else if (url.contains("failure")) {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                 content: Text("Payment Failed!"),
//               ));
//             }
//           },
//         ),
//       );

//     initializePayment();
//   }

//   Future<void> initializePayment() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString("token");

//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Token not found. Please log in again."),
//       ));
//       return;
//     }

//     // Fetch user details
//     final userResponse = await http.get(
//       Uri.parse("$apiUrl/auth/user"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );

//     if (userResponse.statusCode == 200) {
//       final userData = jsonDecode(userResponse.body);

//       final String fullName = userData["name"] ?? "Unknown User";
//       final String email = userData["email"] ?? "unknown@example.com";
//       final String userId =
//           userData["id"].toString(); // Assuming 'id' is the user's ID
//       // Initialize Payment
//       // final txRef = "tx-${DateTime.now().millisecondsSinceEpoch}";
//       final txRef =
//           "$userId-${widget.bookId}-${DateTime.now().millisecondsSinceEpoch}";

//       final paymentResponse = await http.post(
//         Uri.parse("$apiUrl/payment/initialize"),
//         headers: {
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "amount": widget.amount,
//           "email": email,
//           "fullname": fullName,
//           "txRef": txRef,
//           "callbackUrl": "$apiUrl/payment/webhook",
//           // "bookId": widget.bookId,
//           "bookId": widget.bookId.toString(),
//           "userId": userId,
//         }),
//       );

//       if (paymentResponse.statusCode == 200) {
//         final paymentData = jsonDecode(paymentResponse.body);
//         setState(() {
//           checkoutUrl = paymentData["data"]["checkout_url"];
//         });

//         if (checkoutUrl != null) {
//           _controller.loadRequest(Uri.parse(checkoutUrl!));
//         }
//       } else {
//         print("Failed to initialize payment: ${paymentResponse.body}");
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content:
//               Text("Payment initialization failed: ${paymentResponse.body}"),
//         ));
//       }
//     } else {
//       print("Failed to fetch user details: ${userResponse.body}");
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("Failed to fetch user details: ${userResponse.body}"),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Pay for ${widget.bookTitle}"),
//       ),
//       body: checkoutUrl == null
//           ? const Center(child: CircularProgressIndicator())
//           : WebViewWidget(controller: _controller),
//     );
//   }
// }
