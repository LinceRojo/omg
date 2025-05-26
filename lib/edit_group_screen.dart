import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:omg/home_screen.dart';
import 'dart:typed_data';

class EditGroupScreen extends StatefulWidget {
  final String? groupId;
  final Map<String, dynamic> groupData;
  final String? uid;

  const EditGroupScreen({
    super.key,
    required this.groupId,
    required this.groupData,
    this.uid,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  File? _groupImage;
  Uint8List? _groupImageBytes;
  String? _currentImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.groupData['Name'] as String? ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.groupData['Description'] as String? ?? '',
    );
    _currentImageUrl = widget.groupData['imageUrl'] as String?;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _groupImageBytes = bytes;
          _groupImage = null;
        });
      } else {
        setState(() {
          _groupImage = File(image.path);
          _groupImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null && _groupImageBytes == null) return null;

    final Reference storageRef = FirebaseStorage.instance.ref().child(
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

  Future<void> _updateGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? newImageUrl = _currentImageUrl;
        if (_groupImage != null || _groupImageBytes != null) {
          newImageUrl = await _uploadGroupImage(widget.groupId!);
        }

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
              'Name': _nameController.text.trim(),
              'Description': _descriptionController.text.trim(),
              if (newImageUrl != null) 'imageUrl': newImageUrl,
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo actualizado exitosamente.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(uid: widget.uid)),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el grupo: $error')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_groupImage != null) {
      return Image.file(_groupImage!, fit: BoxFit.cover);
    } else if (_groupImageBytes != null) {
      return Image.memory(_groupImageBytes!, fit: BoxFit.cover);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_outlined, size: 60);
        },
      );
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
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Editar Grupo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                            child: _buildImagePreview(),
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
                                    ? 'Por favor, introduce el nombre del grupo.'
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
                          icon: const Icon(Icons.save, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius,
                            ),
                          ),
                          onPressed: _updateGroup,
                          label: const Text(
                            'Guardar Cambios',
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
