import 'package:dio/dio.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAMQlv0cmMWv1Q7FpEwb3vfbPyn_bEDbFU';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final Dio _dio = Dio();

  Future<String> chat(String message, {String? context}) async {
    try {
      // Build system prompt for mental health support
      final systemPrompt = '''
Bạn là Trợ Lý Tâm An - một trợ lý AI hỗ trợ sức khỏe tinh thần độc quyền của ứng dụng Tâm An.

VAI TRÒ:
- Lắng nghe và thấu hiểu cảm xúc người dùng
- Đưa ra lời khuyên tích cực, ấm áp
- Gợi ý các chiến lược xử lý cảm xúc
- Khuyến khích viết nhật ký và tự chăm sóc

NGUYÊN TẮC:
- Luôn empathetic và không phán xét
- Câu trả lời ngắn gọn, dễ hiểu (2-4 câu)
- Sử dụng tiếng Việt tự nhiên, thân thiện
- Không thay thế chuyên gia tâm lý
- Nếu phát hiện dấu hiệu nghiêm trọng, khuyên tìm chuyên gia

TRÁNH:
- Đưa ra chẩn đoán y khoa
- Câu trả lời quá dài dòng
- Ngôn ngữ học thuật phức tạp
- Lời khuyên không an toàn
''';

      final fullPrompt = context != null 
          ? '$systemPrompt\n\nNGỮ CẢNH: $context\n\nNGƯỜI DÙNG: $message'
          : '$systemPrompt\n\nNGƯỜI DÙNG: $message';

      final response = await _dio.post(
        '$_baseUrl/gemini-flash-latest:generateContent?key=$_apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        },
      );

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Xin lỗi, tôi không thể trả lời lúc này. Bạn có thể thử lại không?';
    } on DioException catch (e) {
      print('AI Service DioException:');
      print('Status Code: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('Message: ${e.message}');
      
      if (e.response?.statusCode == 400) {
        return 'API key không hợp lệ hoặc đã hết hạn. Vui lòng kiểm tra lại API key.';
      } else if (e.response?.statusCode == 403) {
        return 'API key bị từ chối. Vui lòng tạo API key mới tại https://aistudio.google.com/app/apikey';
      }
      return 'Đã có lỗi xảy ra. Vui lòng kiểm tra kết nối internet và thử lại.';
    } catch (e) {
      print('AI Service Error: $e');
      return 'Đã có lỗi xảy ra. Vui lòng kiểm tra kết nối internet và thử lại.';
    }
  }

  Future<String> getGuidedQuestion(String emotion) async {
    final prompt = '''
Người dùng đang cảm thấy "$emotion". 
Hãy đưa ra 1 câu hỏi để giúp họ viết nhật ký sâu hơn về cảm xúc này.
Câu hỏi nên ngắn gọn, dễ trả lời, và giúp họ tự nhận thức.
''';

    try {
      final response = await _dio.post(
        '$_baseUrl/gemini-flash-latest:generateContent?key=$_apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Bạn muốn chia sẻ gì về cảm xúc này?';
    } catch (e) {
      return 'Điều gì khiến bạn cảm thấy $emotion?';
    }
  }

  Future<String> getCopingStrategy(String emotion) async {
    final prompt = '''
Người dùng đang cảm thấy "$emotion".
Đề xuất 1 chiến lược xử lý cảm xúc ngắn gọn (2-3 câu).
Chiến lược phải thực tế, dễ làm, và an toàn.
''';

    try {
      final response = await _dio.post(
        '$_baseUrl/gemini-flash-latest:generateContent?key=$_apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Hãy thử thở sâu và cho phép bản thân cảm nhận cảm xúc này.';
    } catch (e) {
      return 'Hãy thử viết ra cảm xúc của bạn, hoặc nói chuyện với người bạn tin tưởng.';
    }
  }

  Future<String> getDailyAffirmation() async {
    final prompt = '''
Tạo 1 câu khích lệ tích cực bằng tiếng Việt.
Câu khích lệ nên ngắn gọn, ấm áp, và truyền cảm hứng.
''';

    try {
      final response = await _dio.post(
        '$_baseUrl/gemini-flash-latest:generateContent?key=$_apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Bạn đang làm rất tốt. Hãy tin vào bản thân mình!';
    } catch (e) {
      return 'Mỗi ngày là một cơ hội mới. Bạn có thể làm được!';
    }
  }
}
