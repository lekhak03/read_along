import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'study_assistant.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastModified TEXT NOT NULL,
        isTemporary INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        content TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (chatId) REFERENCES chats (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertChat(Chat chat) async {
    final db = await database;
    await db.insert(
      'chats',
      {
        'id': chat.id,
        'title': chat.title,
        'createdAt': chat.createdAt.toIso8601String(),
        'lastModified': chat.lastModified.toIso8601String(),
        'isTemporary': chat.isTemporary ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'chatId': message.chatId,
        'content': message.content,
        'isUser': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Chat>> getAllChats() async {
    final db = await database;
    final result = await db.query(
      'chats',
      where: 'isTemporary = ?',
      whereArgs: [0],
      orderBy: 'lastModified DESC',
    );

    return result.map((map) => Chat.fromJson({
      'id': map['id'],
      'title': map['title'],
      'createdAt': map['createdAt'],
      'lastModified': map['lastModified'],
      'isTemporary': (map['isTemporary'] as int) == 1,
      'messageIds': [],
    })).toList();
  }

  Future<List<ChatMessage>> getMessagesForChat(String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => ChatMessage.fromJson({
      'id': map['id'],
      'content': map['content'],
      'isUser': (map['isUser'] as int) == 1,
      'timestamp': map['timestamp'],
      'chatId': map['chatId'],
    })).toList();
  }

  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> updateChatTitle(String chatId, String title) async {
    final db = await database;
    await db.update(
      'chats',
      {'title': title, 'lastModified': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }
}
