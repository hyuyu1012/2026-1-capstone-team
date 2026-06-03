import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../data/patient_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'new_patient_screen.dart';
import 'onboarding_widgets.dart';

/// "기존 환자 연결" destination — a 6-cell invite-code entry (the code-input UI
/// from PatientSetup.html `VersionB`). A full code advances to the app.
class ConnectCodeScreen extends StatefulWidget {
  const ConnectCodeScreen({super.key});

  @override
  State<ConnectCodeScreen> createState() => _ConnectCodeScreenState();
}

class _ConnectCodeScreenState extends State<ConnectCodeScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _busy = false;

  bool get _valid => _controllers.every((c) => c.text.isNotEmpty);

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    final ch = v.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    _controllers[i].text = ch.isEmpty ? '' : ch.characters.last;
    _controllers[i].selection = TextSelection.collapsed(offset: _controllers[i].text.length);
    if (_controllers[i].text.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() {});
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
      await context.read<PatientService>().linkByInviteCode(
            code: _code,
            guardianUid: user.uid,
          );
      if (!mounted) return;
      _backToRoot();
    } on PatientLinkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingTopBar(
              onBack: () => Navigator.pop(context),
              trailing: const StepChip(step: 1, total: 3),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'STEP 1 · 가족과 연결',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.72,
                                  color: AppColors.labelNeutral,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '초대 코드를 입력하세요',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.528,
                              height: 1.3,
                              color: AppColors.labelStrong,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '가족에게서 받은 6자리 코드를 입력하면\n같은 환자를 함께 돌볼 수 있어요.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: AppColors.labelNeutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [for (var i = 0; i < 6; i++) _codeCell(i)],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.labelNeutral),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '코드는 보호자 앱 → 설정 → 보호자 연결에서 확인할 수 있어요',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: AppColors.labelNeutral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: PrimaryButton(
                        label: _busy ? '연결 중…' : '환자와 연결',
                        enabled: _valid && !_busy,
                        onPressed: _submit,
                      ),
                    ),
                    const Spacer(),
                    // Secondary — new patient fallback
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
                    child: Row(
                      children: [
                        Expanded(child: Divider(height: 1, color: AppColors.lineNormalNeutral)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('또는',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.66,
                                color: AppColors.labelAlternative,
                              )),
                        ),
                        Expanded(child: Divider(height: 1, color: AppColors.lineNormalNeutral)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NewPatientScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lineNormalNormal),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.fillAlternative,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_alt_1_outlined, size: 20, color: AppColors.labelStrong),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('새 환자 등록',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.labelStrong)),
                                SizedBox(height: 1),
                                Text('가족 중 처음이라면 새로 시작',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.labelNeutral)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.labelAlternative),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextButton(
                        onPressed: _backToRoot,
                        child: const Text('나중에 설정',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.labelAlternative)),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _codeCell(int i) {
    final filled = _controllers[i].text.isNotEmpty;
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
        onChanged: (v) => _onChanged(i, v),
        style: const TextStyle(
          fontFamily: AppType.family,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.labelStrong,
        ),
        decoration: InputDecoration(
          counterText: '',
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: filled ? AppColors.primary : AppColors.lineNormalNormal),
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
