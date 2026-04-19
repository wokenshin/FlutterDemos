import 'dart:ffi';
import 'package:flutter/material.dart';

// Try to load the native library, fallback to Dart implementation if fails
late int Function(int, int) add_c;
bool isNativeLibraryLoaded = false;

void loadNativeLibrary() {
  try {
    final DynamicLibrary nativeLib = DynamicLibrary.open('libaddition_c.so');
    add_c = nativeLib
        .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('add_c')
        .asFunction();
    isNativeLibraryLoaded = true;
  } catch (e) {
    print('Failed to load native library: $e');
    // Fallback to Dart implementation
    add_c = (a, b) => a + b;
    isNativeLibraryLoaded = false;
  }
}

// Initialize the library loading
void init() {
  loadNativeLibrary();
}

// Call init when the library is loaded
void main() {
  init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _addResult = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _performAddition() {
    setState(() {
      _addResult = add_c(10, 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              'Addition result:',
            ),
            Text(
              '$_addResult',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Library: ${isNativeLibraryLoaded ? 'Native C++' : 'Dart Fallback'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _performAddition,
            tooltip: 'Add 10 + 20',
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
