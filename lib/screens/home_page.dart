import 'package:flutter/material.dart';
import 'package:et_books/screens/drawer.dart';
import 'package:et_books/config.dart';
import 'package:et_books/screens/book_detail.dart';
import 'package:et_books/screens/profile_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> categories = [];
  String selectedCategory = "Non-Fiction"; // Default category
  List<Map<String, dynamic>> books = [];
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse('$apiUrl/categories/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final fetchedCategories =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        List<Map<String, dynamic>> validCategories = [];

        // Check availability of books for each category
        for (var category in fetchedCategories) {
          final booksResponse = await http
              .get(Uri.parse('$apiUrl/books/category/${category['name']}'));
          if (booksResponse.statusCode == 200) {
            final categoryBooks = List<Map<String, dynamic>>.from(
                json.decode(booksResponse.body));
            if (categoryBooks.isNotEmpty) {
              validCategories.add(category);
            }
          }
        }

        setState(() {
          categories = validCategories;
          if (categories.isNotEmpty) {
            selectedCategory = categories[0]['name'];
            fetchBooks(selectedCategory);
          }
          _isLoading = false;
        });
      } else {
        print('Failed to load categories: ${response.statusCode}');
        _showSnackBar('Failed to load categories. Please try again later.');
        _isLoading = false;
      }
    } catch (e) {
      print('Error fetching categories: $e');
      _showSnackBar('An error occurred. Please try again later.');
      _isLoading = false;
    }
  }

  Future<void> fetchBooks(String category) async {
    final url = Uri.parse('$apiUrl/books/category/$category');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        books = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      print('Failed to load books: ${response.statusCode}');
    }
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    fetchBooks(category);
  }

  void _showSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        navigateToProfile: () {},
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator()) // Single progress indicator
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover\nLatest books',
                        style: TextStyle(
                          fontSize: screenHeight * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow[700],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        height: screenHeight * 0.07,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return GestureDetector(
                              onTap: () => selectCategory(category['name']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  color: selectedCategory == category['name']
                                      ? Colors.yellow[700]
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    color: selectedCategory == category['name']
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailScreen(bookId: book['id']),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Column(
                                  children: [
                                    Container(
                                      width: screenWidth * 0.25,
                                      height: screenHeight * 0.18,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              'https://lamerbook.com/public${book['thumbnails']}'),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    SizedBox(
                                      width: screenWidth * 0.3,
                                      child: Text(
                                        book['title'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Text(
                        'Audio Books',
                        style: TextStyle(
                          fontSize: screenHeight * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:et_books/screens/drawer.dart';
// import 'package:et_books/config.dart';
// import 'package:et_books/screens/book_detail.dart';
// import 'package:et_books/screens/profile_screen.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<Map<String, dynamic>> categories = [];
//   String selectedCategory = "Non-Fiction"; // Default category
//   List<Map<String, dynamic>> books = [];
//   Map<String, dynamic> userData = {
//     "name": "John Doe",
//     "email": "johndoe@example.com"
//   }; // Example user data
//   bool _isLoading = true; // Loading state

//   @override
//   void initState() {
//     super.initState();
//     fetchCategories();
//   }

//   Future<void> fetchCategories() async {
//     final url = Uri.parse('$apiUrl/categories/all');

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final fetchedCategories =
//             List<Map<String, dynamic>>.from(json.decode(response.body));
//         List<Map<String, dynamic>> validCategories = [];

//         // Check availability of books for each category
//         for (var category in fetchedCategories) {
//           final booksResponse = await http
//               .get(Uri.parse('$apiUrl/books/category/${category['name']}'));
//           if (booksResponse.statusCode == 200) {
//             final categoryBooks = List<Map<String, dynamic>>.from(
//                 json.decode(booksResponse.body));
//             if (categoryBooks.isNotEmpty) {
//               validCategories.add(category);
//             }
//           }
//         }

//         setState(() {
//           categories = validCategories;
//           if (categories.isNotEmpty) {
//             selectedCategory = categories[0]['name'];
//             fetchBooks(selectedCategory);
//           }
//           _isLoading = false; // Stop loading once data is loaded
//         });
//       } else {
//         // Handle error
//         print('Failed to load categories: ${response.statusCode}');
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content:
//                     Text('Failed to load categories. Please try again later.')),
//           );
//         }
//         _isLoading = false; // Stop loading on error
//       }
//     } catch (e) {
//       // Catch network exceptions
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('An error occurred. Please try again later.')),
//         );
//       }
//       _isLoading = false; // Stop loading on error
//     }
//   }

//   Future<void> fetchBooks(String category) async {
//     final url = Uri.parse('$apiUrl/books/category/$category');

//     final response = await http.get(url);
//     if (response.statusCode == 200) {
//       setState(() {
//         books = List<Map<String, dynamic>>.from(json.decode(response.body));
//       });
//     } else {
//       print('Response Status Code: ${response.statusCode}');
//       print('Response Body: ${response.body}');
//     }
//   }

//   void selectCategory(String category) {
//     setState(() {
//       selectedCategory = category;
//     });
//     fetchBooks(category);
//   }

//   void navigateToProfile() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ProfileScreen(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.account_circle),
//             onPressed: navigateToProfile,
//           ),
//         ],
//       ),
//       drawer: CustomDrawer(
//         navigateToProfile: navigateToProfile,
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator()) // Show loading indicator
//           : SizedBox(
//               height: screenHeight,
//               width: screenWidth,
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Discover\nLatest books',
//                         style: TextStyle(
//                           fontSize: screenHeight * 0.03, // Dynamic font size
//                           fontWeight: FontWeight.bold,
//                           color: Colors.yellow[700],
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.02),
//                       SizedBox(
//                         height: screenHeight *
//                             0.07, // Dynamic height for categories
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: categories.length,
//                           itemBuilder: (context, index) {
//                             final category = categories[index];
//                             return GestureDetector(
//                               onTap: () => selectCategory(category['name']),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 12.0),
//                                 margin: const EdgeInsets.only(right: 8.0),
//                                 decoration: BoxDecoration(
//                                   color: selectedCategory == category['name']
//                                       ? Colors.yellow[700]
//                                       : Colors.grey[800],
//                                   borderRadius: BorderRadius.circular(20.0),
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   category['name'],
//                                   style: TextStyle(
//                                     color: selectedCategory == category['name']
//                                         ? Colors.black
//                                         : Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.02),
//                       SizedBox(
//                         height: screenHeight * 0.25, // Dynamic height for books
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: books.length,
//                           itemBuilder: (context, index) {
//                             final book = books[index];
//                             return GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         BookDetailScreen(bookId: book['id']),
//                                   ),
//                                 );
//                               },
//                               child: Padding(
//                                 padding: const EdgeInsets.only(right: 8.0),
//                                 child: Column(
//                                   children: [
//                                     Container(
//                                       width:
//                                           screenWidth * 0.25, // Dynamic width
//                                       height:
//                                           screenHeight * 0.18, // Dynamic height
//                                       decoration: BoxDecoration(
//                                         image: DecorationImage(
//                                           image: NetworkImage(
//                                               // '$apiUrl/books/thumbnails/${book['thumbnails']}'),
//                                               'https://lamerbook.com/public${book['thumbnails']}'), // Fetch image URL
//                                           fit: BoxFit.cover,
//                                         ),
//                                         borderRadius:
//                                             BorderRadius.circular(8.0),
//                                       ),
//                                     ),
//                                     SizedBox(height: screenHeight * 0.01),
//                                     SizedBox(
//                                       width: screenWidth * 0.3,
//                                       child: Text(
//                                         book['title'],
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.white,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.04),
//                       Text(
//                         'Audio Books',
//                         style: TextStyle(
//                           fontSize: screenHeight * 0.03, // Dynamic font size
//                           fontWeight: FontWeight.bold,
//                           color: Colors.yellow[700],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }
// }
