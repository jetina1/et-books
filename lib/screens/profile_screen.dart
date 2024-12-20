import 'package:et_books/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:et_books/config.dart'; // Assumes `apiUrl` is defined here
import 'package:shared_preferences/shared_preferences.dart'; // For shared preferences to retrieve the token

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>> fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // Handle the case where token is not available (shouldn't happen if you're already logged in)
      return {};
    }

    final url = Uri.parse('$apiUrl/auth/user');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Handle error (e.g., display a message to the user)
      throw Exception('Failed to load user details');
    }
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // Navigate to sign-in screen after logout
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignInPage()),
    ); // Assuming your sign-in route is named '/signin'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.yellow[700])),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading user details'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No user data available'));
          } else {
            final user = snapshot.data!;
            // Construct profile image URL
            final profileImageUrl = user['profilePicture'] != null
                ? '$apiUrl/auth/profile/${user['profilePicture']}'
                : '$apiUrl/auth/profile/';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileImageUrl),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    user['name'], // Display name from user data
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[700], // Golden color
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Text(
                    user['email'], // Display email from user data
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to another page or perform an action
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.yellow[700],
                            backgroundColor: Colors.black, // Text color
                          ),
                          child: Text('Edit Profile'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () =>
                              logout(context), // Use logout function
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor: Colors.black, // Text color
                          ),
                          child: Text('Log Out'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
