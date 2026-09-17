import 'dart:ui';
import 'package:flutter/material.dart';

const Color appRed = Color(0xFFDD0004);

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the home page
      appBar: AppBar(
        backgroundColor: appRed, // Red header
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // White icons (like back button)
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white, // White text for header
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
              style: TextStyle(
                color: appRed, // Red text on white background
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$_counter',
              style: const TextStyle(
                color: appRed, // Red text on white background
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: appRed, // Ensure the FAB is red
        foregroundColor: Colors.white, // Ensure the + icon is white
        child: const Icon(Icons.add),
      ),
    );
  }
}
