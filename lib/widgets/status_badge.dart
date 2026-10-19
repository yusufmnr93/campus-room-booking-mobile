import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';

/// Badge status booking dengan warna yang sesuai.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = _getStatusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _getStatusStyle() {
    switch (status) {
      case AppConstants.statusBooked:
        return (
          AppTheme.bookedColor,
          AppTheme.bookedColor.withValues(alpha: 0.12),
          AppDateUtils.statusLabel(status),
        );
      case AppConstants.statusCancelled:
        return (
          AppTheme.cancelledColor,
          AppTheme.cancelledColor.withValues(alpha: 0.12),
          AppDateUtils.statusLabel(status),
        );
      default:
        return (
          Colors.grey,
          Colors.grey.withValues(alpha: 0.12),
          status,
        );
    }
  }
}
