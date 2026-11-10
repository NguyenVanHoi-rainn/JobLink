import 'dart:io';

class ApiConstants {
  ApiConstants._();

  static const String _pcIp = '192.168.1.29';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$_pcIp:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}