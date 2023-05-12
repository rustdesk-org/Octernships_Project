import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';

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
      home: const MyHomePage(title: 'Elevate priviledge to run a Linux command'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // 使用 FutureBuilder 显示异步任务的结果
        child: FutureBuilder<List<String>>(
          // 调用 api.ls() 方法获取文件列表
          future: api.ls(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // 显示加载指示器
            } else if (snap.hasError) {
              return Text("Error: ${snap.error}"); // 显示错误信息
            } else {
              // 处理返回的 List<String> 结果
              List<String>? rootList = snap.data;
              return ListView.builder(
                itemCount: rootList!.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(rootList[index]),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
