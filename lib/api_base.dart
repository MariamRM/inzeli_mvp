import 'package:flutter/foundation.dart' show kIsWeb;

const String apiBase = kIsWeb
    ? String.fromEnvironment('API_BASE_WEB', defaultValue: 'http://127.0.0.1:3000/api') // للويب
    : String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000/api'); // للأندرويد
//lib/widgets/api_base.dart