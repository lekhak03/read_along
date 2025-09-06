# Study Assistant App

A ChatGPT-style study assistant Flutter app that helps students capture book pages, extract text using OCR, and ask questions about the content.

## 📽️ Demo

Here’s a quick demo of the project in action:

![Project Demo](./demonstration.gif)

## Features

### 🏠 Homepage
- **Ask a Question** - Start a chat conversation
- **Capture Page (Camera)** - Take a photo and extract text using OCR
- **Select from Gallery** - Choose an existing image for text extraction
- **Temporary Mode Toggle** - Choose whether to save chats or use incognito mode

### 📱 Core Functionality
- **Camera Integration** - Capture book pages with camera or select from gallery
- **OCR Text Extraction** - Extract text from images using Google ML Kit
- **AI Chat Interface** - ChatGPT-style conversation UI powered by OpenAI API
- **Chat Persistence** - Save conversations with SQLite database
- **Temporary Mode** - Incognito-style chats that aren't saved

### 💬 Chat Features
- Real-time messaging interface similar to ChatGPT
- Message history and persistence
- Copy messages to clipboard
- Delete individual chats
- Auto-generated chat titles

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- OpenAI API key

### 2. Installation

1. **Clone and setup:**
   ```bash
   cd /path/to/your/project
   flutter pub get
   ```

2. **Configure Gemini API:**
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your actual Gemini API key:
   ```dart
   static const String geminiApiKey = 'your-actual-gemini-api-key-here';
   ```

3. **Configure permissions (already done):**
   - Android: Camera, Internet, Storage permissions added to AndroidManifest.xml
   - iOS: Camera and Photo Library usage descriptions added to Info.plist

### 3. Getting a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign up or log in to your Google account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and add it to the config file

### 4. Run the App

```bash
flutter run
```

For specific platforms:
```bash
flutter run -d android    # Android
flutter run -d ios        # iOS
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── chat.dart            # Chat model
│   └── chat_message.dart    # Message model
├── providers/                # State management
│   └── chat_provider.dart   # Main chat state provider
├── screens/                  # UI screens
│   ├── home_page.dart       # Main homepage
│   └── chat_screen.dart     # Chat interface
├── services/                 # External services
│   ├── camera_service.dart  # Camera/gallery functionality
│   ├── database_service.dart # SQLite database operations
│   ├── ocr_service.dart     # Text extraction from images
│   └── gemini_service.dart  # Gemini API integration
└── widgets/                  # Reusable UI components
    └── message_bubble.dart   # Chat message bubble widget
```

## Key Dependencies

- **`camera`** - Camera functionality
- **`image_picker`** - Image selection from gallery
- **`google_ml_kit`** - OCR text recognition
- **`http`** - HTTP requests for Gemini API
- **`sqflite`** - Local SQLite database
- **`provider`** - State management
- **`shared_preferences`** - Simple data persistence
- **`permission_handler`** - Runtime permissions
- **`flutter_spinkit`** - Loading animations

## Usage

### 1. Basic Chat
1. Open the app
2. Tap "Ask a Question"
3. Type your question and send
4. Receive AI-powered responses

### 2. Image-based Learning
1. Tap "Capture Page" or "Select from Gallery"
2. Take a photo of a book page or select an existing image
3. The app will extract text using OCR
4. Ask questions about the extracted content
5. Get contextual answers based on the text

### 3. Managing Chats
- **View chat history**: Tap "Recent Chats" on homepage
- **Delete chats**: Use the options menu in chat or from chat list
- **Temporary mode**: Toggle on homepage to prevent saving chats

## Troubleshooting

### Common Issues

1. **Camera not working:**
   - Ensure camera permissions are granted
   - Check if device has a camera
   - Restart the app

2. **OCR not extracting text:**
   - Ensure image is clear and well-lit
   - Text should be clearly visible
   - Try capturing the image again

3. **OpenAI API errors:**
   - Verify API key is correct and active
   - Check internet connection
   - Ensure you have API credits available

4. **Database issues:**
   - Clear app data and restart
   - Check device storage space

## Contributing

This is a study assistant app designed to help students learn more effectively by combining OCR technology with AI-powered conversations.

## License

This project is for educational purposes. Please ensure you comply with OpenAI's usage policies when using their API.
