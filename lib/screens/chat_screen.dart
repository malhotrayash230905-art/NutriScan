import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../models/report_data.dart';

class ChatScreen extends StatefulWidget {
  final ReportData? reportData;

  const ChatScreen({Key? key, this.reportData}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use the API key from your environment or backend. Here it's a placeholder.
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    
    // Inject the report data into the system instructions
    String systemInstruction = "You are an expert AI medical assistant and nutritionist. ";
    if (widget.reportData != null) {
      final metricsJson = jsonEncode(widget.reportData!.metrics.map((k, v) => MapEntry(k, {'value': v.value, 'status': v.status})));
      systemInstruction += "The user's latest lab report metrics are: $metricsJson. "
                           "Always answer the user's questions in the context of these specific health parameters. "
                           "Do not give generic advice, tailor it to their out-of-range parameters if any.";
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
    
    _chat = _model.startChat();
    
    // Initial welcome message
    _messages.add(ChatMessage(text: "Hello! I have analyzed your lab report. How can I help you today?", isUser: false));
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
      final response = await _chat.sendMessage(Content.text(text));
      final aiText = response.text;
      
      if (aiText != null) {
        setState(() {
          _messages.insert(0, ChatMessage(text: aiText, isUser: false));
        });
      }
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
