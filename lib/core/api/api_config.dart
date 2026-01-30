import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:3000' : 'http://192.168.8.197:3000';
}
