// group_info_screen.dart
import 'package:flutter/material.dart';
import 'qr_generator_screen.dart';
import 'user_info_screen.dart'; // Importa UserInfoScreen
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInfoScreen extends StatelessWidget {
  final String? groupId;
  final String? uid;
  final Map<String, dynamic> group;

  const GroupInfoScreen({super.key, required this.groupId, this.uid , required this.group});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> usersInGroupIds = group['Users'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(group['Name'] as String? ?? 'Información del Grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group['Description'] as String? ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Usuarios en el grupo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: usersInGroupIds.length,
                itemBuilder: (context, index) {
                  final userId = usersInGroupIds[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Cargando...'));
                      }
                      if (snapshot.hasError) {
                        return ListTile(title: Text('Error al cargar usuario'));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return ListTile(title: Text('Usuario no encontrado'));
                      }
                      final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final name = userData['name'] as String? ?? 'Nombre no disponible';
                      final niu = userData['niu'] as String? ?? ''; // NIU es opcional

                      return ListTile(
                        title: Text(name),
                        subtitle: niu.isNotEmpty ? Text('NIU: $niu') : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserInfoScreen(userId: userId, currentUserId: uid),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (groupId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRGeneratorScreen(data: groupId!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: No se pudo obtener el ID del grupo.')),
                    );
                  }
                },
                child: const Text('Mostrar QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}