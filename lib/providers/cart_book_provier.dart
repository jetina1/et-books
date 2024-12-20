import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> book) {
    _cartItems.add(book);
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> book) {
    _cartItems.remove(book);
    notifyListeners();
  }

  bool isInCart(Map<String, dynamic> book) {
    return _cartItems.contains(book);
  }
}
