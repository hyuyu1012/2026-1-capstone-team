import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// h1 + optional subtitle at the top of each tab (shared.jsx `PageHeader`).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.pageTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: AppType.pageSubtitle),
          ],
        ],
      ),
    );
  }
}

/// Small uppercase caps label with an optional right-aligned value
/// (shared.jsx `SectionHeader`).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: AppType.sectionLabel)),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.23, // 0.02em
                color: AppColors.labelAlternative,
              ).tabular,
            ),
        ],
      ),
    );
  }
}

/// White card with the design's 1px border and no shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.lineNormalNeutral),
      ),
      child: child,
    );
  }
}

/// Top bar with the notification bell + unread dot (shared.jsx `TopBar`).
class CareTopBar extends StatelessWidget {
  const CareTopBar({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onBell,
              tooltip: '알림',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 22, color: AppColors.labelStrong),
                  Positioned(
                    top: -1,
                    right: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.statusCautionary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.pageBackground, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
