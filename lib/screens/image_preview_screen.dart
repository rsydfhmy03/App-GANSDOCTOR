import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gansdoctor/screens/result_screen.dart';
import 'package:gansdoctor/services/detection_service.dart';
import 'package:gansdoctor/widgets/custom_alert_dialog.dart';
import 'package:gansdoctor/widgets/custom_loading_dialog.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final bool useLBP;

  const ImagePreviewScreen({
    Key? key,
    required this.imageFile,
    required this.useLBP,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with TickerProviderStateMixin {
  bool isProcessing = false;
  final DetectionService detectionService = DetectionService();

  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animation when screen loads
    _buttonAnimationController.forward();
  }

  Future<void> _processImage() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);
    CustomLoadingDialog.show(context);
    HapticFeedback.mediumImpact();

    try {
      final result = widget.useLBP
          ? await detectionService.detectFaceLBP(widget.imageFile)
          : await detectionService.detectFace(widget.imageFile);

      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      setState(() => isProcessing = false);

      HapticFeedback.heavyImpact();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } on DetectionException catch (e) {
      if (!mounted) return;
      CustomLoadingDialog.hide(context);
      setState(() => isProcessing = false);

      _handleDetectionError(e);
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

  void _handleDetectionError(DetectionException e) {
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
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Preview Gambar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retakePhoto,
        ),
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
                      Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      _buildCloseButton(),
                      _buildMethodIndicator(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildProcessButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _retakePhoto,
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
                icon: isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    _buttonAnimationController.dispose();
    super.dispose();
  }
}