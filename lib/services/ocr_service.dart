// To do:
// modularize ocr and gemini
// function to export extracted text to gemini service.

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';


class OCRService {
  
  /// Sends a file to the OCR API and returns the extracted text.
  Future<String> extractText(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getOcrApiUrl(isAndroid: true)),
      );
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        final String text = json['text'] ?? '';
        return text;
      } else {
        throw Exception('OCR API failed with status ${response.statusCode}: $responseData');
      }
    } catch (e) {
      throw Exception('Failed to send file to OCR API: $e');
    }
  }
}