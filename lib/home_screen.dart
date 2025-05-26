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
    const primaryColor = Color(0xFFD32F2F);
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Grupos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              if (uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            UserInfoScreen(userId: uid!, currentUserId: uid),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: UID de usuario no disponible.'),
                  ),
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
                  const SnackBar(
                    content: Text('Error: UID de usuario no disponible.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  elevation: 4,
                ),
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
                      const SnackBar(
                        content: Text('Error: UID de usuario no disponible.'),
                      ),
                    );
                  }
                },
                label: const Text(
                  'Crear Nuevo Grupo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
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
                  return Center(child: Text('Error: \${snapshot.error}'));
                }
                final groupsWithId = snapshot.data ?? [];
                if (groupsWithId.isEmpty) {
                  return const Center(
                    child: Text(
                      'No perteneces a ningún grupo.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: groupsWithId.length,
                  itemBuilder: (context, index) {
                    final groupWithId = groupsWithId[index];
                    final groupId = groupWithId['id'] as String?;
                    final groupData =
                        groupWithId['data'] as Map<String, dynamic>? ?? {};
                    final String? groupImageUrl =
                        groupData['imageUrl'] as String?;

                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder:
                          (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          ),
                      child: InkWell(
                        borderRadius: borderRadius,
                        onTap: () {
                          if (groupId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => GroupInfoScreen(
                                      groupId: groupId,
                                      group: groupData,
                                      uid: uid,
                                    ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: borderRadius,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 80,
                                    height: 60,
                                    child:
                                        groupImageUrl != null &&
                                                groupImageUrl.isNotEmpty
                                            ? Image.network(
                                              groupImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                );
                                              },
                                            )
                                            : Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_outlined,
                                                size: 40,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        groupData['Name'] as String? ??
                                            'Nombre Desconocido',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        groupData['Description'] as String? ??
                                            'Descripción Desconocida',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
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
    if (uid == null) return [];
    final groupsWithId = <Map<String, dynamic>>[];
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('groups')
            .where('Users', arrayContains: uid)
            .get();

    for (final doc in querySnapshot.docs) {
      groupsWithId.add({'id': doc.id, 'data': doc.data()});
    }
    return groupsWithId;
  }
}
