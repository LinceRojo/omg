import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_info_screen.dart';
import 'mobile_scanner_screen.dart';
import 'create_group_screen.dart';
import 'user_info_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? uid;

  const HomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle), // Icono de avatar típico
            onPressed: () {
              if (uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoScreen(userId: uid!, currentUserId: uid),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: UID de usuario no disponible.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              if (uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MobileScannerScreen(userId: uid!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: UID de usuario no disponible.')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (uid != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateGroupScreen(ownerId: uid!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: UID de usuario no disponible.')),
                  );
                }
              },
              child: const Text('Crear Nuevo Grupo'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getGroupsForUser(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final groupsWithId = snapshot.data ?? [];
                if (groupsWithId.isEmpty) {
                  return const Center(child: Text('No perteneces a ningún grupo.'));
                }
                return ListView.builder(
                  itemCount: groupsWithId.length,
                  itemBuilder: (context, index) {
                    final groupWithId = groupsWithId[index];
                    final groupId = groupWithId['id'] as String?;
                    final groupData = groupWithId['data'] as Map<String, dynamic>? ?? {};
                    final String? groupImageUrl = groupData['imageUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          if (groupId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupInfoScreen(groupId: groupId, group: groupData, uid: uid,),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                height: 60,
                                child: groupImageUrl != null && groupImageUrl.isNotEmpty
                                    ? Image.network(
                                        groupImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error al cargar la imagen del grupo: $error');
                                          return const Icon(Icons.image_outlined, size: 40);
                                        },
                                      )
                                    : const Icon(Icons.image_outlined, size: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupData['Name'] as String? ?? 'Nombre Desconocido',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      groupData['Description'] as String? ?? 'Descripción Desconocida',
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getGroupsForUser(String? uid) async {
    if (uid == null) {
      return [];
    }
    final groupsWithId = <Map<String, dynamic>>[];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('Users', arrayContains: uid)
        .get();

    for (final doc in querySnapshot.docs) {
      groupsWithId.add({'id': doc.id, 'data': doc.data()});
    }
    return groupsWithId;
  }
}