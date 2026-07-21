import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_data.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final ReportData? reportData;

  const ChatScreen({Key? key, this.reportData}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _savedChats = [];
  String? _currentChatId;
  bool _isLoading = false;
  late String _systemInstruction;

  @override
  void initState() {
    super.initState();
    _initPrompt();
    _loadChats();
  }

  void _initPrompt() {
    _systemInstruction = "You are an expert AI medical assistant and nutritionist. ";
    if (widget.reportData != null) {
      final metricsJson = jsonEncode(widget.reportData!.metrics.map((k, v) => MapEntry(k, {'value': v.value, 'status': v.status})));
      _systemInstruction += "The user's latest lab report metrics are: $metricsJson. "
                           "Always answer the user's questions in the context of these specific health parameters. "
                           "Do not give generic advice, tailor it to their out-of-range parameters if any. ";
    }
    
    _systemInstruction += "Your primary goal is to address any doubts the user has related to food, diet, recipes, and nutrition. Give concrete food recommendations based on their health metrics. "
                         "Please keep your answers short, concise, and pointwise so that it is easily readable for the user. "
                         "CRITICAL: Do NOT use any markdown formatting, such as **bold** or asterisks. Return plain text only.";
    
    _messages = [const ChatMessage(text: "Hello! I have analyzed your lab report. How can I help you today with your diet or food choices?", isUser: false)];
    _history = [];
  }

  String _getUserPrefix() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId != null ? '${userId}_' : 'default_';
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('${_getUserPrefix()}chat_history');
    if (saved != null) {
      setState(() {
        final decoded = jsonDecode(saved) as List;
        _savedChats = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveCurrentChat() async {
    if (_history.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    String title = _history.first['parts'][0].toString();
    if (title.length > 25) title = title.substring(0, 25) + '...';

    if (_currentChatId == null) {
      _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
      _savedChats.insert(0, {
        'id': _currentChatId,
        'title': title,
        'history': _history,
      });
    } else {
      int idx = _savedChats.indexWhere((c) => c['id'] == _currentChatId);
      if (idx != -1) {
        _savedChats[idx]['history'] = _history;
        _savedChats[idx]['title'] = title;
      }
    }
    await prefs.setString('${_getUserPrefix()}chat_history', jsonEncode(_savedChats));
    setState(() {}); // refresh drawer list if open
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = null;
      _initPrompt();
    });
    Navigator.pop(context); // Close drawer
  }
  
  void _restoreChat(Map<String, dynamic> chat) {
    setState(() {
      _currentChatId = chat['id'];
      final rawHistory = chat['history'] as List;
      _history = rawHistory.map((e) => Map<String, dynamic>.from(e)).toList();
      
      _messages = [const ChatMessage(text: "Hello! I have analyzed your lab report. How can I help you today with your diet or food choices?", isUser: false)];
      for (var msg in _history) {
        bool isUser = msg['role'] == 'user';
        String text = msg['parts'][0];
        _messages.insert(0, ChatMessage(text: text, isUser: isUser));
      }
    });
    Navigator.pop(context);
  }

  void _sendMessage() async {
    final text = _textController.text;
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();

    try {
      String response = await ApiService.sendMessage(text, _history, _systemInstruction);
      response = response.replaceAll('**', ''); // Clean up bold markdown for a neat view
      
      _history.add({"role": "user", "parts": [text]});
      _history.add({"role": "model", "parts": [response]});
      await _saveCurrentChat();

      setState(() {
        _messages.insert(0, ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, ChatMessage(text: "Error communicating with AI: $e", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        backgroundColor: isDark ? const Color(0xFF141928) : Colors.white,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF141928) : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chat History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00F2FE)),
                      onPressed: _startNewChat,
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _savedChats.isEmpty
                    ? const Center(child: Text('No previous chats.'))
                    : ListView.builder(
                        itemCount: _savedChats.length,
                        itemBuilder: (context, index) {
                          final chat = _savedChats[index];
                          bool isCurrent = chat['id'] == _currentChatId;
                          return ListTile(
                            leading: Icon(Icons.chat_bubble_outline, color: isCurrent ? const Color(0xFF00F2FE) : Colors.grey),
                            title: Text(chat['title'] ?? 'Chat', maxLines: 1, overflow: TextOverflow.ellipsis),
                            selected: isCurrent,
                            onTap: () => _restoreChat(chat),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Ask about your report...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF00F2FE),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser 
              ? const Color(0xFF00F2FE) 
              : (isDark ? const Color(0xFF2A2D3E) : Colors.white),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Text(
          text, 
          style: TextStyle(
            color: isUser ? Colors.black : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
          )
        ),
      ),
    );
  }
}
