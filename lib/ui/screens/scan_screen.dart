import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/scan_provider.dart';
import '../../utils/image_converter.dart';
import '../../utils/patch_sampler.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_overlay.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (_) {
      // Camera not available or denied; fallback UI is available
    }
  }

  Future<void> _captureFrame() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final scanProv = context.read<ScanProvider>();

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xfile = await _cameraController!.takePicture();
        final bytes = await xfile.readAsBytes();
        final img = decodeImage(bytes);
        if (img != null) {
          final sampled = PatchSampler.sampleFaceletColors(img);
          scanProv.captureCurrentFace(sampled);
        }
      }
    } catch (_) {
      // If taking photo fails or simulated, advance manually
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (scanProv.currentFaceIndex == 5 && scanProv.isScanComplete) {
          context.push('/correction');
        }
      }
    }
  }

  void _manualDemoScramble() {
    final scanProv = context.read<ScanProvider>();
    // Pre-populate with standard scrambled cube
    const demo = [
      4, 0, 4, 0, 0, 0, 4, 0, 4, // U
      2, 4, 2, 4, 4, 4, 2, 4, 2, // R
      1, 2, 1, 2, 2, 2, 1, 2, 1, // F
      5, 1, 5, 1, 1, 1, 5, 1, 5, // D
      3, 5, 3, 5, 5, 5, 3, 5, 3, // L
      0, 3, 0, 3, 3, 3, 0, 3, 0, // B
    ];
    for (int i = 0; i < 54; i++) {
      scanProv.updateFacelet(i, demo[i]);
    }
    context.push('/correction');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scanning ${scanProv.currentFaceName}'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => context.push('/correction'),
            child: const Text('Edit Grid', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera viewfinder or placeholder
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: AppTheme.bgDark,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Preview',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Align each cube face inside the 3x3 frame or use manual entry.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _manualDemoScramble,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Load Demo / Manual Input'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3x3 Overlay
          ScanOverlay(
            faceName: scanProv.currentFaceName,
            faceIndex: scanProv.currentFaceIndex,
            isScanning: _isProcessing,
            onCapture: _captureFrame,
          ),
        ],
      ),
    );
  }
}

// Fallback image decoder
dynamic decodeImage(List<int> bytes) {
  try {
    return ImageConverter.convertCameraImage; // Or image decode
  } catch (_) {
    return null;
  }
}
