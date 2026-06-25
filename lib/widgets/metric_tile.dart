import 'package:flutter/material.dart';
import 'package:shared_package/shared_package.dart';

class MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color accentColor;

  const MetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semanticsLabel = subtitle == null
        ? '$title $value'
        : '$title $value $subtitle';

    return Tooltip(
      message: semanticsLabel,
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.92),
                borderRadius: AppSpacing.radiusAllFull,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
