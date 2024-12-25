import 'package:flutter/material.dart';
import 'package:et_books/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:et_books/providers/cart_book_provier.dart';
import 'package:et_books/providers/favorite_book_provider.dart';
import 'package:et_books/screens/chapa_payment_webview_screen.dart';
import 'package:et_books/screens/pdf_screen.dart';
import 'package:et_books/screens/signin_screen.dart'; // Correct import for SignInPage
import 'package:shared_preferences/shared_preferences.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Map<String, dynamic>? book;
  bool isLoading = true;
  bool hasPurchased = false;
  String? userToken;
  int? userId;

  @override
  void initState() {
    super.initState();
    getUserToken();
  }

  Future<void> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      setState(() {
        userToken = token;
      });
      await fetchUserDetails();
      await fetchBookDetails();
      await checkPurchaseStatus();
    } else {
      print('No token found. Redirecting to sign-in.');
      navigateToSignIn();
    }
  }

  Future<void> fetchUserDetails() async {
    if (userToken == null) {
      print('User token is null. Redirecting to sign-in.');
      navigateToSignIn();
      return;
    }

    final url = Uri.parse('$apiUrl/auth/user');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $userToken'},
      );
      if (response.statusCode == 200) {
        final userDetails = json.decode(response.body);
        setState(() {
          userId = userDetails['id'];
        });
        print('User ID: $userId');
      } else {
        print('Failed to load user details: ${response.body}');
        navigateToSignIn();
      }
    } catch (e) {
      print('Error fetching user details: $e');
      navigateToSignIn();
    }
  }

  void navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignInPage(),
      ),
    );
  }

  Future<void> fetchBookDetails() async {
    final url = Uri.parse('$apiUrl/books/specific/${widget.bookId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          book = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load book details: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching book details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkPurchaseStatus() async {
    if (userToken == null || userId == null) {
      print('User token or ID is missing.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$apiUrl/payment/user/book/check');
    final body = jsonEncode({'userId': userId, 'bookId': widget.bookId});

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: body,
      );

      // Debug: Print the response body
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Debug: Print the decoded response
        print('Response decoded: $result');

        setState(() {
          // Assuming the response contains a boolean field 'owned' or similar
          hasPurchased =
              result['owned'] ?? false; // Default to false if not found
        });

        if (hasPurchased && book != null) {
          print("User owns the book. Redirecting to PDF screen.");
          navigateToPdf();
        }
      } else if (response.statusCode == 404) {
        print("User does not own the book.");
        setState(() {
          hasPurchased = false;
        });
      } else {
        print(
            "Failed to check purchase status. Status Code: ${response.statusCode}, Response: ${response.body}");
        setState(() {
          hasPurchased = false;
        });
      }
    } catch (error) {
      print('Error checking purchase status: $error');
      setState(() {
        hasPurchased = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfScreen(
          pdfUrl: 'https://lamerbook.com/public${book?['pdf_path']}',
          bookId: widget.bookId,
          userId: userId!,
        ),
      ),
    );
  }

  Widget renderBookDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.yellow,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteBooksProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          book?['title'] ?? 'Book Details',
          style: const TextStyle(color: Colors.yellow),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (book != null)
            IconButton(
              icon: Icon(
                favoriteProvider.isFavorite(book!['id'])
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.yellow,
              ),
              onPressed: () {
                favoriteProvider.toggleFavorite(book!);
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : book == null
              ? const Center(
                  child: Text(
                    "Failed to load book details.",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book?['thumbnails'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              'https://lamerbook.com/public${book?['thumbnails']}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          book?['title'] ?? 'Unknown Title',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                        ),
                        const SizedBox(height: 12),
                        renderBookDetail(
                            'Author', book?['author'] ?? 'Unknown Author'),
                        renderBookDetail(
                            'Price', book?['price']?.toString() ?? 'N/A'),
                        renderBookDetail('Published At',
                            book?['published_at'] ?? 'Not Published Yet'),
                        const SizedBox(height: 8),
                        renderBookDetail(
                          'Description',
                          book?['description'] ?? 'No description available.',
                        ),
                        const Divider(
                          color: Colors.yellow,
                          height: 32,
                          thickness: 1,
                        ),
                        if (book?['isfree'] == true || hasPurchased)
                          ElevatedButton.icon(
                            onPressed: book?['pdf_path'] != null
                                ? navigateToPdf
                                : null,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text("View PDF"),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  cartProvider.addToCart(book!);
                                },
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text("Add to Cart"),
                              ),
                              ElevatedButton.icon(
                                onPressed: hasPurchased
                                    ? null
                                    : () {
                                        if (userId != null) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PaymentScreen(
                                                amount: double.parse(
                                                    book?['price']
                                                            ?.toString() ??
                                                        '0'),
                                                bookTitle: book?['title'] ??
                                                    'Unknown Book',
                                                bookId:
                                                    book?['id']?.toString() ??
                                                        '0',
                                                pdfUrl: book?['pdf_path']
                                                        ?.toString() ??
                                                    'https://lamerbook.com/public${book?['pdf_path']}',
                                                userId: userId.toString(),
                                              ),
                                            ),
                                          );
                                        } else {
                                          print('User ID is missing.');
                                        }
                                      },
                                icon: const Icon(Icons.payment),
                                label: Text(
                                    hasPurchased ? "Purchased" : "Purchase"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
