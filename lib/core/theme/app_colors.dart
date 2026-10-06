import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1569C7);
  static const Color primaryDark = Color(0xFF0A355E);
  static const Color secondary = Color(0xFF6CB6FF);
  static const Color background = Color(0xFFEAF3FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F8FF);
  static const Color border = Color(0xFFD7E6FA);
  static const Color accent = Color(0xFFDDEBFF);
  static const Color textDark = Color(0xFF12304F);
  static const Color textMuted = Color(0xFF5F7795);

  // Dark mode
  static const Color darkBackground = Color(0xFF081529);
  static const Color darkSurface = Color(0xFF0E223A);
  static const Color darkSurfaceAlt = Color(0xFF17324F);
  static const Color darkBorder = Color(0xFF24425F);
  static const Color darkText = Color(0xFFD9E9FF);
  static const Color darkMuted = Color(0xFFA4BAD4);

  // Status colors for batch states & workflows
  static const Color statusActive = Color(0xFF16A34A); // Green
  static const Color statusTransferred = Color(0xFF2563EB); // Royal Blue
  static const Color statusSplit = Color(0xFF7C3AED); // Purple
  static const Color statusPending = Color(0xFFD97706); // Amber
  static const Color statusDisqualified = Color(0xFFDC2626); // Red
  static const Color statusArchived = Color(0xFF64748B); // Slate
  static const Color statusMerged = Color(0xFF0D9488); // Teal

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
