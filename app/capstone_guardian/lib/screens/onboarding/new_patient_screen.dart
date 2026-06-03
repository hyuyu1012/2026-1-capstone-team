import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../data/patient_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_widgets.dart';

const List<String> _relations = ['어머니', '아버지', '할머니', '할아버지', '배우자', '기타'];

/// "새 환자 등록" path (NewPatient.html): a brief loading splash, then the
/// patient-info form. A complete form advances to the app.
class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? _LoadingSplash(onSkip: () => setState(() => _loading = false))
          : const _PatientForm(),
    );
  }
}

// ─── Loading splash ──────────────────────────────────────────────────
class _LoadingSplash extends StatefulWidget {
  const _LoadingSplash({required this.onSkip});
  final VoidCallback onSkip;

  @override
  State<_LoadingSplash> createState() => _LoadingSplashState();
}

class _LoadingSplashState extends State<_LoadingSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSkip,
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _c,
                          child: CustomPaint(size: const Size(96, 96), painter: _SpinnerPainter()),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.22), blurRadius: 24, offset: Offset(0, 10))],
                          ),
                          child: const Center(child: BrandShield(size: 36)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '환영합니다',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.68, // 0.14em
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '돌봄을 시작할\n준비를 하고 있어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppType.displayFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.484,
                      height: 1.35,
                      color: AppColors.labelStrong,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _PulsingDots(controller: _c),
                ],
              ),
            ),
            const Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Text(
                '화면을 터치해 계속하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.46,
                  color: AppColors.labelAlternative,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 42.0;
    canvas.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.primary10);
    // ~90° arc (dasharray 66 of ~264 circumference).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => false;
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final phase = (controller.value + i * 0.18) % 1.0;
              final opacity = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
              return Opacity(
                opacity: opacity.clamp(0.25, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ─── Patient info form ───────────────────────────────────────────────
class _PatientForm extends StatefulWidget {
  const _PatientForm();

  @override
  State<_PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<_PatientForm> {
  final _name = TextEditingController();
  String? _relation;
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();
  String? _gender;
  final _note = TextEditingController();

  /// Age relative to the handoff's fixed "today" (2026-05-23), or null if the
  /// date is incomplete/invalid.
  int? get _age {
    final y = int.tryParse(_year.text);
    final m = int.tryParse(_month.text);
    final d = int.tryParse(_day.text);
    if (_year.text.length != 4 || y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final today = DateTime(2026, 5, 23);
    var a = today.year - y;
    if (m > today.month || (m == today.month && d > today.day)) a -= 1;
    return (a >= 0 && a < 130) ? a : null;
  }

  bool _busy = false;

  bool get _valid => _name.text.trim().isNotEmpty && _relation != null && _age != null && _gender != null;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    _month.dispose();
    _day.dispose();
    _note.dispose();
    super.dispose();
  }

  void _backToRoot() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final patient = await context.read<PatientService>().createPatient(
            guardianUid: user.uid,
            name: _name.text.trim(),
            relation: _relation!,
            birthYear: int.parse(_year.text),
            birthMonth: int.parse(_month.text),
            birthDay: int.parse(_day.text),
            gender: _gender!,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      await _showInviteDialog(patient.inviteCode);
      if (!mounted) return;
      _backToRoot();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInviteDialog(String code) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('환자 등록 완료'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '아래 코드를 다른 보호자나 환자 본인에게 공유하면\n같은 환자를 함께 돌볼 수 있어요.',
              style: TextStyle(fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary10,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: AppType.family,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('초대 코드를 복사했어요')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('복사'),
              ),
            ),
          ],
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

  Future<void> _pickRelation() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RelationPicker(selected: _relation),
    );
    if (picked != null) setState(() => _relation = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          OnboardingTopBar(
            onBack: () => Navigator.pop(context),
            trailing: TextButton(
              onPressed: _backToRoot,
              child: const Text('나중에',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.labelNeutral)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 8, 28, 8),
                  child: _HighlightTitle('함께 챙길 가족을 알려주세요'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      LabeledField(
                        label: '이름',
                        required: true,
                        child: AppTextField(
                          controller: _name,
                          placeholder: '예) 이순자',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: '관계',
                        required: true,
                        child: _DropdownField(
                          value: _relation,
                          placeholder: '관계를 선택하세요',
                          onTap: _pickRelation,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: '생년월일',
                        required: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateInput(
                              year: _year,
                              month: _month,
                              day: _day,
                              onChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            _ageHelper(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: '성별',
                        required: true,
                        child: AppSegmentedControl(
                          options: const [(id: 'female', label: '여성'), (id: 'male', label: '남성')],
                          value: _gender,
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        label: '주의사항',
                        optional: true,
                        child: _NoteArea(controller: _note, onChanged: () => setState(() {})),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sticky CTA
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
            ),
            child: PrimaryButton(
              label: _busy ? '등록 중…' : '돌봄 시작하기',
              disabledLabel: '필수 항목을 입력해주세요',
              enabled: _valid && !_busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageHelper() {
    final age = _age;
    if (age != null) {
      return Text('만 $age세',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary));
    }
    return const Text('나이는 자동으로 계산되어요',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.labelNeutral));
  }
}

/// h1 with the design's highlighter swash behind the bottom 40% of the text.
class _HighlightTitle extends StatelessWidget {
  const _HighlightTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent, AppColors.primary20, AppColors.primary20],
            stops: [0, 0.6, 0.6, 1],
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppType.displayFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.528,
            height: 1.3,
            color: AppColors.labelStrong,
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.value, required this.placeholder, required this.onTap});
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lineNormalNormal),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.075,
                  color: value != null ? AppColors.labelStrong : AppColors.labelAlternative,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.labelNeutral),
          ],
        ),
      ),
    );
  }
}

class _RelationPicker extends StatelessWidget {
  const _RelationPicker({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.lineNormalNormal, borderRadius: BorderRadius.circular(999)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('관계 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.labelStrong)),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final r in _relations)
                    InkWell(
                      onTap: () => Navigator.pop(context, r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selected == r ? FontWeight.w700 : FontWeight.w500,
                                  color: selected == r ? AppColors.primary : AppColors.labelStrong,
                                ),
                              ),
                            ),
                            if (selected == r)
                              const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({required this.year, required this.month, required this.day, required this.onChanged});
  final TextEditingController year;
  final TextEditingController month;
  final TextEditingController day;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _cell(year, 4, 'YYYY', context, true)),
        const _Dot(),
        Expanded(flex: 2, child: _cell(month, 2, 'MM', context, true)),
        const _Dot(),
        Expanded(flex: 2, child: _cell(day, 2, 'DD', context, false)),
      ],
    );
  }

  Widget _cell(TextEditingController c, int max, String hint, BuildContext context, bool advance) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: max,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          if (advance && v.length == max) FocusScope.of(context).nextFocus();
          onChanged();
        },
        style: const TextStyle(
          fontFamily: AppType.family,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.labelStrong,
        ),
        decoration: InputDecoration(
          counterText: '',
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.labelAlternative),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lineNormalNormal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.labelAlternative)),
      );
}

class _NoteArea extends StatelessWidget {
  const _NoteArea({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineNormalNormal),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLength: 200,
            maxLines: 3,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppColors.labelStrong,
            ),
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 6),
              border: InputBorder.none,
              hintText: '복용 중인 약, 알러지, 만성질환 등',
              hintStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.labelAlternative),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${controller.text.characters.length} / 200',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.22,
                  color: AppColors.labelAlternative,
                ).tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
