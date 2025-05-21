import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore

import 'home_screen.dart';
import 'user_update_screen.dart';

class UserVerificationScreen extends StatefulWidget {
  final String? uid;

  const UserVerificationScreen({super.key, required this.uid});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserExists();
  }

  Future<void> _checkUserExists() async {
    if (widget.uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      String uid_string = widget.uid!;
      if (userDoc.exists) {
        // El UID existe en la base de datos, navegar a la pantalla X
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(uid:uid_string)), // Reemplaza HomeScreen() con tu pantalla principal
        );
      } else {
        // El UID no existe, navegar a la pantalla Y
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserUpdateScreen(uid:uid_string)),
        );
      }
    } else {
      // Manejar el caso en que el UID sea nulo (posible error)
      print("Error: UID es nulo en UserVerificationScreen.");
      // Podrías navegar a una pantalla de error o volver a la pantalla de inicio de sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Text('Error: UID nulo')), // Ejemplo de pantalla de error
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla no necesita mostrar nada visualmente, ya que redirige inmediatamente
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Opcional: Mostrar un indicador de carga brevemente
      ),
    );
  }
}