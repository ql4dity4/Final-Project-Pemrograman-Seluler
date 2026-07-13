import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _historyKey = 'reconx_history';
  static const String _bookmarksKey = 'reconx_bookmarks';

  // ============= HISTORY =============
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> addHistory(String domain, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.insert(0, {
      'domain': domain,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 entries
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    await prefs.setString(_historyKey, jsonEncode(history));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<void> removeHistoryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await prefs.setString(_historyKey, jsonEncode(history));
    }
  }

  // ============= BOOKMARKS =============
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_bookmarksKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> addBookmark(String domain, {String note = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    // Check if already bookmarked
    if (bookmarks.any((b) => b['domain'] == domain)) return;

    bookmarks.insert(0, {
      'domain': domain,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_bookmarksKey, jsonEncode(bookmarks));
  }

  static Future<void> removeBookmark(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b['domain'] == domain);
    await prefs.setString(_bookmarksKey, jsonEncode(bookmarks));
  }

  static Future<bool> isBookmarked(String domain) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b['domain'] == domain);
  }

  static Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarksKey);
  }
}
