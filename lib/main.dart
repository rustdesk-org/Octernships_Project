import "package:flutter/material.dart";
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
      home:
          const MyHomePage(title: "Elevate priviledge to run a Linux command"),
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

  EscalationMethod? _selectedMethod = EscalationMethod.Su;
  String _username = "";
  String _output = "";

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
                final style = Theme.of(context).textTheme.headlineSmall;
                if (snap.error != null) {
                  debugPrint(snap.error.toString());
                }

                // Guard return here, the data is not ready yet.
                final data = snap.data;
                if (data == null) return const CircularProgressIndicator();

                // Retrieve the data
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
                  default:
                    text = "Unknown";
                    break;
                }

                return Text(text, style: style);
              },
            ),
            SelectableText(_output)
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

          setState(() {
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
                    _showErrorMessage(message);
                  },
                );
              },
            );
          });
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: <Widget>[
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.red,
        actions: <Widget>[
          Row(
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Dismiss'),
                onPressed: () {
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
    return AlertDialog(
      title: _isAuthenticating
          ? const LinearProgressIndicator(value: null, color: Colors.blue)
          : widget.escalationMethod == EscalationMethod.Sudo
              ? const Text('Authenticate using sudo')
              : const Text('Authenticate using su'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            readOnly: widget.escalationMethod == EscalationMethod.Sudo,
            controller: TextEditingController(text: _username),
            decoration: const InputDecoration(
              labelText: "Username",
            ),
          ),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
            ),
            onChanged: (value) {
              _password = value;
            },
          ),
        ],
      ),
      actions: <Widget>[
        IgnorePointer(
            ignoring: _isAuthenticating,
            child: TextButton(
              onPressed: () async {
                _fireAuthentication();
              },
              style: TextButton.styleFrom(
                foregroundColor: _isAuthenticating ? Colors.grey : Colors.blue,
              ),
              child: const Text("Approve"),
            )),
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _fireAuthentication() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      var output = await api.getDirectoryListing(
          method: widget.escalationMethod,
          username: _username,
          password: _password);

      widget.onSubmitted(output);
    } on FfiException catch (exception) {
      widget.onException(exception.message);
    }
  }
}
