import 'package:flutter/material.dart';

class PurchasedBooksScreen extends StatelessWidget {
  const PurchasedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchased Books'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'This is the Purchased Books Screen',
          style: TextStyle(fontSize: 18, color: Colors.yellow[700]),
        ),
      ),
    );
  }
}
