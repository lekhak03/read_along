import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/camera_service.dart';
import 'chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _showSidebar = false;
  final CameraService _cameraService = CameraService();
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChats();
      _animationController?.forward();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  // Removed unused animations
  // _fadeAnimation = Tween<double>(
  //   begin: 0.0,
  //   end: 1.0,
  // ).animate(CurvedAnimation(
  //   parent: _animationController!,
  //   curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
  // ));
  // _slideAnimation = Tween<Offset>(
  //   begin: const Offset(0, 0.3),
  //   end: Offset.zero,
  // ).animate(CurvedAnimation(
  //   parent: _animationController!,
  //   curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
  // ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF181A20),
              Color(0xFF23262F),
              Color(0xFF23262F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Temporary mode banner
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isTemporaryMode) {
                    return Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.eye_slash_fill, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Temporary mode is ON. Chats won't be saved.",
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLargeActionButton(
                      icon: CupertinoIcons.camera,
                      label: 'Take a Photo',
                      onTap: _captureImage,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF23262F), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLargeActionButton(
                      icon: CupertinoIcons.photo,
                      label: 'Choose from Library',
                      onTap: _pickFromGallery,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF23262F), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              ),
              // Recent chats menu button (top left)
              Positioned(
                top: 8,
                left: 8,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 32,
                  child: Icon(CupertinoIcons.sidebar_left, size: 24, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _showSidebar = true;
                    });
                  },
                ),
              ),
              // Animated sidebar overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                top: 0,
                left: _showSidebar ? 0 : -MediaQuery.of(context).size.width * 0.7,
                bottom: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: _showSidebar
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: _buildRecentChatsSidebar(
                            onClose: () {
                              setState(() {
                                _showSidebar = false;
                              });
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // Incognito toggle button (top right)
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      child: Icon(
                        chatProvider.isTemporaryMode
                            ? CupertinoIcons.eye_slash_fill
                            : CupertinoIcons.eye_fill,
                        size: 26,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        chatProvider.setTemporaryMode(!chatProvider.isTemporaryMode);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRecentChatsSidebar({VoidCallback? onClose}) {
    return Material(
      color: const Color(0xFF23262F),
      borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Chats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: Icon(CupertinoIcons.xmark, size: 20, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.chats.isEmpty) {
                    return Center(child: Text('No recent chats', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: chatProvider.chats.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final chat = chatProvider.chats[index];
                      return ListTile(
                        tileColor: Colors.transparent,
                        leading: Icon(CupertinoIcons.chat_bubble_2, size: 20, color: Colors.blueAccent),
                        title: Text(chat.title, style: TextStyle(fontSize: 16, color: Colors.white)),
                        subtitle: Text('Last modified: ${_formatDate(chat.lastModified)}', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 24,
                          child: Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 20),
                          onPressed: () => _confirmDeleteChat(chat.id),
                        ),
                        onTap: () {
                          if (onClose != null) onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(chatId: chat.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoButton(
                color: CupertinoColors.systemRed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.delete_solid, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Delete All Chats', style: TextStyle(color: Colors.white)),
                  ],
                ),
                onPressed: () {
                  context.read<ChatProvider>().chats.forEach((chat) {
                    context.read<ChatProvider>().deleteChat(chat.id);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLargeActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        height: 80,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Color(0xFF3B82F6), size: 28),
            ),
            const SizedBox(width: 24),
            Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222B45),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed unused _buildRecentChatsSection

  Future<void> _captureImage() async {
    try {
      final imageFile = await _cameraService.captureImage();
      if (imageFile != null) {
        _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imageFile = await _cameraService.pickImageFromGallery();
      if (imageFile != null) {
        _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _processImage(File imageFile) {
    // Navigate to chat screen and process the image
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(imageFile: imageFile),
      ),
    );
  }


  void _confirmDeleteChat(String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().deleteChat(chatId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
