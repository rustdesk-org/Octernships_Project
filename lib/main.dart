import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";
import "ffi.dart" if (dart.library.html) "ffi_web.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Octernships Project",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: "Elevate privilege to run a Linux command"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<EscalationMethod>> method;
  late Future<String> username;

  late List<EscalationMethod> _escalationMethods;
  EscalationMethod? _selectedMethod;
  String _username = "";
  String _output = "";

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    method = api.determineEscalationMethods();
    username = api.getUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<dynamic>>(
              future: Future.wait([method, username]),
              builder: (context, snap) {
                final style = Theme.of(context).textTheme.headline6;
                if (snap.error != null) {
                  debugPrint(snap.error.toString());
                  _showErrorBanner(snap.error.toString());
                }
                final data = snap.data;
                if (data == null) return const CircularProgressIndicator();

                _username = data[1];
                _escalationMethods = data[0];

                _selectedMethod ??= _escalationMethods.first;

                String text;
                switch (_selectedMethod) {
                  case EscalationMethod.Sudo:
                    text = "Escalating with sudo...";
                    break;
                  case EscalationMethod.Polkit:
                    text = "Escalating with polkit...";
                    break;
                  case EscalationMethod.Su:
                    text = "Escalating with su...";
                    break;
                  case EscalationMethod.None:
                    text =
                        "Running as user '$_username'...".replaceAll("\n", "");
                    break;
                  default:
                    text = "Unknown";
                    break;
                }

                return Text(text, style: style);
              },
            ),
            const SizedBox(height: 30),
            _output.isEmpty
                ? const SizedBox(height: 0)
                : SizedBox(
                    height: 200,
                    child: Scrollbar(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: SelectableText(
                          _output,
                          style: const TextStyle(
                            fontFamily: 'CodeNewRoman',
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_output.isNotEmpty) {
            setState(() {
              _output = "";
            });
            return;
          }

          if (_selectedMethod == EscalationMethod.None ||
              _selectedMethod == EscalationMethod.Polkit) {
            try {
              var result =
                  await api.getDirectoryListing(method: _selectedMethod!);

              setState(() {
                _output = result;
              });
            } on FfiException catch (exception) {
              _showErrorBanner(exception.message);
            }
            return;
          }

          _showAuthenticationDialog();
        },
        backgroundColor: Colors.blue,
        icon: _output.isEmpty
            ? const Icon(Icons.play_arrow_rounded)
            : const Icon(Icons.clear_rounded),
        label: _output.isEmpty
            ? const Text("Run ls -la /root")
            : const Text("Clear output"),
      ),
    );
  }

  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AuthenticationDialog(
          escalationMethod: _selectedMethod!,
          username: _username,
          onSubmitted: (result) {
            setState(() {
              _output = result;
            });
            Navigator.of(context).pop();
          },
          onException: (message) {
            Navigator.of(context).pop();
            _showErrorBanner(message);
          },
        );
      },
    );
  }

  void _showErrorBanner(String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.red,
        actions: <Widget>[
          Row(
            children: <Widget>[
              if (_escalationMethods.length == 1)
                const SizedBox(width: 0)
              else
                const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 5),
              for (var item in _escalationMethods)
                if (item != _selectedMethod)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedMethod = item;
                      });
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                    },
                    child: Text("Use ${item.name.toLowerCase()}"),
                  ),
              const SizedBox(width: 30),
              const Icon(Icons.key_off_rounded, color: Colors.white),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Turn off escalation'),
                onPressed: () {
                  setState(() {
                    _selectedMethod = EscalationMethod.None;
                  });
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
              ),
            ],
          )
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }
}

class AuthenticationDialog extends StatefulWidget {
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onException;
  final EscalationMethod escalationMethod;
  final String username;

  const AuthenticationDialog({
    Key? key,
    required this.escalationMethod,
    required this.username,
    required this.onSubmitted,
    required this.onException,
  }) : super(key: key);

  @override
  State<AuthenticationDialog> createState() => _AuthenticationDialogState();
}

class _AuthenticationDialogState extends State<AuthenticationDialog> {
  late String _username;
  late String _password;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _username = widget.escalationMethod == EscalationMethod.Sudo
        ? widget.username
        : "root";
    _password = "";
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event.runtimeType.toString() == "RawKeyDownEvent") {
          if (event.logicalKey.keyLabel.toLowerCase() == "enter") {
            _submitForm();
          }
        }
      },
      child: AlertDialog(
        title: const Text("Authenticate"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text("You need to authenticate as ${_username}"),
              const SizedBox(height: 15),
              TextField(
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onException("Authentication canceled");
            },
          ),
          TextButton(
            child: const Text('Authenticate'),
            onPressed: _isAuthenticating ? null : _submitForm,
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isAuthenticating = true;
    });
    try {
      String result = await api.authenticate(
        method: widget.escalationMethod,
        username: _username,
        password: _password,
      );

      widget.onSubmitted(result);
    } on FfiException catch (exception) {
      widget.onException(exception.message);
    }

    setState(() {
      _isAuthenticating = false;
    });
  }
}
