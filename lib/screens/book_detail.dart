import 'package:flutter/material.dart';
import 'package:et_books/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:et_books/providers/cart_book_provier.dart';
import 'package:et_books/providers/favorite_book_provider.dart';
import 'package:et_books/screens/chapa_payment_webview_screen.dart';
import 'package:et_books/screens/pdf_screen.dart';
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
    fetchBookDetails();
    checkPurchaseStatus();
    getUserToken(); // Fetch the stored token on initialization
  }

  Future<void> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userToken = prefs.getString('token');
    });
  }

  Future<void> fetchUserDetails() async {
    final url = Uri.parse('$apiUrl/auth/user');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $userToken'},
      );
      if (response.statusCode == 200) {
        final userDetails = json.decode(response.body);
        setState(() {
          userId = userDetails['id']; // Extract user ID
        });
      } else {
        print('Failed to load user details: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
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
    final url = Uri.parse('$apiUrl/books/user-book/check');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Retrieve the token from storage

    if (token == null) {
      print('User token is missing.');
      return;
    }

    final body = jsonEncode({
      'bookId': widget.bookId, // Only send bookId
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Include token in Authorization header
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          hasPurchased = result['hasPurchased']; // true or false
        });

        // Navigate to PDF screen if purchased
        if (hasPurchased) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfScreen(
                pdfUrl: 'https://lamerbook.com/public${book?['pdf_path']}',
              ),
            ),
          );
        }
      } else {
        print('Failed to check purchase status: ${response.body}');
      }
    } catch (e) {
      print('Error checking purchase status: $e');
    }
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
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PdfScreen(
                                          pdfUrl:
                                              'https://lamerbook.com/public${book?['pdf_path']}',
                                        ),
                                      ),
                                    );
                                  }
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
                                onPressed: () {
                                  if (hasPurchased) {
                                    return;
                                  }
                                  if (userId != null) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentScreen(
                                          amount:
                                              book?['price']?.toString() ?? '0',
                                          bookTitle:
                                              book?['title'] ?? 'Unknown Book',
                                          bookId:
                                              book?['id']?.toString() ?? '0',
                                          pdfUrl:
                                              book?['pdfUrl']?.toString() ?? '',
                                          userId: userId.toString(),
                                        ),
                                      ),
                                    );
                                  } else {
                                    print('User ID is missing or invalid.');
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

// import 'package:et_books/screens/chapa_payment_webview_screen.dart';
// import 'package:et_books/screens/pdf_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:et_books/config.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import 'package:et_books/providers/cart_book_provier.dart';
// import 'package:et_books/providers/favorite_book_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class BookDetailScreen extends StatefulWidget {
//   final int bookId;

//   const BookDetailScreen({super.key, required this.bookId});

//   @override
//   _BookDetailScreenState createState() => _BookDetailScreenState();
// }

// class _BookDetailScreenState extends State<BookDetailScreen> {
//   Map<String, dynamic>? book;
//   bool isLoading = true;
//   bool hasPurchased = false;
//   String? userToken;
//   int? userId;

//   @override
//   void initState() {
//     super.initState();
//     fetchBookDetails();
//     checkPurchaseStatus();
//     getUserToken(); // Fetch the stored token on initialization
//   }

//   Future<void> getUserToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       userToken = prefs.getString('token');
//     });
//   }

//   Future<void> fetchUserDetails() async {
//     final url = Uri.parse('$apiUrl/auth/user');
//     try {
//       final response = await http.get(
//         url,
//         headers: {'Authorization': 'Bearer $userToken'},
//       );
//       if (response.statusCode == 200) {
//         // Parse user details from the response
//         final userDetails = json.decode(response.body);
//         setState(() {
//           userId = userDetails['id']; // Extract user ID
//         });
//       } else {
//         print('Failed to load user details: ${response.body}');
//       }
//     } catch (e) {
//       print('Error fetching user details: $e');
//     }
//   }

//   Future<void> fetchBookDetails() async {
//     final url = Uri.parse('$apiUrl/books/specific/${widget.bookId}');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         setState(() {
//           book = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         print('Failed to load book details: ${response.body}');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching book details: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> checkPurchaseStatus() async {
//     final userId = this.userId; // Use the extracted user ID
//     final url = Uri.parse(
//         '$apiUrl/user-book/check?userId=$userId&bookId=${widget.bookId}');
//     // '$apiUrl/books/check-purchase?userId=$userId&bookId=${widget.bookId}');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);
//         setState(() {
//           hasPurchased = result['hasPurchased']; // true or false
//         });
//       } else {
//         print('Failed to check purchase status: ${response.body}');
//       }
//     } catch (e) {
//       print('Error checking purchase status: $e');
//     }
//   }

//   Widget renderBookDetail(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: Colors.yellow,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 16, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final favoriteProvider = Provider.of<FavoriteBooksProvider>(context);
//     final cartProvider = Provider.of<CartProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           book?['title'] ?? 'Book Details',
//           style: const TextStyle(color: Colors.yellow),
//         ),
//         backgroundColor: Colors.black,
//         actions: [
//           if (book != null)
//             IconButton(
//               icon: Icon(
//                 favoriteProvider.isFavorite(book!['id'])
//                     ? Icons.favorite
//                     : Icons.favorite_border,
//                 color: Colors.yellow,
//               ),
//               onPressed: () {
//                 favoriteProvider.toggleFavorite(book!);
//               },
//             ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : book == null
//               ? const Center(
//                   child: Text(
//                     "Failed to load book details.",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (book?['thumbnails'] != null)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8.0),
//                             child: Image.network(
//                               'https://lamerbook.com/public${book?['thumbnails']}',
//                               // '$apiUrl/books/thumbnails/${book?['thumbnails']}',
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         const SizedBox(height: 16),
//                         Text(
//                           book?['title'] ?? 'Unknown Title',
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.yellow,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         renderBookDetail(
//                             'Author', book?['author'] ?? 'Unknown Author'),
//                         renderBookDetail(
//                             'Price', book?['price']?.toString() ?? 'N/A'),
//                         renderBookDetail('Published At',
//                             book?['published_at'] ?? 'Not Published Yet'),
//                         const SizedBox(height: 8),
//                         renderBookDetail(
//                           'Description',
//                           book?['description'] ?? 'No description available.',
//                         ),
//                         const Divider(
//                           color: Colors.yellow,
//                           height: 32,
//                           thickness: 1,
//                         ),
//                         if (book?['isfree'] == true || hasPurchased)
//                           ElevatedButton.icon(
//                             onPressed: book?['pdf_path'] != null
//                                 ? () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => PdfScreen(
//                                           pdfUrl:
//                                               // '$apiUrl/books/pdf/${book?['pdf_path']}',
//                                               'https://lamerbook.com/public${book?['pdf_path']}',
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 : null,
//                             icon: const Icon(Icons.picture_as_pdf),
//                             label: const Text("View PDF"),
//                           )
//                         else
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   cartProvider.addToCart(book!);
//                                 },
//                                 icon: const Icon(Icons.shopping_cart),
//                                 label: const Text("Add to Cart"),
//                               ),
//                               ElevatedButton.icon(
//                                 onPressed: hasPurchased
//                                     ? null
//                                     : () {
//                                         if (book != null) {
//                                           Navigator.pushReplacement(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder: (context) =>
//                                                   PaymentScreen(
//                                                 amount: book?['price']
//                                                         ?.toString() ??
//                                                     '0',
//                                                 bookTitle: book?['title'] ??
//                                                     'Unknown Book',
//                                                 bookId:
//                                                     book?['id']?.toString() ??
//                                                         '0',
//                                               ),
//                                             ),
//                                           );
//                                         }
//                                       },
//                                 icon: const Icon(Icons.payment),
//                                 label: Text(
//                                     hasPurchased ? "Purchased" : "Purchase"),
//                               ),
//                             ],
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }
// }






// import 'package:et_books/screens/chapa_payment_webview_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:et_books/config.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import 'package:et_books/providers/cart_book_provier.dart';
// import 'package:et_books/providers/favorite_book_provider.dart';

// class BookDetailScreen extends StatefulWidget {
//   final int bookId;

//   const BookDetailScreen({super.key, required this.bookId});

//   @override
//   _BookDetailScreenState createState() => _BookDetailScreenState();
// }

// class _BookDetailScreenState extends State<BookDetailScreen> {
//   Map<String, dynamic>? book;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchBookDetails();
//   }

//   Future<void> fetchBookDetails() async {
//     final url = Uri.parse('$apiUrl/books/specific/${widget.bookId}');

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         setState(() {
//           book = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         print('Failed to load book details: ${response.body}');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching book details: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Widget renderBookDetail(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: Colors.yellow,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 16, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final favoriteProvider = Provider.of<FavoriteBooksProvider>(context);
//     final cartProvider = Provider.of<CartProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           book?['title'] ?? 'Book Details',
//           style: const TextStyle(color: Colors.yellow),
//         ),
//         backgroundColor: Colors.black,
//         actions: [
//           if (book != null)
//             IconButton(
//               icon: Icon(
//                 favoriteProvider.isFavorite(book!['id'])
//                     ? Icons.favorite
//                     : Icons.favorite_border,
//                 color: Colors.yellow,
//               ),
//               onPressed: () {
//                 favoriteProvider.toggleFavorite(book!);
//               },
//             ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : book == null
//               ? const Center(
//                   child: Text(
//                     "Failed to load book details.",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (book?['thumbnails'] != null)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8.0),
//                             child: Image.network(
//                               '$apiUrl/books/thumbnails/${book?['thumbnails']}',
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         const SizedBox(height: 16),
//                         Text(
//                           book?['title'] ?? 'Unknown Title',
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.yellow,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         renderBookDetail(
//                             'Author', book?['author'] ?? 'Unknown Author'),
//                         renderBookDetail(
//                             'Price', book?['price']?.toString() ?? 'N/A'),
//                         renderBookDetail('Published At',
//                             book?['published_at'] ?? 'Not Published Yet'),
//                         const SizedBox(height: 8),
//                         renderBookDetail(
//                           'Description',
//                           book?['description'] ?? 'No description available.',
//                         ),
//                         const Divider(
//                           color: Colors.yellow,
//                           height: 32,
//                           thickness: 1,
//                         ),
//                         if (book?['isfree'] == true)
//                           ElevatedButton.icon(
//                             onPressed: book?['pdf_path'] != null
//                                 ? () {
//                                     // Navigate to PDF view
//                                   }
//                                 : null,
//                             icon: const Icon(Icons.picture_as_pdf),
//                             label: const Text("View PDF"),
//                           )
//                         else
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   cartProvider.addToCart(book!);
//                                 },
//                                 icon: const Icon(Icons.shopping_cart),
//                                 label: const Text("Add to Cart"),
//                               ),
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   if (book != null) {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => PaymentScreen(
//                                           amount:
//                                               book?['price']?.toString() ?? '0',
//                                           bookTitle:
//                                               book?['title'] ?? 'Unknown Book',
//                                           bookId: book?['id']?.toString() ??
//                                               '0', // Convert bookId to String
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                                 icon: const Icon(Icons.payment),
//                                 label: const Text("Purchase"),
//                               ),
//                             ],
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }
// }
