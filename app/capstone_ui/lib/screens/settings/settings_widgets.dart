import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../../state/settings_provider.dart';
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

/// Label (+ optional subtitle) with a trailing control, e.g. a toggle.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.control,
    this.subtitle,
    this.first = false,
  });

  final String label;
  final String? subtitle;
  final Widget control;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(label, style: AppType.settingsRowLabel),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppType.settingsRowSub),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
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

/// 글자 크기 segmented control row (settings.jsx font-size block).
class FontSizeRow extends StatelessWidget {
  const FontSizeRow({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<double> _sizes = [12, 14, 16, 19];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('글자 크기', style: AppType.settingsRowLabel),
              Text(
                SettingsProvider.fontSizeLabels[index],
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.23,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: index == i ? AppColors.primary : AppColors.fillAlternative,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '가',
                        style: TextStyle(
                          fontSize: _sizes[i],
                          fontWeight: FontWeight.w700,
                          color: index == i ? Colors.white : AppColors.labelNeutral,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 44×26 pill toggle with a 22×22 thumb and 180ms motion (settings.jsx
/// `Toggle`).
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: const Cubic(0.2, 0, 0, 1),
          width: 44,
          height: 26,
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.fillNormal,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: const Cubic(0.2, 0, 0, 1),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.15), blurRadius: 3, offset: Offset(0, 1))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
