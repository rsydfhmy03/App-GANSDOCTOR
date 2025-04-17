import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gansdoctor/screens/result_screen.dart';
import 'package:gansdoctor/services/detection_service.dart';
import 'package:gansdoctor/utils/helpers.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isCameraReady = false;
  bool isRearCameraSelected = false;
  bool flashEnabled = false;
  File? imageFile;

  final ImagePicker _picker = ImagePicker();
  final DetectionService detectionService = DetectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      int selectedCamera = cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (selectedCamera == -1) selectedCamera = 0;
      await onNewCameraSelected(cameras![selectedCamera]);
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller!.dispose();

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
      setState(() => isCameraReady = true);
    } catch (e) {
      Helpers.showSnackBar(context, 'Camera error: $e');
    }
  }

  void toggleFlash() {
    if (controller == null) return;
    flashEnabled = !flashEnabled;
    controller!.setFlashMode(flashEnabled ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;
    isRearCameraSelected = !isRearCameraSelected;
    int selected = isRearCameraSelected
        ? cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.back)
        : cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    if (selected == -1) selected = 0;
    await onNewCameraSelected(cameras![selected]);
  }

  Future<void> takePicture() async {
    if (!controller!.value.isInitialized) return;
    try {
      final file = await controller!.takePicture();
      setState(() => imageFile = File(file.path));
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to take picture: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => imageFile = File(picked.path));
  }

  Future<void> _processImage() async {
    if (imageFile == null) return;
    Helpers.showLoadingDialog(context);
    try {
      final result = await detectionService.detectFace(imageFile!);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageFile: imageFile!, result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Helpers.showSnackBar(context, 'Detection failed: $e');
    }
  }

  Widget buildProcessButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        _processImage();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF5DCCFC),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5DCCFC).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Proses Gambar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady || controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: imageFile == null
                          ? CameraPreview(controller!)
                          : Stack(
                              children: [
                                Image.file(imageFile!, fit: BoxFit.cover, width: double.infinity),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                    onPressed: () => setState(() => imageFile = null),
                                  ),
                                )
                              ],
                            ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: imageFile == null
                        ? [
                            IconButton(
                              icon: const Icon(Icons.photo_library, size: 32),
                              onPressed: _pickImage,
                            ),
                            Container(
                              height: 75,
                              width: 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Center(
                                child: Container(
                                  height: 55,
                                  width: 55,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF5DCCFC),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.flip_camera_ios, size: 32),
                              onPressed: _switchCamera,
                            ),
                          ]
                        : [
                            // buildProcessButton(),
                                                        ElevatedButton(
                              onPressed: _processImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DCCFC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: Text('Proses Gambar', style: GoogleFonts.poppins(fontSize: 16)),
                            ),
                          ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5DCCFC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5DCCFC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  flashEnabled ? Icons.flash_on : Icons.flash_off,
                  color: Colors.blue,
                  size: 28,
                ),
                onPressed: toggleFlash,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(controller!.description);
    }
  }
}