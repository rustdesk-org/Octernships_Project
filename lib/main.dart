import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

typedef RunLSCFunc = Int32 Function();
typedef RunLSDart = int Function();
typedef FreeStringCFunc = Void Function(Pointer<Utf8>);
typedef FreeStringDart = void Function(Pointer<Utf8>);

class RustLibrary {
  RustLibrary() {
    final DynamicLibrary dylib =
        DynamicLibrary.open('/absolute/path/to/libprivileged_ls.so');

    runLS = dylib.lookupFunction<RunLSCFunc, RunLSDart>('run_ls');

    freeString =
        dylib.lookupFunction<FreeStringCFunc, FreeStringDart>('free_string');
  }

  late final int Function() runLS;
  late final void Function(Pointer<Utf8>) freeString;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RustLibrary rust = RustLibrary();
  Pointer<Utf8>? output;

  @override
  void dispose() {
    rust.freeString(output!);
    super.dispose();
  }

  void runCommand() {
    final resultLength = rust.runLS();
    final outputPtr = malloc<Uint8>(resultLength);
    final outputString = outputPtr.cast<Utf8>();
    output = outputString;
    rust.runLS();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Elevated LS Command'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: runCommand,
                child: const Text('Run LS Command'),
              ),
              const SizedBox(height: 16),
              output != null
                  ? Text(
                      output!.toDartString(),
                      style: const TextStyle(fontSize: 16),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
