import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static String _activeBaseUrl = '';

  static Future<void> init() async {
    final customUrl = await StorageService.getCustomApiUrl();
    if (customUrl != null && customUrl.isNotEmpty) {
      _activeBaseUrl = customUrl;
    } else {
      _activeBaseUrl = defaultBaseUrl;
    }
  }

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get baseUrl => _activeBaseUrl.isNotEmpty ? _activeBaseUrl : defaultBaseUrl;

  static void setBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  static Future<Map<String, dynamic>> dnsLookup(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/dns/$domain'))
        .timeout(const Duration(seconds: 20));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> whoisLookup(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/whois/$domain'))
        .timeout(const Duration(seconds: 20));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> subdomainFinder(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/subdomains/$domain'))
        .timeout(const Duration(seconds: 25));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> techDetection(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/tech/$domain'))
        .timeout(const Duration(seconds: 20));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> ipInfo(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/ip/$domain'))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> portInfo(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/ports/$domain'))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fullRecon(String domain) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/recon/$domain'))
        .timeout(const Duration(seconds: 45));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> identifyHash(String hash) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/hash/identify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'hash': hash}),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> generateHash(
      String text, String algorithm) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/hash/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'algorithm': algorithm}),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
