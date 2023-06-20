import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";
import "ffi.dart" if (dart.library.html) "ffi_web.dart";

void main() {
  runApp(const MyApp());
}

/// The root of the application.
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

/// The home page of the application.
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Futures to retrieve the current username and possible escalation methods.
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
                final style = Theme.of(context).textTheme.headlineSmall;
                if (snap.error != null) {
                  debugPrint(snap.error.toString());
                  _showErrorBanner(snap.error.toString());
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
            const SizedBox(height: 30), // padding
            _output.isEmpty // shows nothing if there's no output, to prevent the space from being taken
                ? const SizedBox(height: 0)
                : SizedBox(
                    height: 200,
                    child: Scrollbar(
                        thumbVisibility: true,
                        controller: scrollController,
                        // wraps the output in a scrollable view and makes it monospace & selectable
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: SelectableText(
                            _output,
                            style: const TextStyle(
                              fontFamily: 'CodeNewRoman',
                            ),
                          ),
                        )))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_output.isNotEmpty) {
            // clears the output if there's already output
            setState(() {
              _output = "";
            });
            return;
          }

          // just authenticate if using polkit or no escalation method
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

          // otherwise, show the authentication dialog
          _showAuthenticationDialog();
        },
        backgroundColor: Colors.blue,
        // shows a play button if there's no output, otherwise shows a clear button
        icon: _output.isEmpty
            ? const Icon(Icons.play_arrow_rounded)
            : const Icon(Icons.clear_rounded),
        label: _output.isEmpty
            ? const Text("Run ls -la /root")
            : const Text("Clear output"),
      ),
    );
  }

  /// Shows the authentication dialog and handles the result.
  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AuthenticationDialog(
          escalationMethod:
              _selectedMethod!, // _selectedMethod defaults to EscalationMethod.None
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

  /// Shows a banner with an error message.
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
          // shows buttons to switch escalation methods or to turn off escalation
          Row(
            children: <Widget>[
              // only shows the lock icon if there's more than one escalation method
              _escalationMethods.length == 1
                  ? const SizedBox(width: 0)
                  : const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 5), // padding

              // shows a button for every other escalation method apart from the current one
              for (var item in _escalationMethods)
                if (item != _selectedMethod)
                  TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedMethod = item;
                        });
                        ScaffoldMessenger.of(context)
                            .hideCurrentMaterialBanner();
                      },
                      child: Text("Use ${item.name.toLowerCase()}")),
              const SizedBox(width: 30), // padding
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

    // hides the banner after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }
}

/// A dialog that asks for the user's username and password.
///
/// This dialog is used to authenticate the user when using sudo or su.
/// The username is not required when using sudo, so it is already filled in.
class AuthenticationDialog extends StatefulWidget {
  final ValueChanged<String>
      onSubmitted; // called when the user submits the form
  final ValueChanged<String> onException; // called when an exception occurs
  final EscalationMethod escalationMethod; // the escalation method to use
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

    // username defaults to "root" if using su
    _username = widget.escalationMethod == EscalationMethod.Sudo
        ? widget.username
        : "root";
    _password = "";
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        // handles Enter and Escape key presses to submit or cancel the dialog respectively
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (v) {
          if (v.logicalKey == LogicalKeyboardKey.enter) {
            _fireAuthentication();
          } else if (v.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: AlertDialog(
          // shows a progress indicator during the authentication process
          title: _isAuthenticating
              ? const LinearProgressIndicator(value: null, color: Colors.blue)
              : widget.escalationMethod == EscalationMethod.Sudo
                  ? const Text('Authenticate using sudo')
                  : const Text('Authenticate using su'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          icon: const Icon(Icons.admin_panel_settings_rounded),
          actionsPadding: const EdgeInsets.all(10.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                // username is not required when using sudo
                readOnly: widget.escalationMethod == EscalationMethod.Sudo,
                controller: TextEditingController(text: _username),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
                onChanged: (value) {
                  _username = value;
                },
              ),
              const SizedBox(height: 10), // padding
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                onChanged: (value) {
                  _password = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            IgnorePointer( // disables the "Approve" button while authenticating
              ignoring: _isAuthenticating,
              child: TextButton(
                onPressed: () async {
                  await _fireAuthentication();
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      _isAuthenticating ? Colors.grey : Colors.blue,
                ),
                child: const Text('Approve'),
              ),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ));
  }

  /// Attempts to authenticate the action and closes the dialog.
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
