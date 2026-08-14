import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
    this.otherUserPhoto = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _messages = [];
  final bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadMessages();
  }

  void _initializeSocket() {
    // TODO: Initialize socket connection with backend
    // _socket = IO.io('YOUR_BACKEND_URL', <String, dynamic>{
    //   'transports': ['websocket'],
    //   'autoConnect': false,
    // });
    
    // _socket.auth = {'userId': 'CURRENT_USER_ID'};
    // _socket.connect();
    
    // _socket.onConnect((_) {
    //   setState(() => _isConnected = true);
    //   _socket.emit('joinMatch', {'matchId': widget.matchId});
    // });
    
    // _socket.on('newMessage', (data) {
    //   setState(() {
    //     _messages.add(data);
    //   });
    //   _scrollToBottom();
    // });
    
    // _socket.on('userTyping', (data) {
    //   if (data['userId'] != 'CURRENT_USER_ID') {
    //     setState(() => _isTyping = data['isTyping']);
    //   }
    // });
  }

  Future<void> _loadMessages() async {
    // TODO: Load messages from API
    setState(() {
      _messages = _getMockMessages();
    });
  }

  List<Map<String, dynamic>> _getMockMessages() {
    return [
      {
        'id': '1',
        'senderId': 'other',
        'content': '¡Hola! Me parece que tenemos un 92% de compatibilidad',
        'messageType': 'text',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
        'isRead': true,
      },
      {
        'id': '2',
        'senderId': 'me',
        'content': '¡Sí! Es genial. Me encanta que ambos teletrabajemos',
        'messageType': 'text',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
        'isRead': true,
      },
    ];
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'me',
      'content': text,
      'messageType': 'text',
      'createdAt': DateTime.now(),
      'isRead': false,
    };

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });

    _scrollToBottom();

    // TODO: Send via socket
    // _socket.emit('sendMessage', {
    //   'matchId': widget.matchId,
    //   'messageType': 'text',
    //   'content': text,
    // });
  }

  Future<void> _sendImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (image != null) {
      // TODO: Upload image and send via socket
      final message = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': 'me',
        'mediaUrl': image.path,
        'messageType': 'image',
        'createdAt': DateTime.now(),
        'isRead': false,
      };

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();
    }
  }

  Future<void> _sendLocation() async {
    // TODO: Implement location sharing
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhoto.isNotEmpty
                  ? NetworkImage(widget.otherUserPhoto)
                  : null,
              child: widget.otherUserPhoto.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16),
                ),
                if (_isTyping)
                  const Text(
                    'Escribiendo...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _sendLocation,
            tooltip: 'Enviar ubicación',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Inicia la conversación',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == 'me';
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _sendImage,
            color: const Color(0xFF4A90E2),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
}
