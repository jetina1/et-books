import 'package:et_books/screens/cart.dart';
import 'package:et_books/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:et_books/screens/favorite_screen.dart';
import 'package:et_books/screens/purchased_book_screen.dart'; // Import the new screen

class CustomDrawer extends StatelessWidget {
  final Function navigateToProfile;

  const CustomDrawer({super.key, required this.navigateToProfile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.yellow[700],
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.yellow[700]),
            title: const Text('Saved/Favorite Books',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart, color: Colors.yellow[700]),
            title: const Text('My Cart', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle, color: Colors.yellow[700]),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              navigateToProfile();
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books, color: Colors.yellow[700]),
            title:
                const Text('My Books', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchasedBooksScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.yellow[700]),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);

              // Handle logout logic (e.g., token deletion or clearing storage)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()),
                (route) => false, // Removes all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
// import 'package:et_books/screens/cart.dart';
// import 'package:et_books/screens/signin_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:et_books/screens/favorite_screen.dart';

// class CustomDrawer extends StatelessWidget {
//   final Function navigateToProfile;

//   const CustomDrawer({super.key, required this.navigateToProfile});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: const BoxDecoration(
//               color: Colors.black,
//             ),
//             child: Text(
//               'Menu',
//               style: TextStyle(
//                 color: Colors.yellow[700],
//                 fontSize: 24,
//               ),
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.favorite, color: Colors.yellow[700]),
//             title: const Text('Saved/Favorite Books',
//                 style: TextStyle(color: Colors.white)),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const FavoriteScreen(),
//                 ),
//               );
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.shopping_cart, color: Colors.yellow[700]),
//             title: const Text('My Cart', style: TextStyle(color: Colors.white)),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const CartScreen(),
//                 ),
//               );
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.account_circle, color: Colors.yellow[700]),
//             title: const Text('Profile', style: TextStyle(color: Colors.white)),
//             onTap: () {
//               Navigator.pop(context);
//               navigateToProfile();
//             },
//           ),
//           const Divider(color: Colors.grey),
//           ListTile(
//             leading: Icon(Icons.logout, color: Colors.yellow[700]),
//             title: const Text('Logout', style: TextStyle(color: Colors.white)),
//             onTap: () {
//               // Handle logout logic
//               Navigator.pop(context);

//               // You can implement token deletion here or clear local storage.
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (context) => SignInPage()),
//                 (route) => false, // Removes all previous routes
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
