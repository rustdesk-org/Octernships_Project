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
  late Future<List<String>> _futureFiles;

  @override
  void initState() {
    super.initState();
    _futureFiles = _fetchFiles();
  }

  Future<List<String>> _fetchFiles([String? password]) async {
    try {
      // 尝试无密码提权
      return await api.lsRootWithPolkit();
    } catch (_) {
      // 提权失败，请求密码并尝试用密码提权
      password = await _requestPassword(context);
      return await api.lsRootWithSudo(password: password);
    }
  }

  Future<String> _requestPassword(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Permission denied'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: "Enter your password"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
            ),
          ],
        );
      },
    ).then((value) => Future<String>.value(value as String));
  }

  void _refreshFiles() {
    setState(() {
      _futureFiles = _fetchFiles();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      // 通过FutureBuilder来构建列表
      body: FutureBuilder<List<String>>(
        future: _futureFiles,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            // 等待提权或加载，显示一个旋转的加载条
            return Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            // 如果文件获取错误，显示错误信息
            return Center(child: Text("Error: ${snap.error}"));
          } else {
            // 文件获取成功，加载文件列表
            List<String>? rootList = snap.data;
            // 使用ListView.builder来打印rootList内所有的成员
            return ListView.builder(
              itemCount: rootList!.length,
              itemBuilder: (context, index) {
                // 以Card的形式返回条目
                return Card(
                  elevation: 4.0,
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      rootList[index],
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      // 在右下角添加一个按钮，点击后刷新列表
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshFiles,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
