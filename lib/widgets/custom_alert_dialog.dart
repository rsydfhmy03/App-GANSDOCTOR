import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info }

class CustomAlertDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    AlertType type = AlertType.info,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
    bool dismissible = true,
  }) {
    final iconData = _getIconData(type);
    final iconColor = _getIconColor(type);
    final backgroundColor = _getBackgroundColor(type);

    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with animated background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        size: 40,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onConfirm != null) onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curveAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInBack,
        );
        
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.7,
              end: 1.0,
            ).animate(curveAnimation),
            child: child,
          ),
        );
      },
    );
  }

  // Show specific dialog for face detection errors (silent, no popup)
  static void showFaceDetectedError({
    required BuildContext context,
    required String message,
    VoidCallback? onRetry,
  }) {
    // For face detection errors, we show a subtle snackbar instead of popup
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.face_retouching_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  // Show connection error as a subtle message
  static void showConnectionError({
    required BuildContext context,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Periksa koneksi internet Anda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static IconData _getIconData(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle;
      case AlertType.error:
        return Icons.error;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.info:
      default:
        return Icons.info;
    }
  }

  static Color _getIconColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return const Color(0xFF4CAF50);
      case AlertType.error:
        return const Color(0xFFE53E3E);
      case AlertType.warning:
        return const Color(0xFFFF9800);
      case AlertType.info:
      default:
        return const Color(0xFF5DCCFC);
    }
  }

  static Color _getBackgroundColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return const Color(0xFF4CAF50).withOpacity(0.1);
      case AlertType.error:
        return const Color(0xFFE53E3E).withOpacity(0.1);
      case AlertType.warning:
        return const Color(0xFFFF9800).withOpacity(0.1);
      case AlertType.info:
      default:
        return const Color(0xFF5DCCFC).withOpacity(0.1);
    }
  }
}