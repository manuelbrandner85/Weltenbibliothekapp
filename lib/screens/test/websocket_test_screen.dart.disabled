/// 🧪 WELTENBIBLIOTHEK - WEBSOCKET TEST WIDGET
/// Quick test screen to verify WebSocket connection

import 'package:flutter/material.dart';
import '../services/websocket_chat_service.dart';
import '../config/api_config.dart';

class WebSocketTestScreen extends StatefulWidget {
  const WebSocketTestScreen({Key? key}) : super(key: key);

  @override
  State<WebSocketTestScreen> createState() => _WebSocketTestScreenState();
}

class _WebSocketTestScreenState extends State<WebSocketTestScreen> {
  final WebSocketChatService _wsService = WebSocketChatService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  
  bool _isConnected = false;
  String _status = 'Disconnected';
  Color _statusColor = Colors.red;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to WebSocket messages
    _wsService.messageStream.listen((message) {
      setState(() {
        _messages.insert(0, message);
      });
    });
  }
  
  Future<void> _connect() async {
    setState(() {
      _status = 'Connecting...';
      _statusColor = Colors.orange;
    });
    
    try {
      final success = await _wsService.connect(
        room: 'test',
        realm: 'materie',
        userId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        username: 'TestUser',
      );
      
      setState(() {
        _isConnected = success;
        _status = success ? 'Connected ✅' : 'Failed ❌';
        _statusColor = success ? Colors.green : Colors.red;
      });
      
      if (success) {
        _showSnackBar('✅ WebSocket Connected!', Colors.green);
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = 'Error: $e';
        _statusColor = Colors.red;
      });
      _showSnackBar('❌ Connection failed: $e', Colors.red);
    }
  }
  
  Future<void> _disconnect() async {
    await _wsService.disconnect();
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
      _statusColor = Colors.red;
    });
    _showSnackBar('🔌 Disconnected', Colors.orange);
  }
  
  Future<void> _sendMessage() async {
    if (!_isConnected) {
      _showSnackBar('⚠️ Please connect first!', Colors.orange);
      return;
    }
    
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showSnackBar('⚠️ Message cannot be empty!', Colors.orange);
      return;
    }
    
    try {
      await _wsService.sendMessage(
        room: 'test',
        message: message,
        username: 'TestUser',
        realm: 'materie',
      );
      
      _messageController.clear();
      _showSnackBar('📤 Message sent!', Colors.blue);
    } catch (e) {
      _showSnackBar('❌ Send failed: $e', Colors.red);
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _wsService.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 WebSocket Test'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor, width: 2),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // WebSocket URL Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔗 WebSocket URL:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ApiConfig.websocketUrl}/ws',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Room: test | Realm: materie',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Connection Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : _connect,
                    icon: const Icon(Icons.power),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnect : null,
                    icon: const Icon(Icons.power_off),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect and send a test message!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final type = message['type'] ?? 'unknown';
                      final timestamp = DateTime.now().toString().substring(11, 19);
                      
                      Color cardColor;
                      IconData icon;
                      
                      switch (type) {
                        case 'new_message':
                        case 'chat_message':
                          cardColor = Colors.blue;
                          icon = Icons.message;
                          break;
                        case 'user_joined':
                          cardColor = Colors.green;
                          icon = Icons.login;
                          break;
                        case 'user_left':
                          cardColor = Colors.orange;
                          icon = Icons.logout;
                          break;
                        default:
                          cardColor = Colors.grey;
                          icon = Icons.info;
                      }
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: cardColor.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: Icon(icon, color: cardColor),
                          title: Text(
                            message['message']?.toString() ?? 
                            message['username']?.toString() ?? 
                            type,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Type: $type | Time: $timestamp',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a test message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
