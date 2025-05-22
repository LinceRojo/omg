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

  const EditGroupScreen({super.key, required this.groupId, required this.groupData, this.uid});

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
    _nameController = TextEditingController(text: widget.groupData['Name'] as String? ?? '');
    _descriptionController = TextEditingController(text: widget.groupData['Description'] as String? ?? '');
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

  Future<void> _updateGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        String? newImageUrl = _currentImageUrl;
        if (_groupImage != null || _groupImageBytes != null) {
          newImageUrl = await _uploadGroupImage(widget.groupId!);
        }

        await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
          'Name': _nameController.text.trim(),
          'Description': _descriptionController.text.trim(),
          if (newImageUrl != null) 'imageUrl': newImageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo actualizado exitosamente.')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(uid: widget.uid,),
          ),
        ); // Volver a la pantalla de información del grupo
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el grupo: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
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
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar la imagen actual: $error');
          return const Icon(Icons.image_outlined, size: 100);
        },
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
        title: const Text('Editar Grupo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                            child: _buildImagePreview(),
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
                        onPressed: _isLoading ? null : _updateGroup,
                        child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}