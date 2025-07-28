import 'package:flutter/material.dart';

/// 🎨 OMGx OChat - AI-Inspired Dark Purple Theme
///
/// A sophisticated color palette designed for OMGx's flagship AI messaging app.
/// Features deep purples, neon accents, and premium gradients that reflect
/// innovation and cutting-edge AI technology.
class TColors {
  // 🚀 OMGx Brand - Primary AI Purple Theme
  static const Color primary = Color(0xFF7C3AED); // Vibrant purple
  static const Color primaryDark = Color(0xFF5B21B6); // Deep royal purple
  static const Color primaryLight = Color(0xFF8B5CF6); // Lighter purple
  static const Color secondary = Color(0xFF06B6D4); // Cyan accent (AI feel)
  static const Color accent = Color(0xFFEC4899); // Pink accent
  static const Color neonAccent = Color(0xFF00F5FF); // Neon cyan
  static const Color background = Color(0xFFF5F3FF); // background for light mode

  // 🌟 Gradient Colors for Premium Feel
  static const Color gradientStart = Color(0xFF7C3AED); // Purple
  static const Color gradientMid = Color(0xFF8B5CF6); // Light purple
  static const Color gradientEnd = Color(0xFFEC4899); // Pink

  // 🌙 Dark Theme - Professional & Sleek
  static const Color backgroundDark =
      Color(0xFF0F0F23); // Very dark blue-purple
  static const Color surfaceDark = Color(0xFF1A1A2E); // Dark surface
  static const Color cardDark = Color(0xFF16213E); // Card background
  static const Color elevation1 = Color(0xFF1F1F3A); // Slightly elevated
  static const Color elevation2 = Color(0xFF2A2A4A); // More elevated

  // 🎯 Text Colors - High Contrast & Accessibility
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB8BCC8); // Light grey
  static const Color textTertiary = Color(0xFF8B8B9A); // Muted grey
  static const Color textWhite = Color(0xFFFFFFFF); // White
  static const Color textPurple = Color(0xFF8B5CF6); // Purple text
  static const Color textCyan = Color(0xFF06B6D4); // Cyan text

  // 💬 Chat-Specific Colors
  static const Color myMessage = Color(0xFF7C3AED); // My messages (purple)
  static const Color otherMessage = Color(0xFF2D2D4A); // Other messages (dark)
  static const Color messageTime = Color(0xFF8B8B9A); // Timestamp color
  static const Color onlineIndicator =
      Color(0xFF00FF88); // Online status (green)
  static const Color typingIndicator = Color(0xFF06B6D4); // Typing indicator

  // 🔳 Button Colors - Interactive Elements
  static const Color buttonPrimary = Color(0xFF7C3AED); // Primary button
  static const Color buttonSecondary = Color(0xFF2D2D4A); // Secondary button
  static const Color buttonDisabled = Color(0xFF4A4A6A); // Disabled state
  static const Color buttonHover = Color(0xFF8B5CF6); // Hover state
  static const Color buttonPressed = Color(0xFF5B21B6); // Pressed state

  // 🎨 Input & Form Colors
  static const Color inputBackground =
      Color(0xFF1A1A2E); // Input field background
  static const Color inputBorder = Color(0xFF3D3D5C); // Input border
  static const Color inputBorderFocused = Color(0xFF7C3AED); // Focused border
  static const Color inputText = Color(0xFFFFFFFF); // Input text
  static const Color inputHint = Color(0xFF8B8B9A); // Placeholder text

  // 🔲 Border & Divider Colors
  static const Color borderPrimary = Color(0xFF3D3D5C); // Primary border
  static const Color borderSecondary = Color(0xFF2A2A4A); // Secondary border
  static const Color divider = Color(0xFF2A2A4A); // Divider lines

  // 🚨 Status & Feedback Colors
  static const Color error = Color(0xFFEF4444); // Error red
  static const Color success = Color(0xFF10B981); // Success green
  static const Color warning = Color(0xFFF59E0B); // Warning amber
  static const Color info = Color(0xFF06B6D4); // Info cyan

  // 🎯 AI-Specific Colors
  static const Color aiAccent = Color(0xFF00F5FF); // AI neon cyan
  static const Color aiGradientStart = Color(0xFF7C3AED); // AI gradient start
  static const Color aiGradientEnd = Color(0xFF06B6D4); // AI gradient end
  static const Color robotText = Color(0xFF00F5FF); // AI/Bot text color

  // 🌐 Social & Interactive
  static const Color link = Color(0xFF06B6D4); // Links
  static const Color linkHover = Color(0xFF0891B2); // Link hover
  static const Color mention = Color(0xFFEC4899); // @mentions
  static const Color hashtag = Color(0xFF8B5CF6); // #hashtags

  // 🎨 Neutral Shades - Dark Theme Optimized
  static const Color black = Color(0xFF000000); // Pure black
  static const Color darkest = Color(0xFF0F0F23); // Darkest shade
  static const Color darker = Color(0xFF1A1A2E); // Darker shade
  static const Color dark = Color(0xFF2D2D4A); // Dark shade
  static const Color medium = Color(0xFF4A4A6A); // Medium shade
  static const Color light = Color(0xFF8B8B9A); // Light shade
  static const Color lighter = Color(0xFFB8BCC8); // Lighter shade
  static const Color lightest = Color(0xFFE5E5E9); // Lightest shade
  static const Color white = Color(0xFFFFFFFF); // Pure white

  // 🌈 Special Effect Colors
  static const Color shimmerBase = Color(0xFF2A2A4A); // Shimmer effect base
  static const Color shimmerHighlight = Color(0xFF3D3D5C); // Shimmer highlight
  static const Color glowPurple = Color(0x337C3AED); // Purple glow
  static const Color glowCyan = Color(0x3306B6D4); // Cyan glow

  // 🎯 Message Status Colors
  static const Color messageSent = Color(0xFF8B8B9A); // Message sent
  static const Color messageDelivered = Color(0xFF06B6D4); // Message delivered
  static const Color messageRead = Color(0xFF10B981); // Message read
  static const Color messageFailed = Color(0xFFEF4444); // Message failed

  // 🔄 Loading & Progress Colors
  static const Color loadingPrimary = Color(0xFF7C3AED); // Primary loading
  static const Color loadingSecondary = Color(0xFF2D2D4A); // Secondary loading
  static const Color progressBackground =
      Color(0xFF2A2A4A); // Progress bar background
  static const Color progressFill = Color(0xFF7C3AED); // Progress bar fill

  // 🎨 Premium Gradients
  static const List<Color> purpleGradient = [
    Color(0xFF7C3AED), // Purple
    Color(0xFF8B5CF6), // Light purple
  ];

  static const List<Color> aiGradient = [
    Color(0xFF7C3AED), // Purple
    Color(0xFF06B6D4), // Cyan
  ];

  static const List<Color> chatGradient = [
    Color(0xFF8B5CF6), // Light purple
    Color(0xFFEC4899), // Pink
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF0F0F23), // Very dark
    Color(0xFF1A1A2E), // Dark
  ];

  // 🎯 Component-Specific Colors

  /// App Bar Colors
  static const Color appBarBackground = Color(0xFF1A1A2E);
  static const Color appBarForeground = Color(0xFFFFFFFF);

  /// Bottom Navigation Colors
  static const Color bottomNavBackground = Color(0xFF16213E);
  static const Color bottomNavSelected = Color(0xFF7C3AED);
  static const Color bottomNavUnselected = Color(0xFF8B8B9A);

  /// Card Colors
  static const Color cardBackground = Color(0xFF16213E);
  static const Color cardShadow = Color(0x1A000000);

  /// Avatar Colors
  static const Color avatarBackground = Color(0xFF2D2D4A);
  static const Color avatarBorder = Color(0xFF7C3AED);

  /// Floating Action Button
  static const Color fabBackground = Color(0xFF7C3AED);
  static const Color fabForeground = Color(0xFFFFFFFF);

  // 🎨 Helper Methods for Dynamic Colors

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get lighter shade of color
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Get darker shade of color
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
