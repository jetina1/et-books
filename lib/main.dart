import 'package:et_books/providers/cart_book_provier.dart';
import 'package:et_books/providers/favorite_book_provider.dart';
import 'package:et_books/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteBooksProvider()),
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
          // child: MyApp(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ET Books',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.yellow[700]),
          titleTextStyle: TextStyle(color: Colors.yellow[700]),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.yellow[700]),
          displayMedium: TextStyle(color: Colors.yellow[700]),
        ),
      ),
      home: const WelcomeScreen(), // Set WelcomeScreen as the initial screen
    );
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'ET Books',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: Colors.black,
//         scaffoldBackgroundColor: Colors.black,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.black,
//           iconTheme: IconThemeData(color: Colors.yellow[700]),
//           titleTextStyle: TextStyle(color: Colors.yellow[700]),
//         ),
//         drawerTheme: DrawerThemeData(
//           backgroundColor: Colors.black,
//         ),
//         textTheme: TextTheme(
//           bodyLarge: TextStyle(color: Colors.white),
//           bodyMedium: TextStyle(color: Colors.white),
//           displayLarge: TextStyle(color: Colors.yellow[700]),
//           displayMedium: TextStyle(color: Colors.yellow[700]),
//         ),
//       ),
//       home: const WelcomeScreen(), // Set HomePage as the initial screen
//     );
//   }
// }

// import 'package:et_books/providers/cart_book_provier.dart';
// import 'package:et_books/providers/favorite_book_provider.dart';
// import 'package:et_books/screens/welcome.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => FavoriteBooksProvider()),
//         ChangeNotifierProvider(create: (context) => CartProvider()),
//       ],
//       child: MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'ET Books',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: Colors.black,
//         scaffoldBackgroundColor: Colors.black,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.black,
//           iconTheme: IconThemeData(color: Colors.yellow[700]),
//           titleTextStyle: TextStyle(color: Colors.yellow[700]),
//         ),
//         drawerTheme: DrawerThemeData(
//           backgroundColor: Colors.black,
//         ),
//         textTheme: TextTheme(
//           bodyLarge: TextStyle(color: Colors.white),
//           bodyMedium: TextStyle(color: Colors.white),
//           displayLarge: TextStyle(color: Colors.yellow[700]),
//           displayMedium: TextStyle(color: Colors.yellow[700]),
//         ),
//       ),
//       home: const WelcomeScreen(), // Set WelcomeScreen as the initial screen
//     );
//   }
// }

