import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class CreateGroupScreen extends StatefulWidget {
  final String ownerId;

  const CreateGroupScreen({super.key, required this.ownerId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  File? _groupImage;
  Uint8List? _groupImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _groupImageBytes = bytes);
      } else {
        setState(() => _groupImage = File(image.path));
      }
    }
  }

  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null && _groupImageBytes == null) return null;

    final storageRef = FirebaseStorage.instance.ref().child(
      'groups/$groupId/image.jpg',
    );

    try {
      if (kIsWeb) {
        await storageRef.putData(_groupImageBytes!);
      } else {
        await storageRef.putFile(_groupImage!);
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto del grupo.')),
      );
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final groupRef = await FirebaseFirestore.instance
            .collection('groups')
            .add({
              'Name': _nameController.text.trim(),
              'Description': _descriptionController.text.trim(),
              'Users': [widget.ownerId],
              'Owner': widget.ownerId,
              'imageUrl': null,
            });

        final imageUrl = await _uploadGroupImage(groupRef.id);
        if (imageUrl != null) {
          await groupRef.update({'imageUrl': imageUrl});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo creado exitosamente.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(uid: widget.ownerId),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear el grupo: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGroupImagePreview() {
    if (_groupImage != null) {
      return Image.file(_groupImage!, fit: BoxFit.cover);
    } else if (_groupImageBytes != null) {
      return Image.memory(_groupImageBytes!, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.image_outlined, size: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD32F2F);
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Crear Nuevo Grupo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 140,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Center(child: _buildGroupImagePreview()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Grupo',
                          prefixIcon: const Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: borderRadius,
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Introduce un nombre.'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción del Grupo',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: borderRadius,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius,
                            ),
                          ),
                          onPressed: _createGroup,
                          label: const Text(
                            'Crear Grupo',
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
