import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileScannerScreen extends StatefulWidget {
  const MobileScannerScreen({super.key});

  @override
  State<MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<MobileScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedBarcode;
  bool isTorchOn = false;
  CameraFacing currentCameraFacing = CameraFacing.back; // Valor inicial

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner QR con Mobile Scanner'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (barcodeCapture) {
                final List<Barcode> barcodes = barcodeCapture.barcodes;
                if (barcodes.isNotEmpty) {
                  setState(() {
                    scannedBarcode = barcodes.first.rawValue;
                  });
                }
              },
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