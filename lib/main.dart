import 'package:flutter/material.dart';

const Color appRed = Color(0xFFDD0004);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSIc',
      theme: ThemeData(
        // Custom red and white theme
        primaryColor: appRed,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Doto', // Use local Doto font
        colorScheme: const ColorScheme.light(
          primary: appRed,
          secondary: appRed,
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: appRed,
          displayColor: appRed,
          fontFamily: 'Doto',
        ).copyWith(
          bodyMedium: const TextStyle(fontWeight: FontWeight.bold, color: appRed),
          bodyLarge: const TextStyle(fontWeight: FontWeight.bold, color: appRed),
          titleLarge: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appRed,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: appRed,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyHomePage(title: 'MSIc App'),
    );
  }
}

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
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
              style: TextStyle(
                color: appRed,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$_counter',
              style: const TextStyle(
                color: appRed,
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
