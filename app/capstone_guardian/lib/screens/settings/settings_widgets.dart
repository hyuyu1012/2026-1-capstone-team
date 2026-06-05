import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common.dart';

/// A titled group of rows inside a single bordered card (settings.jsx
/// `SettingsSection`).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.topMargin = 18,
  });

  final String title;
  final List<Widget> children;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(title, style: AppType.sectionLabel),
          ),
          AppCard(radius: 14, clip: true, child: Column(children: children)),
        ],
      ),
    );
  }
}

/// Tappable navigation row with a chevron (settings.jsx `NavRow`). When
/// [primary] is true it renders as the "+ 보호자 초대" accent action with no
/// chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.first = false,
    this.primary = false,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final bool first;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: first ? null : const Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary ? '+ $label' : label,
                    style: AppType.settingsRowLabel.copyWith(
                      fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                      color: primary ? AppColors.primary : AppColors.labelStrong,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppType.settingsRowSub),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (!primary)
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.labelAlternative),
          ],
        ),
      ),
    );
  }
}

/// A guardian entry with avatar initial + active chip (settings.jsx
/// `GuardianRow`).
class GuardianRow extends StatelessWidget {
  const GuardianRow({super.key, required this.guardian, this.first = false});

  final Guardian guardian;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.fillAlternative),
            alignment: Alignment.center,
            child: Text(
              guardian.name.characters.first,
              style: const TextStyle(
                fontFamily: AppType.displayFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.labelNeutral,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardian.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.07,
                    color: AppColors.labelStrong,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  guardian.relation,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.labelNeutral,
                  ),
                ),
              ],
            ),
          ),
          if (guardian.active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green10bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '활성',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.22,
                  color: AppColors.green40,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
