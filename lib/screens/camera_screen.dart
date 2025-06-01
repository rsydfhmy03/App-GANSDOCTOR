import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gansdoctor/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gansdoctor/screens/image_preview_screen.dart';
import 'package:gansdoctor/widgets/custom_alert_dialog.dart';

class CameraScreen extends StatefulWidget {
  final bool useLBP;
  const CameraScreen({Key? key, required this.useLBP}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isCameraReady = false;
  bool isRearCameraSelected = false;
  bool flashEnabled = false;

  final ImagePicker _picker = ImagePicker();

  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    initializeCamera();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
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
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: "Camera Error",
          message: "Gagal mengakses kamera. Pastikan aplikasi memiliki izin kamera.",
          type: AlertType.error,
        );
      }
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    try {
      if (controller != null) {
        // Turn off flash before disposing camera
        if (flashEnabled) {
          await controller!.setFlashMode(FlashMode.off);
          setState(() => flashEnabled = false);
        }
        await controller!.dispose();
      }
      
      controller = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller!.initialize();
      if (mounted) {
        setState(() => isCameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: "Gagal Inisialisasi",
          message: "Kamera tidak bisa digunakan. Silakan restart aplikasi.",
          type: AlertType.error,
        );
      }
    }
  }

  void toggleFlash() {
    if (controller == null) return;
    flashEnabled = !flashEnabled;
    controller!.setFlashMode(flashEnabled ? FlashMode.torch : FlashMode.off);
    setState(() {});
    HapticFeedback.lightImpact();
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    HapticFeedback.mediumImpact();

    isRearCameraSelected = !isRearCameraSelected;
    int selected = isRearCameraSelected
        ? cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.back)
        : cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    
    if (selected == -1) selected = 0;
    await onNewCameraSelected(cameras![selected]);
  }

  Future<void> takePicture() async {
    if (!controller!.value.isInitialized) return;

    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    HapticFeedback.mediumImpact();

    try {
      // Turn off flash before taking picture
      if (flashEnabled) {
        await controller!.setFlashMode(FlashMode.off);
        setState(() => flashEnabled = false);
      }

      final file = await controller!.takePicture();
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imageFile: File(file.path),
              useLBP: widget.useLBP,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: "Gagal Mengambil Foto",
          message: "Terjadi kesalahan saat mengambil foto. Silakan coba lagi.",
          type: AlertType.error,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (picked != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imageFile: File(picked.path),
              useLBP: widget.useLBP,
            ),
          ),
        );
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: "Galeri Error",
          message: "Gagal mengambil gambar dari galeri. Periksa izin aplikasi.",
          type: AlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady || controller == null) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.cameraScreen,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      CameraPreview(controller!),
                      _buildFlashToggle(),
                      _buildMethodIndicator(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCameraControls(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DCCFC)),
            ),
            const SizedBox(height: 20),
            Text(
              'Memuat Kamera...',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashToggle() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            flashEnabled ? Icons.flash_on : Icons.flash_off,
            color: flashEnabled ? Colors.yellow : Colors.white,
          ),
          onPressed: toggleFlash,
        ),
      ),
    );
  }

  Widget _buildMethodIndicator() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.useLBP ? 'LBP + CNN' : 'CNN Standard',
            style: GoogleFonts.poppins(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.photo_library_outlined,
            onPressed: _pickImage,
          ),
          _buildCaptureButton(),
          _buildControlButton(
            icon: Icons.flip_camera_ios_outlined,
            onPressed: _switchCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 28, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: takePicture,
      child: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5DCCFC), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5DCCFC).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [const Color(0xFF5DCCFC), const Color(0xFF0099FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Turn off flash before disposing
    if (controller != null && flashEnabled) {
      controller!.setFlashMode(FlashMode.off);
    }
    controller?.dispose();
    _fabAnimationController.dispose();
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