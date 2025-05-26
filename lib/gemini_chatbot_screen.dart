import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';

class GeminiChatbotScreen extends StatefulWidget {
  final String groupId;

  const GeminiChatbotScreen({super.key, required this.groupId});

  @override
  State<GeminiChatbotScreen> createState() => _GeminiChatbotScreenState();
}

class _GeminiChatbotScreenState extends State<GeminiChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final Gemini _gemini = Gemini.instance;

  Future<Map<String, dynamic>?> _getGroupData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();
      return snapshot.data();
    } catch (e) {
      log('Error al obtener datos del grupo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      return snapshot.data();
    } catch (e) {
      log('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  Future<List<Part>> _buildPromptParts(String userQuery) async {
    final groupData = await _getGroupData();
    String context = '';

    if (groupData != null) {
      final groupName = groupData['Name'] ?? 'Este grupo';
      final groupDescription = groupData['Description'] ?? 'este grupo';
      final userIds = groupData['Users'] as List<dynamic>? ?? [];
      final usersInfo = <Map<String, dynamic>>[];

      for (final userId in userIds) {
        final userData = await _getUserData(userId);
        if (userData != null) {
          usersInfo.add({
            'name': userData['name'],
            'email': userData['email'],
            'github': userData['github'],
            'niu': userData['niu'],
          });
        }
      }

      context =
          '''Eres un asistente útil que proporciona información relevante sobre el grupo "$groupName".
Descripción: "$groupDescription".
Miembros: ${usersInfo.map((u) => u['name']).join(', ')}.
Detalles:
${usersInfo.map((u) => '- ${u['name']} (${u['email']}, GitHub: ${u['github'] ?? 'N/A'}, NIU: ${u['niu'] ?? 'N/A'})').join('\n')}
''';
    }

    return [Part.text(context), Part.text('Usuario: $userQuery')];
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();

    final parts = await _buildPromptParts(text);

    try {
      final response = await _gemini.prompt(parts: parts);
      final output = response?.output ?? 'Sin respuesta del chatbot.';
      setState(() => _messages.add(ChatMessage(text: output, isUser: false)));
    } catch (e) {
      setState(
        () => _messages.add(ChatMessage(text: 'Error: $e', isUser: false)),
      );
    } finally {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Chatbot del Grupo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: ChatBubble(text: msg.text, isUser: msg.isUser),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black87,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_textController.text),
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

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser ? Colors.redAccent : Colors.grey.shade300;
    final textColor = isUser ? Colors.white : Colors.black;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius =
        isUser
            ? const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, borderRadius: radius),
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
        ),
      ],
    );
  }
}
