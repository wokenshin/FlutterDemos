import 'package:flutter/material.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JWT Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'JWT Generator'),
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
  String? _jwtToken;
  bool _isGenerating = false;

  // ES256 PEM 格式私钥
  final String ecPrivateKeyPem = '''-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIFbXVgwj22kLU4KRXi3Vto/Dj3+/YCiV5Lm5s9luWEgaoAoGCCqGSM49
AwEHoUQDQgAEJgXlnyeYB+rTH4eqZjLR79DeNk4IO+K8pil8QRmZd+w3S6KxL7HO
1nbDI7hSqhEwWpjPMQ+B4+eEV7x4KRUsFg==
-----END EC PRIVATE KEY-----''';

  Future<void> _generateJWT() async {
    setState(() {
      _isGenerating = true;
      _jwtToken = null;
    });

    try {
      // 创建 JWT
      final jwt = JWT({
        'sub': '1234567890',
        'name': 'John Doe',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'iss': 'flutter-app',
      });

      // 使用 ES256 算法签署 JWT
      final token = jwt.sign(
        ECPrivateKey(ecPrivateKeyPem),
        algorithm: JWTAlgorithm.ES256,
      );

      // 同时打印到控制台
      developer.log('Generated JWT Token: $token', name: 'JWT_Demo');

      setState(() {
        _jwtToken = token;
      });
    } catch (e) {
      developer.log('JWT Generation Error: $e', name: 'JWT_Demo', level: 1000);
      setState(() {
        _jwtToken = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateJWT,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('生成 JWT Token'),
            ),
            const SizedBox(height: 24),
            if (_jwtToken != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        _jwtToken!,
                        style: const TextStyle(
                            fontFamily: 'Monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
