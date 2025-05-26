import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:omg/user_verification_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserUpdateScreen extends StatefulWidget {
  final String? uid;

  const UserUpdateScreen({super.key, required this.uid});

  @override
  State<UserUpdateScreen> createState() => _UserUpdateScreenState();
}

class _UserUpdateScreenState extends State<UserUpdateScreen>
    with SingleTickerProviderStateMixin {
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
    setState(() => _isLoading = true);
    if (widget.uid != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();
      if (userDoc.exists) {
        setState(() {
          _userExists = true;
          _nameController.text = userDoc.data()?['name'] ?? '';
          _emailController.text = userDoc.data()?['email'] ?? '';
          _niuController.text = userDoc.data()?['niu'] ?? '';
          _githubController.text = userDoc.data()?['github'] ?? '';
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      } else {
        setState(() => _profileImage = File(image.path));
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null && _profileImageBytes == null) return null;
    final Reference storageRef = FirebaseStorage.instance.ref().child(
      'users/${widget.uid}/profile.jpg',
    );
    try {
      if (kIsWeb) {
        await storageRef.putData(_profileImageBytes!);
      } else {
        await storageRef.putFile(_profileImage!);
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto de perfil.')),
      );
      return null;
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final profileImageUrl = await _uploadProfileImage();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'niu': _niuController.text.trim(),
              'github': _githubController.text.trim(),
              'profileImageUrl': profileImageUrl,
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserVerificationScreen(uid: widget.uid),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la cuenta: $error')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final profileImageUrl = await _uploadProfileImage() ?? _profileImageUrl;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .update({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'niu': _niuController.text.trim(),
              'github': _githubController.text.trim(),
              'profileImageUrl': profileImageUrl,
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado exitosamente.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserVerificationScreen(uid: widget.uid),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el usuario: $error')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD32F2F);
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_userExists ? 'Actualizar Usuario' : 'Crear Cuenta'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Image.asset('./assets/logo.png', height: 100),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder(
                        tween: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, Offset offset, child) {
                          return Opacity(
                            opacity: offset.dy == 0 ? 1 : 0,
                            child: Transform.translate(
                              offset: Offset(0, offset.dy * 100),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: borderRadius,
                          ),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage:
                                            kIsWeb
                                                ? _profileImageBytes != null
                                                    ? MemoryImage(
                                                      _profileImageBytes!,
                                                    )
                                                    : (_profileImageUrl != null
                                                        ? NetworkImage(
                                                          _profileImageUrl!,
                                                        )
                                                        : const AssetImage(
                                                              './assets/default_profile.png',
                                                            )
                                                            as ImageProvider)
                                                : _profileImage != null
                                                ? FileImage(_profileImage!)
                                                : (_profileImageUrl != null
                                                    ? NetworkImage(
                                                      _profileImageUrl!,
                                                    )
                                                    : const AssetImage(
                                                          './assets/default_profile.png',
                                                        )
                                                        as ImageProvider),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre',
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Por favor, introduce tu nombre.'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Correo electrónico',
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                      ),
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
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _niuController,
                                    decoration: InputDecoration(
                                      labelText: 'NIU (opcional)',
                                      prefixIcon: Icon(
                                        Icons.badge_outlined,
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _githubController,
                                    decoration: InputDecoration(
                                      labelText: 'Github (opcional)',
                                      prefixIcon: Icon(
                                        Icons.code,
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: borderRadius,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: Icon(
                                        _userExists
                                            ? Icons.save
                                            : Icons.person_add,
                                        color: Colors.white,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: borderRadius,
                                        ),
                                      ),
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _userExists
                                              ? _updateUser
                                              : _createUser,
                                      label: Text(
                                        _userExists
                                            ? 'Actualizar Usuario'
                                            : 'Crear Cuenta',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
