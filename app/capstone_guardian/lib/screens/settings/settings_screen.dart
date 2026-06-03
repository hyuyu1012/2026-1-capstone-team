import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../models/patient.dart';
import '../../state/care_provider.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common.dart';
import 'settings_widgets.dart';

/// 설정 — patient profile, notifications, meds info, guardians, display, general.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final settings = context.watch<SettingsProvider>();
    final patient = care.patient;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        const PageHeader(title: '설정'),

        // 환자 프로필
        const SizedBox(height: 20),
        if (patient != null) _ProfileCard(patient: patient),

        // 알림
        SettingsSection(
          title: '알림',
          topMargin: 24,
          children: [
            SettingsRow(
              label: '복용 알림',
              subtitle: '예정 시간에 알림을 보냅니다',
              first: true,
              control: AppToggle(value: settings.reminder, onChanged: settings.setReminder),
            ),
            SettingsRow(
              label: '누락 알림',
              subtitle: '30분 이상 지나면 다시 알려요',
              control: AppToggle(value: settings.missedAlert, onChanged: settings.setMissedAlert),
            ),
            SettingsRow(
              label: '보호자에게 푸시',
              subtitle: '누락 시 가족에게 알림',
              control: AppToggle(value: settings.guardianPush, onChanged: settings.setGuardianPush),
            ),
            SettingsRow(
              label: '알림음',
              subtitle: '기본 · 부드러운 차임',
              control: AppToggle(value: settings.sound, onChanged: settings.setSound),
            ),
          ],
        ),

        // 복용 정보
        SettingsSection(
          title: '복용 정보',
          children: [
            NavRow(label: '복용 일정 관리', first: true, trailing: _metaText('${care.meds.length}개', bold: true)),
            NavRow(label: '식사 시간 설정', trailing: _metaText('08:30 · 12:30 · 18:30')),
            const NavRow(label: '처방 기록', subtitle: '병원 / 처방전 사진 보관'),
          ],
        ),

        // 가족 · 보호자
        SettingsSection(
          title: '가족 · 보호자',
          children: [
            for (var i = 0; i < care.guardians.length; i++)
              GuardianRow(guardian: care.guardians[i], first: i == 0),
            const NavRow(label: '보호자 초대', primary: true),
          ],
        ),

        // 화면
        SettingsSection(
          title: '화면',
          children: [
            SettingsRow(
              label: '다크 모드',
              first: true,
              control: AppToggle(value: settings.darkMode, onChanged: settings.setDarkMode),
            ),
            FontSizeRow(
              index: settings.fontSizeIndex,
              onChanged: settings.setFontSizeIndex,
            ),
          ],
        ),

        // 일반
        SettingsSection(
          title: '일반',
          children: [
            const NavRow(label: '개인정보 및 데이터', first: true),
            const NavRow(label: '도움말 · 문의'),
            NavRow(label: '앱 정보', trailing: _metaText('v1.0.0', weight: FontWeight.w500)),
          ],
        ),

        // 로그아웃
        const SizedBox(height: 16),
        const _LogoutButton(),
      ],
    );
  }

  Widget _metaText(String text, {bool bold = false, FontWeight? weight}) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: weight ?? (bold ? FontWeight.w700 : FontWeight.w600),
            color: AppColors.labelAlternative,
          ).tabular,
        ),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.avatarGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              patient.profileInitial,
              style: const TextStyle(
                fontFamily: AppType.displayFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.204, // -0.012em
                    color: AppColors.labelStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.relation} · 만 ${patient.age}세',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.025,
                    color: AppColors.labelNeutral,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.lineNormalNormal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text(
              '편집',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.06,
                color: AppColors.labelStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('로그아웃'),
              content: const Text('정말 로그아웃하시겠어요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;
          context.read<CareProvider>().unbindFromGuardian();
          await context.read<AuthService>().signOut();
          if (!context.mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.lineNormalNeutral),
          ),
        ),
        child: const Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.07,
            color: AppColors.statusNegative,
          ),
        ),
      ),
    );
  }
}
