import 'package:flutter/material.dart';
import 'native/native_add.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoadSo Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FFI LoadSo Demo'),
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
  bool _initialized = false;
  String _result = '';
  final TextEditingController _aController = TextEditingController(text: '10');
  final TextEditingController _bController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _initializeNative();
  }

  void _initializeNative() {
    final success = NativeAdd.instance.initialize();
    setState(() {
      _initialized = success;
      if (success) {
        _result = 'Native library loaded successfully!';
      } else {
        _result = 'Failed: ${NativeAdd.lastError}';
      }
    });
  }

  void _performOperation(String operation) {
    if (!_initialized) {
      setState(() {
        _result = 'Native library not initialized';
      });
      return;
    }

    final a = int.tryParse(_aController.text) ?? 0;
    final b = int.tryParse(_bController.text) ?? 0;

    int res;
    switch (operation) {
      case 'add':
        res = NativeAdd.instance.addInt(a, b);
        setState(() {
          _result = '$a + $b = $res';
        });
        break;
      case 'subtract':
        res = NativeAdd.instance.subtractInt(a, b);
        setState(() {
          _result = '$a - $b = $res';
        });
        break;
      case 'multiply':
        res = NativeAdd.instance.multiplyInt(a, b);
        setState(() {
          _result = '$a * $b = $res';
        });
        break;
      case 'divide':
        res = NativeAdd.instance.divideInt(a, b);
        setState(() {
          _result = b != 0 ? '$a / $b = $res' : 'Division by zero';
        });
        break;
    }
  }

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Native SO Library Test',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _initialized ? '✓ Library Loaded' : '✗ Library Not Loaded',
              style: TextStyle(
                color: _initialized ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aController,
                    decoration: const InputDecoration(
                      labelText: 'Number A',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _bController,
                    decoration: const InputDecoration(
                      labelText: 'Number B',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _performOperation('add'),
                  child: const Text('Add (+)'),
                ),
                ElevatedButton(
                  onPressed: () => _performOperation('subtract'),
                  child: const Text('Subtract (-)'),
                ),
                ElevatedButton(
                  onPressed: () => _performOperation('multiply'),
                  child: const Text('Multiply'),
                ),
                ElevatedButton(
                  onPressed: () => _performOperation('divide'),
                  child: const Text('Divide'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
