import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isCameraReady = false;
  bool isRearCameraSelected = false;
  bool flashEnabled = false;
  File? imageFile;
  bool isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final DetectionService detectionService = DetectionService();

  // Animation controllers for better UX
  late AnimationController _fabAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _buttonSlideAnimation;

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

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _buttonSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
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
          message:
              "Gagal mengakses kamera. Pastikan aplikasi memiliki izin kamera.",
          type: AlertType.error,
        );
      }
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

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

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

    // Animation and haptic feedback
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    HapticFeedback.mediumImpact();

    try {
      final file = await controller!.takePicture();
      setState(() => imageFile = File(file.path));
      _buttonAnimationController.forward();
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
      if (picked != null) {
        setState(() => imageFile = File(picked.path));
        _buttonAnimationController.forward();
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

  Future<void> _processImage() async {
    if (imageFile == null || isProcessing) return;

    setState(() => isProcessing = true);
    CustomLoadingDialog.show(context);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final result =
          widget.useLBP
              ? await detectionService.detectFaceLBP(imageFile!)
              : await detectionService.detectFace(imageFile!);

      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      setState(() => isProcessing = false);

      // Success haptic feedback
      HapticFeedback.heavyImpact();

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } on DetectionException catch (e) {
      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      setState(() => isProcessing = false);

      // Handle different types of detection errors
      switch (e.type) {
        case DetectionErrorType.noFaceDetected:
          CustomAlertDialog.showFaceDetectedError(
            context: context,
            message: e.message,
            onRetry: () => _processImage(),
          );
          break;

        case DetectionErrorType.connectionError:
          CustomAlertDialog.showConnectionError(
            context: context,
            onRetry: () => _processImage(),
          );
          break;

        case DetectionErrorType.serverError:
        case DetectionErrorType.invalidResponse:
        case DetectionErrorType.unknown:
        default:
          CustomAlertDialog.show(
            context: context,
            title: "Proses Gagal",
            message: e.message,
            type: AlertType.error,
            confirmText: "Coba Lagi",
            onConfirm: () => _processImage(),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      setState(() => isProcessing = false);

      CustomAlertDialog.show(
        context: context,
        title: "Error",
        message: "Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.",
        type: AlertType.error,
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      imageFile = null;
      isProcessing = false;
    });
    _buttonAnimationController.reset();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady || controller == null) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.cameraScreen,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // backgroundColor: Colors.black,
        // foregroundColor: Colors.white,
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
                      imageFile == null
                          ? CameraPreview(controller!)
                          : Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),

                      // Close button (when image is selected)
                      if (imageFile != null)
                        Positioned(
                          top: 16,
                          right: 16,
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _retakePhoto,
                            ),
                          ),
                        ),

                      // Flash toggle (when no image selected)
                      if (imageFile == null)
                        Positioned(
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
                                color:
                                    flashEnabled ? Colors.yellow : Colors.white,
                              ),
                              onPressed: toggleFlash,
                            ),
                          ),
                        ),

                      // Method indicator
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Controls
            imageFile == null ? _buildCameraControls() : _buildProcessButton(),

            const SizedBox(height: 20),
          ],
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
          // Gallery button
          Container(
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
              icon: const Icon(
                Icons.photo_library_outlined,
                size: 28,
                color: Colors.white,
              ),
              onPressed: _pickImage,
            ),
          ),

          // Capture button
          GestureDetector(
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
                      border: Border.all(
                        color: const Color(0xFF5DCCFC),
                        width: 4,
                      ),
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
                            colors: [
                              const Color(0xFF5DCCFC),
                              const Color(0xFF0099FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Switch camera button
          Container(
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
              icon: const Icon(
                Icons.flip_camera_ios_outlined,
                size: 28,
                color: Colors.white,
              ),
              onPressed: _switchCamera,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_buttonSlideAnimation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Process button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : _processImage,
                icon:
                    isProcessing
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.psychology_outlined),
                label: Text(
                  isProcessing ? "Memproses..." : "Analisis Gambar",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0099FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  elevation: 8,
                  shadowColor: const Color(0xFF0099FF).withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Retake button
            TextButton.icon(
              onPressed: isProcessing ? null : _retakePhoto,
              icon: const Icon(Icons.refresh_outlined),
              label: Text(
                "Ambil Ulang",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[400],
                disabledForegroundColor: Colors.blue[600],
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
    _fabAnimationController.dispose();
    _buttonAnimationController.dispose();
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
