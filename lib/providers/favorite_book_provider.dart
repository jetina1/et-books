import 'package:flutter/material.dart';

class FavoriteBooksProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _favoriteBooks = [];

  List<Map<String, dynamic>> get favoriteBooks => _favoriteBooks;

  bool isFavorite(int bookId) {
    return _favoriteBooks.any((book) => book['id'] == bookId);
  }

  void toggleFavorite(Map<String, dynamic> book) {
    final existingIndex =
        _favoriteBooks.indexWhere((favBook) => favBook['id'] == book['id']);

    if (existingIndex >= 0) {
      _favoriteBooks.removeAt(existingIndex);
    } else {
      _favoriteBooks.add(book);
    }
    notifyListeners();
  }
}
