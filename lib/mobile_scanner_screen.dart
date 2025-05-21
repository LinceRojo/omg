import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class MobileScannerScreen extends StatefulWidget {
  final String userId;

  const MobileScannerScreen({super.key, required this.userId});

  @override
  State<MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<MobileScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedBarcode;
  bool isTorchOn = false;
  CameraFacing currentCameraFacing = CameraFacing.back;
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      print("Error toggling torch: $e");
    }
  }

  Future<void> _switchCamera() async {
    try {
      final newFacing = currentCameraFacing == CameraFacing.back
          ? CameraFacing.front
          : CameraFacing.back;
      await cameraController.switchCamera();
      setState(() {
        currentCameraFacing = newFacing;
      });
    } catch (e) {
      print("Error switching camera: $e");
    }
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty && !_isProcessing) {
      setState(() {
        scannedBarcode = barcodes.first.rawValue;
        _isProcessing = true;
      });

      if (scannedBarcode != null) {
        // Navegar a la pantalla de confirmación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JoinGroupConfirmationScreen(
              userId: widget.userId,
              groupId: scannedBarcode!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR para Unirse'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onBarcodeDetected,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Código escaneado: ${scannedBarcode ?? 'Ninguno'}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: isTorchOn ? Colors.yellow : Colors.grey,
                  ),
                  iconSize: 32.0,
                  onPressed: _toggleTorch,
                ),
                IconButton(
                  icon: Icon(
                    currentCameraFacing == CameraFacing.back
                        ? Icons.camera_rear
                        : Icons.camera_front,
                  ),
                  iconSize: 32.0,
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JoinGroupConfirmationScreen extends StatefulWidget {
  final String userId;
  final String groupId;

  const JoinGroupConfirmationScreen({super.key, required this.userId, required this.groupId});

  @override
  State<JoinGroupConfirmationScreen> createState() => _JoinGroupConfirmationScreenState();
}

class _JoinGroupConfirmationScreenState extends State<JoinGroupConfirmationScreen> {
  String? groupName;
  bool _isLoading = false;
  bool _isAlreadyMember = false;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          groupName = doc.data()!['Name'] as String?;
          final users = doc.data()!['Users'] as List<dynamic>? ?? [];
          _isAlreadyMember = users.contains(widget.userId);
        });
      } else {
        setState(() {
          groupName = 'Grupo no encontrado';
        });
      }
    } catch (e) {
      print('Error al cargar la información del grupo: $e');
      setState(() {
        groupName = 'Error al cargar el nombre';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUserToGroup() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'Users': FieldValue.arrayUnion([widget.userId]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te has unido al grupo.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(uid:widget.userId),
          ),
      ); // Volver a la pantalla anterior (Home Screen)
    } catch (e) {
      print('Error al añadir usuario al grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al unirte al grupo.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar unirse al grupo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _isAlreadyMember
                        ? 'Ya formas parte del grupo "${groupName ?? 'Cargando...'}"'
                        : '¿Quieres unirte al grupo "${groupName ?? 'Cargando...'}"?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (!_isAlreadyMember) // Mostrar botones solo si no es miembro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addUserToGroup,
                          child: const Text('Unirme'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Volver a la pantalla del escáner
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  if (_isAlreadyMember) // Mostrar botón para volver si ya es miembro
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Volver a la pantalla del escáner
                      },
                      child: const Text('Volver'),
                    ),
                ],
              ),
            ),
    );
  }
}