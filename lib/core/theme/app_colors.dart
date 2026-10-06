import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (Aligned with True Root #007E6E logo)
  static const Color primary = Color(0xFF007E6E);
  static const Color primaryDark = Color(0xFF004D43);
  static const Color secondary = Color(0xFF10B981);
  static const Color background = Color(0xFFF2F9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFE6F4EE);
  static const Color border = Color(0xFFCCE6DC);
  static const Color accent = Color(0xFFD1FAE5);
  static const Color textDark = Color(0xFF11261F);
  static const Color textMuted = Color(0xFF527066);

  // Dark mode (Botanical forest palette)
  static const Color darkBackground = Color(0xFF091914);
  static const Color darkSurface = Color(0xFF0F261F);
  static const Color darkSurfaceAlt = Color(0xFF16352C);
  static const Color darkBorder = Color(0xFF224A3E);
  static const Color darkText = Color(0xFFE4F5EE);
  static const Color darkMuted = Color(0xFF8AAFA1);

  // Status colors for batch states & workflows
  static const Color statusActive = Color(0xFF16A34A); // Green
  static const Color statusTransferred = Color(0xFF0D9488); // Teal
  static const Color statusSplit = Color(0xFF7C3AED); // Purple
  static const Color statusPending = Color(0xFFD97706); // Amber
  static const Color statusDisqualified = Color(0xFFDC2626); // Red
  static const Color statusArchived = Color(0xFF64748B); // Slate
  static const Color statusMerged = Color(0xFF059669); // Emerald

  // Helper method for status color
  static Color statusColor(String? status) {
    if (status == null) return textMuted;
    final upper = status.toUpperCase();
    switch (upper) {
      case 'ACTIVE':
      case 'CREATED':
        return statusActive;
      case 'APPROVED':
      case 'TRANSFERRED':
        return statusTransferred;
      case 'SPLIT':
        return statusSplit;
      case 'PENDING':
        return statusPending;
      case 'DISQUALIFIED':
      case 'REJECTED':
      case 'DELETED':
        return statusDisqualified;
      case 'ARCHIVED':
        return statusArchived;
      case 'MERGED':
      case 'TRANSFORMED':
        return statusMerged;
      default:
        return primary;
    }
  }
}
