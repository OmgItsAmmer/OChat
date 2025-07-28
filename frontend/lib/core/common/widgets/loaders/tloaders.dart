import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

/// 🚀 OMGx OChat Enhanced Loaders
///
/// Premium AI-inspired loaders and notifications featuring:
/// - Dark purple theme integration
/// - Smooth animations
/// - Glassmorphism effects
/// - Professional feedback systems
class TLoader {
  /// Hide current snackbar
  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  /// 🎨 Custom AI-inspired Toast with Glassmorphism
  static customToast({required String message, Duration? duration}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // 🌟 Glassmorphism effect
            color: TColors.cardBackground.withOpacity(0.95),
            border: Border.all(
              color: TColors.borderPrimary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔮 AI accent dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: TColors.neonAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TColors.neonAccent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: TColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Success notification with AI styling
  static successSnackBar(
      {required String title, String message = '', int duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: TColors.success,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      boxShadows: [
        BoxShadow(
          color: TColors.success.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.tick_circle,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// ⚠️ Warning notification with AI styling
  static warningSnackBar(
      {required String title, String message = '', int duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: TColors.warning,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      boxShadows: [
        BoxShadow(
          color: TColors.warning.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.warning_2,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// ❌ Error notification with AI styling
  static errorSnackBar(
      {required String title, String message = '', int duration = 4}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: TColors.error,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      boxShadows: [
        BoxShadow(
          color: TColors.error.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.close_circle,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 🔗 Info notification with AI styling
  static infoSnackBar(
      {required String title, String message = '', int duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: TColors.info,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      boxShadows: [
        BoxShadow(
          color: TColors.info.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.info_circle,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 🤖 AI-specific notification for OMGx OChat
  static aiSnackBar(
      {required String title, String message = '', int duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: TColors.primary,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      boxShadows: [
        BoxShadow(
          color: TColors.primary.withOpacity(0.4),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: TColors.neonAccent.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: -5,
          offset: const Offset(0, 0),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TColors.neonAccent.withOpacity(0.3),
              TColors.secondary.withOpacity(0.3),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.cpu,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 💬 Message-specific notification for chat features
  static messageSnackBar(
      {required String title, String message = '', int duration = 2}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: false,
      colorText: TColors.white,
      backgroundColor: TColors.myMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      boxShadows: [
        BoxShadow(
          color: TColors.myMessage.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.message,
          color: TColors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 🔄 Loading dialog with AI-inspired design
  static showLoadingDialog({required String message}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TColors.borderPrimary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI-inspired loading animation
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: TColors.aiGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: TColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
