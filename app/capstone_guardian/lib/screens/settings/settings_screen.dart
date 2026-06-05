import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../models/patient.dart';
import '../../state/care_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common.dart';
import 'settings_widgets.dart';

/// 설정 — patient profile, the room (invite) code guardians use to connect, the
/// list of linked guardians, and a small mock 일반 section (개인정보처리방침 등).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    final patient = care.patient;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        const PageHeader(title: '설정'),

        // 환자 프로필
        const SizedBox(height: 20),
        if (patient != null) _ProfileCard(patient: patient),

        // 방 코드 — 보호자 연동용
        if (patient != null) ...[
          const SizedBox(height: 16),
          _RoomCodeCard(code: patient.inviteCode),
        ],

        // 연동된 보호자
        SettingsSection(
          title: '연동된 보호자',
          topMargin: 24,
          children: care.guardians.isEmpty
              ? const [_EmptyGuardians()]
              : [
                  for (var i = 0; i < care.guardians.length; i++)
                    GuardianRow(guardian: care.guardians[i], first: i == 0),
                ],
        ),

        // 일반 (목업)
        SettingsSection(
          title: '일반',
          children: [
            NavRow(
              label: '개인정보처리방침',
              first: true,
              onTap: () => _showMockup(context, '개인정보처리방침'),
            ),
            NavRow(
              label: '이용약관',
              onTap: () => _showMockup(context, '이용약관'),
            ),
            NavRow(label: '앱 정보', trailing: _metaText('v1.0.0')),
          ],
        ),

        // 로그아웃
        const SizedBox(height: 16),
        const _LogoutButton(),
      ],
    );
  }

  Widget _metaText(String text) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.labelAlternative,
          ).tabular,
        ),
      );

  /// Placeholder sheet for the mock 일반 rows — enough to show the entry exists.
  void _showMockup(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          '준비 중입니다.\n실제 문서는 추후 연결될 예정입니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 방 코드 — the patient's invite code. Guardians enter it to link their app.
class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('방 코드', style: AppType.sectionLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: AppType.displayFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.labelStrong,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _CopyButton(code: code),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '보호자에게 이 코드를 공유하면 환자와 연동돼요.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.labelNeutral,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('방 코드를 복사했어요'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primary),
      label: const Text(
        '복사',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.06,
          color: AppColors.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: AppColors.lineNormalNormal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

/// Shown inside the 연동된 보호자 card when no guardian has joined yet.
class _EmptyGuardians extends StatelessWidget {
  const _EmptyGuardians();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Text(
        '아직 연동된 보호자가 없어요.\n위의 방 코드를 공유해 보세요.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.labelNeutral,
        ),
      ),
    );
  }
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
