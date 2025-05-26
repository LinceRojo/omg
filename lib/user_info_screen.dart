import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_update_screen.dart';

class UserInfoScreen extends StatelessWidget {
  final String userId;
  final String? currentUserId;

  const UserInfoScreen({super.key, required this.userId, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD32F2F);
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Información del Usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (userId == currentUserId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserUpdateScreen(uid: userId),
                  ),
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuario no encontrado.'));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] as String? ?? 'Nombre no disponible';
          final email = userData['email'] as String? ?? 'Email no disponible';
          final niu = userData['niu'] as String? ?? 'NIU no disponible';
          final github =
              userData['github'] as String? ?? 'Github no disponible';
          final profileImageUrl = userData['profileImageUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (profileImageUrl != null && profileImageUrl.isNotEmpty)
                            ? NetworkImage(profileImageUrl)
                            : null,
                    child:
                        (profileImageUrl == null || profileImageUrl.isEmpty)
                            ? const Icon(
                              Icons.account_circle,
                              size: 60,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Email:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'NIU:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        niu,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Github:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        github,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
