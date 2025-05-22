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
        setState(() {
          _groupImageBytes = bytes;
        });
      } else {
        setState(() {
          _groupImage = File(image.path);
        });
      }
    }
  }

  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null && _groupImageBytes == null) return null;

    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('groups/$groupId/image.jpg');

    try {
      if (kIsWeb) {
        await storageRef.putData(_groupImageBytes!);
      } else {
        await storageRef.putFile(_groupImage!);
      }
      final String downloadURL = await storageRef.getDownloadURL();
      print("Uploaded Group Image URL: $downloadURL");
      return downloadURL;
    } catch (e) {
      print('Error al subir la imagen del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto del grupo.')),
      );
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final groupRef = await FirebaseFirestore.instance.collection('groups').add({
          'Name': _nameController.text.trim(),
          'Description': _descriptionController.text.trim(),
          'Users': [widget.ownerId],
          'Owner': widget.ownerId,
          'imageUrl': null, // Inicialmente sin imagen
        });

        final groupId = groupRef.id;
        final imageUrl = await _uploadGroupImage(groupId);

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
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el grupo: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGroupImagePreview() {
    if (_groupImage != null) {
      return Image.file(
        _groupImage!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else if (_groupImageBytes != null) {
      return Image.memory(
        _groupImageBytes!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      return const SizedBox(
        width: 100,
        height: 100,
        child: Icon(Icons.image_outlined),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Grupo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: _buildGroupImagePreview(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Grupo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce el nombre del grupo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción del Grupo',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createGroup,
                      child: const Text('Crear Grupo', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}