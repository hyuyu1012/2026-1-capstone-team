import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../state/care_provider.dart';
import '../../theme/app_colors.dart';
import 'connect_code_screen.dart';
import 'new_patient_screen.dart';
import 'onboarding_widgets.dart';

/// First branch after login (PatientSetup.html `VersionA` — the card-select
/// layout chosen for this project): connect to an existing patient, or
/// register a new one. Shown by [AuthGate] whenever the signed-in guardian has
/// no patient linked yet.
class BranchScreen extends StatelessWidget {
  const BranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingTopBar(
              onBack: () => Navigator.maybePop(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StepChip(step: 1, total: 3),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      context.read<CareProvider>().unbindFromGuardian();
                      await context.read<AuthService>().signOut();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelNeutral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: _Greeting(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChoiceCard(
                      primary: true,
                      icon: Icons.link_rounded,
                      tag: '가족이 이미 가입했어요',
                      title: '기존 환자 연결',
                      desc: '가족에게 받은 초대 코드를 입력해 함께 돌봐요',
                      meta: '가장 흔한 경우',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConnectCodeScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      primary: false,
                      icon: Icons.person_add_alt_1_outlined,
                      tag: '처음 시작합니다',
                      title: '새 환자 등록',
                      desc: '돌봄 대상자 정보를 입력하고 새로 시작해요',
                      meta: '약 2분 소요',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NewPatientScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        const Text(
          '환영합니다',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.72, // 0.06em
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.528,
              height: 1.3,
              color: AppColors.labelStrong,
            ),
            children: [
              TextSpan(text: '돌봄을 시작할\n'),
              TextSpan(text: '방법을 선택해주세요', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '가족이 이미 가입했다면 연결하고, 처음이라면 새로 시작하세요.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: AppColors.labelNeutral,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.primary,
    required this.icon,
    required this.tag,
    required this.title,
    required this.desc,
    required this.meta,
    required this.onTap,
  });

  final bool primary;
  final IconData icon;
  final String tag;
  final String title;
  final String desc;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onCard = primary ? Colors.white : AppColors.labelStrong;
    final dim = primary ? const Color.fromRGBO(255, 255, 255, 0.78) : AppColors.labelAlternative;
    final descColor = primary ? const Color.fromRGBO(255, 255, 255, 0.82) : AppColors.labelNeutral;
    final divider = primary ? const Color.fromRGBO(255, 255, 255, 0.18) : AppColors.lineNormalNeutral;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: AppColors.lineNormalNormal),
          boxShadow: primary
              ? const [BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.22), blurRadius: 18, offset: Offset(0, 6))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary ? const Color.fromRGBO(255, 255, 255, 0.16) : AppColors.fillAlternative,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: onCard),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.84, // 0.08em
                          color: dim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.204,
                          color: onCard,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.chevron_right_rounded, size: 18,
                      color: primary ? const Color.fromRGBO(255, 255, 255, 0.85) : AppColors.labelAlternative),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: descColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: divider))),
              child: Text(
                meta,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.23,
                  color: dim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
