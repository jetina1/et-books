import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:et_books/providers/cart_book_provier.dart';
import 'package:et_books/screens/book_detail.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cartProvider.cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final book = cartProvider.cartItems[index];
                return Dismissible(
                  key: Key(book['id'].toString()), // Unique key for each item
                  direction: DismissDirection.endToStart, // Swipe direction
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    // Remove the item from the cart
                    cartProvider.removeFromCart(book);

                    // Show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${book['title']} removed from cart')),
                    );
                  },
                  child: ListTile(
                    leading: Image.network(
                        'https://lamerbook.com/public${book['thumbnails']}'),
                    title: Text(book['title']),
                    onTap: () {
                      // Navigate to BookDetailScreen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookDetailScreen(bookId: book['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
