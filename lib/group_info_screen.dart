import 'package:flutter/material.dart';
import 'qr_generator_screen.dart';
import 'user_info_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_group_screen.dart';
import 'gemini_chatbot_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final String? groupId;
  final String? uid;
  final Map<String, dynamic> group;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    this.uid,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final String? groupImageUrl = group['imageUrl'] as String?;
    final List<dynamic> usersInGroupIds =
        group['Users'] as List<dynamic>? ?? [];
    final String? ownerId = group['Owner'] as String?;
    const primaryColor = Color(0xFFD32F2F);
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          group['Name'] as String? ?? 'Información del Grupo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (uid == ownerId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (groupId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditGroupScreen(
                            groupId: groupId,
                            groupData: group,
                            uid: ownerId,
                          ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error: No se pudo obtener el ID del grupo para editar.',
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                  image:
                      groupImageUrl != null && groupImageUrl.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(groupImageUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    groupImageUrl == null || groupImageUrl.isEmpty
                        ? const Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Colors.grey,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              group['Description'] as String? ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              'Usuarios en el grupo:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: usersInGroupIds.length,
                itemBuilder: (context, index) {
                  final userId = usersInGroupIds[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Cargando...'));
                      }
                      if (snapshot.hasError) {
                        return const ListTile(
                          title: Text('Error al cargar usuario'),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const ListTile(
                          title: Text('Usuario no encontrado'),
                        );
                      }
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final name =
                          userData['name'] as String? ?? 'Nombre no disponible';
                      final niu = userData['niu'] as String? ?? '';

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: niu.isNotEmpty ? Text('NIU: $niu') : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UserInfoScreen(
                                    userId: userId,
                                    currentUserId: uid,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    ),
                    onPressed: () {
                      if (groupId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => QRGeneratorScreen(data: groupId!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error: No se pudo obtener el ID del grupo.',
                            ),
                          ),
                        );
                      }
                    },
                    label: const Text(
                      'Mostrar QR',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    ),
                    onPressed: () {
                      if (groupId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    GeminiChatbotScreen(groupId: groupId!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error: No se pudo obtener el ID del grupo para el chatbot.',
                            ),
                          ),
                        );
                      }
                    },
                    label: const Text(
                      'Chatbot del Grupo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
