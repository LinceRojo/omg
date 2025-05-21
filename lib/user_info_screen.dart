import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_update_screen.dart';

class UserInfoScreen extends StatelessWidget {
  final String userId;
  final String? currentUserId; // Nuevo parámetro para el ID del usuario actual

  const UserInfoScreen({super.key, required this.userId, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Usuario'),
        actions: [
          if (userId == currentUserId) // Mostrar botón solo si es el perfil del usuario actual
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
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
          final github = userData['github'] as String? ?? 'Github no disponible';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Email: $email'),
                const SizedBox(height: 8),
                Text('NIU: $niu'),
                const SizedBox(height: 8),
                Text('Github: $github'),
              ],
            ),
          );
        },
      ),
    );
  }
}