import 'package:flutter/material.dart';
import 'package:saferest_mobile/utils/routes.dart'; // Import the routes

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: Routes.splash,  // Set initial page to login
      routes: Routes.routes,       // Use the defined routes
    );
  }
}
