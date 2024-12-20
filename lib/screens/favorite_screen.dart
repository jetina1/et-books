// import 'package:et_books/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:et_books/providers/favorite_book_provider.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteBooksProvider>(context);
    final favoriteBooks = favoriteProvider.favoriteBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Books',
          style: TextStyle(color: Colors.yellow),
        ),
        backgroundColor: Colors.black,
      ),
      body: favoriteBooks.isEmpty
          ? const Center(
              child: Text(
                'No favorite books yet!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: favoriteBooks.length,
              itemBuilder: (context, index) {
                final book = favoriteBooks[index];

                return ListTile(
                  leading: book['thumbnails'] != null
                      ? Image.network(
                          // '$apiUrl/books/thumbnails/${book['thumbnails']}',
                          'https://lamerbook.com/public${book['thumbnails']}',
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        )
                      : const Icon(Icons.book, size: 50, color: Colors.yellow),
                  title: Text(
                    book['title'] ?? 'Unknown Title',
                    style: const TextStyle(color: Colors.yellow),
                  ),
                  subtitle: Text(
                    book['author'] ?? 'Unknown Author',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      favoriteProvider.toggleFavorite(book);
                    },
                  ),
                );
              },
            ),
    );
  }
}
