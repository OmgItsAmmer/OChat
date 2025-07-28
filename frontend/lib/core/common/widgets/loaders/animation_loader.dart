import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// 🎭 OMGx OChat Premium Animation Loader
///
/// A sophisticated animation loader widget featuring:
/// - AI-inspired glassmorphism design
/// - Premium purple theme integration
/// - Smooth animations and transitions
/// - Customizable action buttons
class TAnimationLoaderWidget extends StatelessWidget {
  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    required this.animation,
    required this.showAction,
    this.actionText,
    this.onActionPressed,
    this.actionButtonStyle,
    this.containerHeight,
    this.animationSize,
    this.spacing,
  });

  final String text;
  final String animation;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final ButtonStyle? actionButtonStyle;
  final double? containerHeight;
  final double? animationSize;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveAnimationSize = animationSize ?? screenWidth * 0.7;
    final effectiveSpacing = spacing ?? TSizes.defaultSpace;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🎭 Animation Container with Glassmorphism
          Container(
            width: effectiveAnimationSize,
            height: effectiveAnimationSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // 🌟 Glassmorphism background
              color: TColors.cardBackground.withOpacity(0.1),
              border: Border.all(
                color: TColors.borderPrimary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Lottie.asset(
                animation,
                width: effectiveAnimationSize,
                height: effectiveAnimationSize,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
          ),

          SizedBox(height: effectiveSpacing),

          // 📝 Premium Text Styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: effectiveSpacing),

          // 🔳 Premium Action Button
          if (showAction) ...[
            Container(
              width: 280,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: TColors.purpleGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onActionPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TColors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        actionText ?? 'Try Again',
                        style: const TextStyle(
                          color: TColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 48), // Maintain spacing when no button
          ],
        ],
      ),
    );
  }
}

/// 🚀 OMGx OChat Specialized Loaders
///
/// Pre-configured loaders for common scenarios in the OChat app
class OChatLoaders {
  /// 🔄 General loading state
  static Widget loading({
    String message = 'Loading...',
    double? size,
  }) {
    return TAnimationLoaderWidget(
      text: message,
      animation: 'assets/animations/loading.json', // You'll need to add this
      showAction: false,
      animationSize: size ?? 200,
    );
  }

  /// 📶 No internet connection
  static Widget noInternet({
    VoidCallback? onRetry,
  }) {
    return TAnimationLoaderWidget(
      text: 'No internet connection\nPlease check your network and try again',
      animation: 'assets/animations/no_internet.json',
      showAction: true,
      actionText: 'Retry Connection',
      onActionPressed: onRetry,
    );
  }

  /// 📭 Empty state (no messages, etc.)
  static Widget empty({
    required String message,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return TAnimationLoaderWidget(
      text: message,
      animation: 'assets/animations/empty.json',
      showAction: onAction != null,
      actionText: actionText ?? 'Get Started',
      onActionPressed: onAction,
    );
  }

  /// ❌ Error state
  static Widget error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return TAnimationLoaderWidget(
      text: message,
      animation: 'assets/animations/error.json',
      showAction: true,
      actionText: 'Try Again',
      onActionPressed: onRetry,
    );
  }

  /// 🔐 Authentication required
  static Widget authRequired({
    VoidCallback? onLogin,
  }) {
    return TAnimationLoaderWidget(
      text: 'Authentication required\nPlease sign in to continue using OChat',
      animation: 'assets/animations/auth.json',
      showAction: true,
      actionText: 'Sign In',
      onActionPressed: onLogin,
    );
  }

  /// 🤖 AI processing state
  static Widget aiProcessing({
    String message = 'AI is processing your request...',
  }) {
    return TAnimationLoaderWidget(
      text: message,
      animation: 'assets/animations/ai_processing.json',
      showAction: false,
      animationSize: 180,
    );
  }

  /// 💬 No messages state
  static Widget noMessages({
    VoidCallback? onStartChat,
  }) {
    return TAnimationLoaderWidget(
      text: 'No messages yet\nStart a conversation to see messages here',
      animation: 'assets/animations/chat_empty.json',
      showAction: true,
      actionText: 'Start Chatting',
      onActionPressed: onStartChat,
    );
  }

  /// 🔍 Search no results
  static Widget noSearchResults({
    VoidCallback? onClearSearch,
  }) {
    return TAnimationLoaderWidget(
      text: 'No results found\nTry adjusting your search terms',
      animation: 'assets/animations/search_empty.json',
      showAction: true,
      actionText: 'Clear Search',
      onActionPressed: onClearSearch,
    );
  }

  /// 📱 Update available
  static Widget updateAvailable({
    VoidCallback? onUpdate,
  }) {
    return TAnimationLoaderWidget(
      text:
          'A new version of OChat is available\nUpdate now to get the latest features',
      animation: 'assets/animations/update.json',
      showAction: true,
      actionText: 'Update Now',
      onActionPressed: onUpdate,
    );
  }

  /// 🎉 Success state
  static Widget success({
    required String message,
    VoidCallback? onContinue,
  }) {
    return TAnimationLoaderWidget(
      text: message,
      animation: 'assets/animations/success.json',
      showAction: onContinue != null,
      actionText: 'Continue',
      onActionPressed: onContinue,
    );
  }
}
