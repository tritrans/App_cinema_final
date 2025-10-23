import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAEHGyVyJcS2bYiwMXu8E4uHRRWRu5Yfyk';

  static Future<String?> getMovieSummary(String movieTitle) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
      final prompt = 'Tóm tắt nội dung phim "$movieTitle" trong khoảng 50 từ.';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Lỗi khi gọi Gemini API: $e');
      return null;
    }
  }
}
