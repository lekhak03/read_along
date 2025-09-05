import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  final OCRService _ocrService = OCRService();

  List<Chat> _chats = [];
  Chat? _currentChat;
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  bool _isTemporaryMode = false;
  String? _extractedText;

  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isTemporaryMode => _isTemporaryMode;
  String? get extractedText => _extractedText;

  void setTemporaryMode(bool isTemporary) {
    _isTemporaryMode = isTemporary;
    notifyListeners();
  }

  Future<void> loadChats() async {
    try {
      _chats = await _databaseService.getAllChats();
      notifyListeners();
    } catch (e) {
      print('Error loading chats: $e');
    }
  }

  Future<void> createNewChat({String? title}) async {
    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    // Auto-increment chat title
    int chatNumber = _chats.length + 1;
    final autoTitle = title ?? 'New Chat $chatNumber';
    final chat = Chat(
      id: chatId,
      title: autoTitle,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      isTemporary: _isTemporaryMode,
    );

    _currentChat = chat;
    _currentMessages = [];
    // _extractedText = null;

    // Always save chat to DB unless in incognito mode
    if (!_isTemporaryMode) {
      await _databaseService.insertChat(chat);
      await loadChats();
    }
    notifyListeners();
  }

  Future<void> renameCurrentChat(String newTitle) async {
  if (_currentChat == null || _isTemporaryMode) return;
  await _databaseService.updateChatTitle(_currentChat!.id, newTitle);
  _currentChat = _currentChat!.copyWith(title: newTitle, lastModified: DateTime.now());
  await loadChats(); // This will update the recent chats sidebar
  notifyListeners();
  }

  Future<void> selectChat(String chatId) async {
    try {
      _currentChat = _chats.firstWhere((chat) => chat.id == chatId);
      _currentMessages = await _databaseService.getMessagesForChat(chatId);
      notifyListeners();
    } catch (e) {
      print('Error selecting chat: $e');
    }
  }

  Future<void> sendMessage(String content, {File? file}) async {
    if (_currentChat == null) {
      await createNewChat();
    }

    if (file != null) {
      await processFileWithOCR(file); // This sets _extractedText
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      chatId: _currentChat!.id,
    );

    _currentMessages.add(userMessage);
    notifyListeners();

    if (!_isTemporaryMode) {
      await _databaseService.insertMessage(userMessage);
    }

    await _getAIResponse();
  }

  Future<void> _getAIResponse() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare conversation history
      final messages = _currentMessages
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();
      print("Extracted text is:\n $_extractedText");
      final response = await _geminiService.getChatResponse(
        messages: messages,
        extractedText: _extractedText,
      );

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        chatId: _currentChat!.id,
      );

      _currentMessages.add(aiMessage);

      if (!_isTemporaryMode) {
        await _databaseService.insertMessage(aiMessage);
        
        // Update chat title if it's the first message
        if (_currentMessages.length == 2 && _currentChat!.title == 'New Chat') {
          final newTitle = _generateChatTitle(_currentMessages.first.content);
          await _databaseService.updateChatTitle(_currentChat!.id, newTitle);
          _currentChat = _currentChat!.copyWith(title: newTitle);
          await loadChats();
        }
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: $e',
        isUser: false,
        timestamp: DateTime.now(),
        chatId: _currentChat!.id,
      );
      _currentMessages.add(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> processFileWithOCR(File file) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use the public extractText method from OCRService
      _extractedText = await _ocrService.extractText(file);

      // Debug logging for extracted text
      print('=== OCR EXTRACTED TEXT ===');
      print('Text length: ${_extractedText?.length ?? 0}');
      print('Text preview: ${_extractedText?.substring(0, _extractedText!.length > 200 ? 200 : _extractedText!.length)}');
      print('=== END OCR TEXT ===');

      if (_extractedText != null && _extractedText!.isNotEmpty) {
        await createNewChat(title: 'Page Analysis');

        final textMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'I\'ve extracted the following text from your file:\n\n"${_extractedText}"\n\nWhat would you like to know about it?',
          isUser: false,
          timestamp: DateTime.now(),
          chatId: _currentChat!.id,
        );

        _currentMessages.add(textMessage);

        if (!_isTemporaryMode) {
          await _databaseService.insertMessage(textMessage);
        }
      } else {
        final noTextMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'I couldn\'t find any readable text in this file. Please try:\n\n• Using a clearer image or PDF\n• Ensuring good lighting\n• Making sure text is not too small\n• Checking that the file contains text',
          isUser: false,
          timestamp: DateTime.now(),
          chatId: _currentChat?.id ?? 'temp',
        );
        _currentMessages.add(noTextMessage);
      }
    } catch (e) {
      print('OCR Error: $e');
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I couldn\'t extract text from the file: $e',
        isUser: false,
        timestamp: DateTime.now(),
        chatId: _currentChat?.id ?? 'temp',
      );
      _currentMessages.add(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> processImageWithOCR(File imageFile) async {
    await processFileWithOCR(imageFile);
  }

  String _generateChatTitle(String firstMessage) {
    // Generate a short title from the first message
    final words = firstMessage.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _databaseService.deleteChat(chatId);
      _chats.removeWhere((chat) => chat.id == chatId);
      
      if (_currentChat?.id == chatId) {
        _currentChat = null;
        _currentMessages = [];
        _extractedText = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  void clearCurrentChat() {
    _currentChat = null;
    _currentMessages = [];
    _extractedText = null;
    notifyListeners();
  }
}
