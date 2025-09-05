import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const int _maxTokens = 4000;

  Future<String> getChatResponse({
    required List<Map<String, String>> messages,
    String? extractedText,
  }) async {
    try {
      // Prepare the conversation context
      String conversationContext = '';
      
      // Add extracted text context if available
      if (extractedText != null && extractedText.isNotEmpty) {
        conversationContext += 'Context from book page: "$extractedText"\n\n';
        print("Conversation Context in GEMINI: $conversationContext\n");
      }
      
      // Add conversation history
      conversationContext += 'Conversation history:\n';
      for (final message in messages) {
        final role = message['role'] == 'user' ? 'User' : 'Assistant';
        conversationContext += '$role: ${message['content']}\n';
      }
      
      // Add the current user message
      final lastMessage = messages.last;
      conversationContext += '\nUser: ${lastMessage['content']}\n\n';
      conversationContext += 'Assistant: ';

      // Truncate if context is too long
      final truncatedContext = _truncateContext(conversationContext);

      final response = await http.post(
        Uri.parse('${ApiConfig.getGeminiApiUrl()}?key=${ApiConfig.getGeminiApiKey()}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': truncatedContext,
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': _maxTokens,
            'temperature': 0.7,
            'topP': 0.8,
            'topK': 40,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('candidates') && 
            data['candidates'] is List && 
            data['candidates'].isNotEmpty) {
          
          final candidate = data['candidates'][0];
          if (candidate.containsKey('content') && 
              candidate['content'].containsKey('parts') && 
              candidate['content']['parts'] is List && 
              candidate['content']['parts'].isNotEmpty) {
            
            final part = candidate['content']['parts'][0];
            if (part.containsKey('text')) {
              return part['text'].toString().trim();
            }
          }
        }
        
        throw Exception('Unexpected response format from Gemini API');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error']?['message'] ?? 'Bad request'}');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Gemini API key.');
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Error communicating with AI: $e');
    }
  }

  String _truncateContext(String context) {
    // Estimate token count (rough approximation: 1 token ≈ 4 characters)
    final maxChars = _maxTokens * 4;
    
    if (context.length <= maxChars) {
      return context;
    }
    
    // Truncate from the beginning, keeping the most recent conversation
    return context.substring(context.length - maxChars);
  }
}
