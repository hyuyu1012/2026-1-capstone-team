import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/care_icon.dart';

/// First registration menu opened by the center FAB (app.jsx `RegisterSheet`).
/// Pops with the chosen entry point: `'med'`, `'meal'`, or null (스캔/dismiss).
class RegisterSheet extends StatelessWidget {
  const RegisterSheet({super.key});

  /// Shows the menu; resolves to the selected option's id.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      isScrollControlled: true,
      builder: (_) => const RegisterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lineNormalNormal,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Text(
                '새로 등록하기',
                style: TextStyle(
                  fontFamily: AppType.displayFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.342, // -0.018em
                  color: AppColors.labelStrong,
                ),
              ),
            ),
            _Option(
              glyph: CareGlyph.med,
              title: '복용 약 등록',
              subtitle: '처방받은 약을 추가합니다',
              onTap: () => Navigator.pop(context, 'med'),
            ),
            _Option(
              glyph: CareGlyph.meal,
              title: '식사 일정 등록',
              subtitle: '아침 · 점심 · 저녁 시간을 정합니다',
              onTap: () => Navigator.pop(context, 'meal'),
            ),
            _Option(
              icon: Icons.document_scanner_outlined,
              title: '처방전 스캔',
              subtitle: '사진 한 장으로 자동 입력',
              badge: '새 기능',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    this.glyph,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final CareGlyph? glyph;
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary08,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: glyph != null
                  ? CareIcon(glyph!, size: 22, color: AppColors.primary, strokeWidth: 1.8)
                  : Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.0725,
                            color: AppColors.labelStrong,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary10,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.023,
                      color: AppColors.labelNeutral,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.labelAlternative),
          ],
        ),
      ),
    );
  }
}
