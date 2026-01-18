import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:3000' : 'http://10.0.2.2:3000';
}
