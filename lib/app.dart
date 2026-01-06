import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'True Root',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text(
            'True Root – Clean Start',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
