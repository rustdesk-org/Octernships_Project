import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_template/polkit_handler.dart';
import 'package:process_run/process_run.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Octernships Project',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home:
          const MyHomePage(title: 'Elevate priviledge to run a Linux command'),
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
  String output = '';
  var query = 'ls -la /root/';

  @override
  void initState() {
    super.initState();
    executeCommand();
  }

  Future<void> executeCommand() async {
    bool polkitAvailable = false;
    try {
      polkitAvailable = await executePolkitAction();
    } catch (e) {
      print('Error checking Polkit availability: $e');
    }

    if (polkitAvailable) {
      // Use Polkit for privilege elevation
      // ...
    } else {
      // Polkit is not available, use sudo or alternative method
      try {
        final commandOutput = await executePrivilegedCommand(query);
        setState(() {
          output = commandOutput;
        });
      } catch (e) {
        setState(() {
          output = 'Error executing privileged command: $e';
        });
      }
    }
  }

  Future<String> executePrivilegedCommand(String command) async {
    final result = await run('sudo $command');
    final processResult =
        result.first; // Get the first ProcessResult from the list

    if (processResult.exitCode == 0) {
      return processResult.stdout.toString();
    } else {
      throw Exception('Failed to execute privileged command');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // const Text(
              //   "Command:~ ls -la /root/",
              //   style: TextStyle(fontSize: 40.0),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "[root@localhost ~]# ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 60,
                    padding: const EdgeInsets.only(top: 4),
                    child: TextField(
                      onChanged: (val) {
                        query = val;
                      },
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ls -la /root/',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              executeCommand();
                            });
                          },
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.lightBlue.shade200,
                ),
                child: Text(
                  'Output: $output',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
