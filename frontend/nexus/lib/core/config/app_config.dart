import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api/v1';

  static Future<void> loadEnv() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }
}
