import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gansdoctor/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gansdoctor/screens/result_screen.dart';
import 'package:gansdoctor/services/detection_service.dart';
import 'package:gansdoctor/widgets/custom_alert_dialog.dart';
import 'package:gansdoctor/widgets/custom_loading_dialog.dart';

class CameraScreen extends StatefulWidget {
  final bool useLBP;
  const CameraScreen({Key? key, required this.useLBP}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
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
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        int selectedCamera = cameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (selectedCamera == -1) selectedCamera = 0;
        await onNewCameraSelected(cameras![selectedCamera]);
      }
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: "Camera Error",
        message: "Gagal mengakses kamera: $e",
      );
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    try {
      if (controller != null) await controller!.dispose();

      controller = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      setState(() => isCameraReady = true);
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: "Gagal Inisialisasi",
        message: "Kamera tidak bisa digunakan: $e",
      );
    }
  }

  void toggleFlash() {
    if (controller == null) return;
    flashEnabled = !flashEnabled;
    controller!.setFlashMode(flashEnabled ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;
    isRearCameraSelected = !isRearCameraSelected;
    int selected =
        isRearCameraSelected
            ? cameras!.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
            )
            : cameras!.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
            );
    if (selected == -1) selected = 0;
    await onNewCameraSelected(cameras![selected]);
  }

  Future<void> takePicture() async {
    if (!controller!.value.isInitialized) return;
    try {
      final file = await controller!.takePicture();
      setState(() => imageFile = File(file.path));
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: "Gagal",
        message: "Gagal mengambil gambar: $e",
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => imageFile = File(picked.path));
      }
    } catch (e) {
      CustomAlertDialog.show(
        context: context,
        title: "Galeri Error",
        message: "Gagal mengambil gambar dari galeri: $e",
      );
    }
  }

  Future<void> _processImage() async {
    if (imageFile == null) return;

    CustomLoadingDialog.show(context);
    try {
      final result =
          widget.useLBP
              ? await detectionService.detectFaceLBP(imageFile!)
              : await detectionService.detectFace(imageFile!);

      if (!mounted) return;
      CustomLoadingDialog.hide(context);

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } catch (e) {
      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      CustomAlertDialog.show(
        context: context,
        title: "Error",
        message: "Proses deteksi gagal dilakukan: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady || controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.cameraScreen),
        centerTitle: true,
        elevation: 0,
      ),
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
                      child:
                          imageFile == null
                              ? CameraPreview(controller!)
                              : Stack(
                                children: [
                                  Image.file(
                                    imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed:
                                          () =>
                                              setState(() => imageFile = null),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        imageFile == null
                            ? [
                              IconButton(
                                icon: const Icon(Icons.photo_library, size: 32),
                                onPressed: _pickImage,
                              ),
                              GestureDetector(
                                onTap: takePicture,
                                child: Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF5DCCFC),
                                      width: 5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 60,
                                      width: 60,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF5DCCFC),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_ios,
                                  size: 32,
                                ),
                                onPressed: _switchCamera,
                              ),
                            ]
                            : [
                              ElevatedButton(
                                onPressed: _processImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5DCCFC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  'Process Image',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                            ],
                  ),
                ),
              ],
            ),

            // Tombol Back
            // Positioned(
            //   top: 16,
            //   left: 16,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF5DCCFC),
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color(0xFF5DCCFC).withOpacity(0.3),
            //           blurRadius: 8,
            //           offset: const Offset(0, 4),
            //         ),
            //       ],
            //     ),
            //     child: IconButton(
            //       icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            //       onPressed: () => Navigator.pop(context),
            //     ),
            //   ),
            // ),

            // // Title di tengah atas (seperti AppBar)
            // Positioned(
            //   top: 16,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: Text(
            //       'Camera',
            //       style: GoogleFonts.poppins(
            //         fontSize: 20,
            //         fontWeight: FontWeight.w600,
            //         color: Colors.black87,
            //       ),
            //     ),
            //   ),
            // ),

            // Tombol Flash
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
