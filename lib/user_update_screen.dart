import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:omg/user_verification_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class UserUpdateScreen extends StatefulWidget {
  final String? uid;

  const UserUpdateScreen({super.key, required this.uid});

  @override
  State<UserUpdateScreen> createState() => _UserUpdateScreenState();
}

class _UserUpdateScreenState extends State<UserUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _niuController = TextEditingController();
  final _githubController = TextEditingController();
  bool _isLoading = false;
  bool _userExists = false;
  File? _profileImage;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (widget.uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userExists = true;
          _nameController.text = userDoc.data()?['name'] ?? '';
          _emailController.text = userDoc.data()?['email'] ?? '';
          _niuController.text = userDoc.data()?['niu'] ?? '';
          _githubController.text = userDoc.data()?['github'] ?? '';
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
          print("Loaded Profile Image URL: $_profileImageUrl"); // Log when loading data
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
        });
      } else {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null && _profileImageBytes == null) return null;

    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('users/${widget.uid}/profile.jpg');

    try {
      if (kIsWeb) {
        await storageRef.putData(_profileImageBytes!);
      } else {
        await storageRef.putFile(_profileImage!);
      }
      final String downloadURL = await storageRef.getDownloadURL();
      print("Uploaded Profile Image URL: $downloadURL"); // Log after upload
      return downloadURL;
    } catch (e) {
      print('Error al subir la imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto de perfil.')),
      );
      return null;
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final profileImageUrl = await _uploadProfileImage();
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'niu': _niuController.text.trim(),
          'github': _githubController.text.trim(),
          'profileImageUrl': profileImageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente.')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserVerificationScreen(uid: widget.uid)));
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la cuenta: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final profileImageUrl = await _uploadProfileImage() ?? _profileImageUrl;
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'niu': _niuController.text.trim(),
          'github': _githubController.text.trim(),
          'profileImageUrl': profileImageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado exitosamente.')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserVerificationScreen(uid: widget.uid)));
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el usuario: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userExists ? 'Actualizar Usuario' : 'Crear Cuenta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center, // O el centro, etc.
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: ClipOval(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: kIsWeb
                                    ? _profileImageBytes != null
                                        ? MemoryImage(_profileImageBytes!)
                                        : _profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                            : const AssetImage('default_profile.png')
                                    : _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : _profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                            : const AssetImage('default_profile.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce tu nombre.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce tu correo electrónico.';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor, introduce un correo electrónico válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _niuController,
                      decoration: const InputDecoration(
                        labelText: 'NIU (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _githubController,
                      decoration: const InputDecoration(
                        labelText: 'Github (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _userExists
                              ? _updateUser
                              : _createUser,
                      child: Text(
                        _userExists ? 'Actualizar Usuario' : 'Crear Cuenta',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}