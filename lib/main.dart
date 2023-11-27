import 'package:flutter/material.dart';
import 'ffi.io.dart' if (dart.library.html) 'ffi.web.dart';
export 'ffi.io.dart' if (dart.library.html) 'ffi.web.dart' show api;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sudo Command Output - ls -la /root/'),
        ),
        body: const _MyAppContent(),
      ),
    );
  }
}

class _MyAppContent extends StatefulWidget {
  const _MyAppContent({Key? key}) : super(key: key);

  @override
  State<_MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<_MyAppContent> {
  String? exampleText;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _showPasswordDialog();
            },
            child: const Text('Execute sudo command'),
          ),
          const SizedBox(height: 16),
          Text(
            exampleText ?? 'No command executed yet.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog() async {
    final password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Sudo Password : '),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final password = _passwordController.text;
                Navigator.pop(context, password);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (password != null && password.isNotEmpty) {
      _callExampleFfiTwo(password);
    }
  }

  Future<void> _callExampleFfiTwo(String password) async {
    final receivedText = await api.passingComplexStructs(password: password);
    if (mounted) {
      setState(() {
        exampleText = receivedText;
      });
    }
  }
}
