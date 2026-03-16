import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = kIsWeb
      ? 'https://<api-service>.onrender.com'
      : 'https://true-root.onrender.com';
}