/// API configuration for OCR and Gemini endpoints.
/// Update the IP address and API key below to match your environment.

class ApiConfig {
  // OCR API URLs
  static const String ocrApiUrlEmulator = 'http://10.0.2.2:5500/ocr';
  static const String ocrApiUrlSimulator = 'http://localhost:5500/ocr';
  static const String ocrApiUrlLan = 'http://192.168.2.60:5500/ocr'; // Replace with your MacBook's LAN IP

  // Gemini API configuration
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String geminiApiKey = ''; // Replace with your Gemini API key

  /// Returns the correct OCR API URL based on platform
  static String getOcrApiUrl({required bool isAndroid, bool isPhysicalDevice = false}) {
    if (isPhysicalDevice) {
      return ocrApiUrlLan;
    }
    return isAndroid ? ocrApiUrlEmulator : ocrApiUrlSimulator;
  }

  /// Returns the Gemini API URL
  static String getGeminiApiUrl() => geminiApiUrl;

  /// Returns the Gemini API Key
  static String getGeminiApiKey() => geminiApiKey;
}