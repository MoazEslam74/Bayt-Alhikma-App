import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. استدعاء الحزمة الخاصة بمتغيرات البيئة

class BookPriceService {
  // 2. استبدال القيم الثابتة بجلب القيم من ملف .env
  // استخدمنا "get" عشان نقرأ القيمة وقت استدعائها، وحطينا "" كقيمة افتراضية لو المفتاح مش موجود
  static String get apiKey => dotenv.env['GOOGLE_SEARCH_API_KEY'] ?? "";
  static String get searchEngineId => dotenv.env['SEARCH_ENGINE_ID'] ?? "";

  static Future<List<Map<String, dynamic>>> searchHardCopy(String title) async {
    final query = Uri.encodeComponent("buy $title hardcopy book price");
    print("🔑 API Key is: '$apiKey'");
    print("🔑 Search Engine ID is: '$searchEngineId'");
    // الـ URL هيتم بناؤه دلوقتي باستخدام المفاتيح المخفية والمستدعاة بأمان
    final url = Uri.parse(
      "https://www.googleapis.com/customsearch/v1?q=$query&key=$apiKey&cx=$searchEngineId&gl=eg&hl=ar",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) {
          String? imageUrl;
          if (item['pagemap'] != null &&
              item['pagemap']['cse_image'] != null &&
              (item['pagemap']['cse_image'] as List).isNotEmpty) {
            imageUrl = item['pagemap']['cse_image'][0]['src'];
          }

          String snippet = item['snippet'] ?? "";
          String price = _extractPrice(snippet);

          return {
            "title": item['title'] ?? "No Title",
            "link": item['link'] ?? "",
            "store": item['displayLink'] ?? "Unknown Store",
            "price": price,
            "thumbnail": imageUrl,
            "snippet": snippet,
          };
        }).toList();
      } else {
        print("API Error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

  static String _extractPrice(String text) {
    RegExp regExp = RegExp(
      r'(EGP|LE)\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)|\b(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s?(EGP|LE)\b',
      caseSensitive: false,
    );

    Match? match = regExp.firstMatch(text);
    if (match != null) {
      return match.group(0) ?? "Check Link";
    }
    return "Check Link";
  }
}