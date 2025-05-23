import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Importa la librería flutter_gemini
import 'dart:developer'; // Import para la función log

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

  final Gemini _gemini = Gemini.instance; // Obtiene la instancia de Gemini

  Future<Map<String, dynamic>?> _getGroupData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      return snapshot.data();
    } catch (e) {
      print('Error al obtener datos del grupo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return snapshot.data();
    } catch (e) {
      print('Error al obtener datos del usuario $userId: $e');
      return null;
    }
  }

  Future<List<Part>> _buildPromptParts(String userQuery) async {
    final groupData = await _getGroupData();
    String context = '';

    if (groupData != null) {
      final groupName = groupData['Name'] as String? ?? 'Este grupo';
      final groupDescription = groupData['Description'] as String? ?? 'este grupo';
      final List<dynamic> userIds = groupData['Users'] as List<dynamic>? ?? [];
      List<Map<String, dynamic>> usersInfo = [];

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

      context = '''Eres un asistente útil que proporciona información relevante sobre el grupo "${groupName}".
      La descripción del grupo es: "${groupDescription}".
      Los miembros del grupo son: ${usersInfo.map((user) => user['name']).join(', ')}.
      Aquí tienes información detallada de los miembros:
      ${usersInfo.map((user) => '- Nombre: ${user['name']}, Email: ${user['email']}, GitHub: ${user['github'] ?? 'No disponible'}, NIU: ${user['niu'] ?? 'No disponible'}').join('\n')}

      Historial de conversación:\n${_messages.map((msg) => '${msg.isUser ? 'Usuario' : 'Asistente'}: ${msg.text}').join('\n')}
      ''';
    }

    final List<Part> promptParts = [];
    if (context.isNotEmpty) {
      promptParts.add(Part.text(context));
    }
    promptParts.add(Part.text('Usuario: $userQuery'));

    return promptParts;
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();

    final promptParts = await _buildPromptParts(text);

    try {
      final response = await _gemini.prompt(parts: promptParts);
      if (response != null && response.output != null) {
        setState(() {
          _messages.add(ChatMessage(text: response.output!, isUser: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: 'Error al obtener respuesta del chatbot o respuesta vacía.', isUser: false));
        });
      }
    } catch (e) {
      log('Error al enviar mensaje a Gemini', error: e, name: 'Gemini Error');
      setState(() {
        _messages.add(ChatMessage(text: 'Error: $e', isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Desplazar al final después de que el mensaje se haya añadido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot del Grupo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  text: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          _isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_textController.text),
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
    return Align(
      alignment: isUser ? Alignment.topRight : Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}