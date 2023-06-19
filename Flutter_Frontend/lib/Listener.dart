// ignore_for_file: avoid_print, file_names

import 'package:http/http.dart' as http;

Future fetchRootDirectoryListing() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:3000'));
  final result = response.body;
  print(result);
  return result;
}