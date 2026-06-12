import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/schedule_service.dart';
import '../models/schedule_item.dart';
import '../state/care_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ─── Shared constants / helpers (app.jsx) ────────────────────────────
const List<({String name, String time})> _mealPresets = [
  (name: '아침', time: '08:30'),
  (name: '점심', time: '12:30'),
  (name: '저녁', time: '18:30'),
];

const List<({String id, String label})> _dayOptions = [
  (id: 'mon', label: '월'),
  (id: 'tue', label: '화'),
  (id: 'wed', label: '수'),
  (id: 'thu', label: '목'),
  (id: 'fri', label: '금'),
  (id: 'sat', label: '토'),
  (id: 'sun', label: '일'),
];
const List<String> _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri'];

/// One row in the 복용 식사 picker. Built at runtime from the patient's
/// registered meal schedules (see [_MedRegisterSheetState._registeredMeals]).
typedef MealRef = ({String id, String name, String time});

// `sign` is the direction relative to the meal (식전 = before = -1, 식후 = +1);
// the magnitude (minutes) is chosen by the guardian per registration.
const List<({String id, String label, int sign})> _timingOptions = [
  (id: 'before', label: '식전', sign: -1),
  (id: 'after', label: '식후', sign: 1),
];

/// Allowed range / step for the editable 식전·식후 offset (minutes).
const int _offsetMinValue = 0;
const int _offsetMaxValue = 120;
const int _offsetStep = 1;

/// Period-of-day label for a "HH:mm" time.
String _periodOf(String time) {
  final h = int.parse(time.split(':')[0]);
  if (h < 11) return '아침';
  if (h < 14) return '점심';
  if (h < 17) return '오후';
  if (h < 21) return '저녁';
  return '밤';
}

/// Add minutes to a "HH:mm" time, wrapping around 24h.
String _addMinutes(String time, int mins) {
  final parts = time.split(':');
  final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + mins + 24 * 60;
  final hh = ((total % (24 * 60)) ~/ 60).toString().padLeft(2, '0');
  final mm = (total % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Writes the registered schedule item(s) to the bound patient's Firestore
/// `schedules` subcollection, then closes the sheet. Shows a guard message if
/// no patient is connected yet.
Future<void> _saveSchedules(
  BuildContext context,
  List<({ScheduleKind kind, String name, String? dose, String time, List<String> days, String? mealRelation, String? mealId})> items,
) async {
  final patient = context.read<CareProvider>().patient;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (patient == null) {
    messenger.showSnackBar(const SnackBar(
      content: Text('먼저 환자를 연결한 뒤 일정을 등록할 수 있어요.'),
    ));
    return;
  }
  final service = context.read<ScheduleService>();
  try {
    for (final it in items) {
      await service.addSchedule(
        patient.id,
        kind: it.kind,
        name: it.name,
        dose: it.dose,
        time: it.time,
        days: it.days,
        mealRelation: it.mealRelation,
        mealId: it.mealId,
      );
    }
    messenger.showSnackBar(SnackBar(
      content: Text('일정 ${items.length}건을 저장했어요. 환자 앱에서 확인할 수 있어요.'),
    ));
    navigator.pop();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('저장 실패: $e')));
  }
}

// ─── Meal register sheet ─────────────────────────────────────────────
class MealRegisterSheet extends StatefulWidget {
  const MealRegisterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        builder: (_) => const MealRegisterSheet(),
      );

  @override
  State<MealRegisterSheet> createState() => _MealRegisterSheetState();
}

class _MealRegisterSheetState extends State<MealRegisterSheet> {
  final _name = TextEditingController();
  String _time = '08:30';
  final Set<String> _days = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};

  bool get _everyDay => _days.length == 7;
  bool get _isWeekday => _days.length == 5 && _weekdays.every(_days.contains);
  bool get _canSave => _name.text.trim().isNotEmpty && _days.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) {
      setState(() => _time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: '식사 일정 등록',
      canSave: _canSave,
      onSave: () => _saveSchedules(context, [
        (
          kind: ScheduleKind.meal,
          name: _name.text.trim(),
          dose: null,
          time: _time,
          days: _days.toList(),
          mealRelation: null,
          mealId: null,
        ),
      ]),
      children: [
        // 식사 이름
        const FieldLabel('식사 이름'),
        SheetTextField(controller: _name, placeholder: '예: 아침', onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in _mealPresets)
              _PresetChip(
                label: p.name,
                active: _name.text == p.name,
                onTap: () => setState(() {
                  _name.text = p.name;
                  _time = p.time;
                }),
              ),
          ],
        ),
        const SizedBox(height: 22),

        // 시간
        const FieldLabel('시간'),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lineNormalNormal),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _time,
                    style: const TextStyle(
                      fontFamily: AppType.displayFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.216,
                      color: AppColors.labelStrong,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  _periodOf(_time),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.23,
                    color: AppColors.labelAlternative,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // 요일
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const FieldLabel('요일', inline: true),
            Row(
              children: [
                QuickBtn(label: '매일', active: _everyDay, onTap: () => setState(() {
                  _days
                    ..clear()
                    ..addAll(_dayOptions.map((d) => d.id));
                })),
                const SizedBox(width: 6),
                QuickBtn(label: '평일', active: _isWeekday, onTap: () => setState(() {
                  _days
                    ..clear()
                    ..addAll(_weekdays);
                })),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _dayOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _DayCell(
                day: _dayOptions[i],
                active: _days.contains(_dayOptions[i].id),
                onTap: () => setState(() {
                  final id = _dayOptions[i].id;
                  _days.contains(id) ? _days.remove(id) : _days.add(id);
                }),
              )),
            ],
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color.fromRGBO(0, 102, 255, 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.primary : AppColors.lineNormalNormal),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.06,
            color: active ? AppColors.primary : AppColors.labelNeutral,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.active, required this.onTap});
  final ({String id, String label}) day;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSun = day.id == 'sun';
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.fillAlternative,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.22), blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(
            day.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.065,
              color: active
                  ? Colors.white
                  : isSun
                      ? AppColors.statusCautionary
                      : AppColors.labelNeutral,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Med register sheet ──────────────────────────────────────────────
class MedRegisterSheet extends StatefulWidget {
  const MedRegisterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        builder: (_) => const MedRegisterSheet(),
      );

  @override
  State<MedRegisterSheet> createState() => _MedRegisterSheetState();
}

class _MedRegisterSheetState extends State<MedRegisterSheet> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final Set<String> _meals = {};
  final Set<String> _timings = {'after'};
  int _offsetMin = 30; // 식사 기준 ±몇 분에 복용 알림을 줄지 (사용자 조절)

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _meals.isNotEmpty && _timings.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  /// The patient's registered meal schedules, in time order — the source for
  /// the 복용 식사 options (previously hard-coded mock data). Empty until a
  /// meal is registered for the bound patient.
  List<MealRef> _registeredMeals(BuildContext context) => context
      .watch<CareProvider>()
      .todayItems
      .where((i) => i.kind == ScheduleKind.meal)
      .map((i) => (id: i.id, name: i.name, time: i.time))
      .toList();

  List<({String label, String time, String mealRelation, String mealId})>
      _previewFor(List<MealRef> meals) {
    final out = <({String label, String time, String mealRelation, String mealId})>[];
    for (final m in meals) {
      if (!_meals.contains(m.id)) continue;
      for (final t in _timingOptions) {
        if (!_timings.contains(t.id)) continue;
        out.add((
          label: '${m.name} ${t.label} $_offsetMin분',
          time: _addMinutes(m.time, t.sign * _offsetMin),
          mealRelation: t.id, // 'before' | 'after' — 환자 앱 연동용
          mealId: m.id, // 어느 식사에 붙은 약인지(식후 감지 트리거 대상)
        ));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final meals = _registeredMeals(context);
    final preview = _previewFor(meals);
    return SheetShell(
      title: '복용 약 등록',
      canSave: _canSave,
      onSave: () => _saveSchedules(
        context,
        [
          for (final line in preview)
            (
              kind: ScheduleKind.med,
              name: _name.text.trim(),
              dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
              time: line.time,
              days: const <String>[],
              mealRelation: line.mealRelation,
              mealId: line.mealId,
            ),
        ],
      ),
      children: [
        const FieldLabel('약 이름'),
        SheetTextField(controller: _name, placeholder: '예: 암로디핀', onChanged: (_) => setState(() {})),
        const SizedBox(height: 18),

        const FieldLabel('용량'),
        SheetTextField(controller: _dose, placeholder: '예: 5mg 1정', onChanged: (_) => setState(() {})),
        const SizedBox(height: 22),

        // 복용 식사 — 환자에게 등록된 실제 식사 일정에서 가져온다.
        const FieldLabel('복용 식사'),
        if (meals.isEmpty)
          const _NoMealsNotice()
        else
          for (var i = 0; i < meals.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _MealOption(
              meal: meals[i],
              active: _meals.contains(meals[i].id),
              onTap: () => setState(() {
                final id = meals[i].id;
                _meals.contains(id) ? _meals.remove(id) : _meals.add(id);
              }),
            ),
          ],
        const SizedBox(height: 8),
        Text(
          meals.isEmpty
              ? '먼저 식사 일정을 등록하면 그 시간에 맞춰 복용 알림을 보낼 수 있어요.'
              : '등록된 식사 일정에 맞춰 복용 알림을 보냅니다.',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.022,
            color: AppColors.labelAlternative,
          ),
        ),
        const SizedBox(height: 22),

        // 복용 시점
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const FieldLabel('복용 시점', inline: true),
            _MinuteStepper(
              minutes: _offsetMin,
              onChanged: (v) => setState(() => _offsetMin = v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _timingOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _TimingOption(
                option: _timingOptions[i],
                minutes: _offsetMin,
                active: _timings.contains(_timingOptions[i].id),
                onTap: () => setState(() {
                  final id = _timingOptions[i].id;
                  _timings.contains(id) ? _timings.remove(id) : _timings.add(id);
                }),
              )),
            ],
          ],
        ),
        const SizedBox(height: 18),

        // 알림 시각 미리보기
        if (preview.isNotEmpty) ...[
          _PreviewBox(lines: [
            for (final l in preview) (label: l.label, time: l.time),
          ]),
          const SizedBox(height: 22),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

/// Shown in place of the meal options when the patient has no registered meal
/// schedule yet — med timing is anchored to meals, so there's nothing to pick.
class _NoMealsNotice extends StatelessWidget {
  const _NoMealsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.fillAlternative,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineNormalNormal),
      ),
      child: const Row(
        children: [
          Icon(Icons.restaurant_outlined, size: 18, color: AppColors.labelAlternative),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '등록된 식사 일정이 없어요.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.065,
                color: AppColors.labelNeutral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealOption extends StatelessWidget {
  const _MealOption({required this.meal, required this.active, required this.onTap});
  final MealRef meal;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary04 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.lineNormalNormal),
        ),
        child: Row(
          children: [
            SquareCheck(checked: active),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                meal.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.07,
                  color: AppColors.labelStrong,
                ),
              ),
            ),
            Text(
              meal.time,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.0625,
                color: AppColors.labelAlternative,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingOption extends StatelessWidget {
  const _TimingOption({
    required this.option,
    required this.minutes,
    required this.active,
    required this.onTap,
  });
  final ({String id, String label, int sign}) option;
  final int minutes;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary04 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.lineNormalNormal),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SquareCheck(checked: active, size: 20),
            const SizedBox(width: 8),
            Text(
              '${option.label} $minutes분',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.07,
                color: active ? AppColors.labelStrong : AppColors.labelNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline − / value / + control for the 식전·식후 offset minutes. Clamps to
/// [_offsetMinValue].._offsetMaxValue in [_offsetStep] increments.
class _MinuteStepper extends StatelessWidget {
  const _MinuteStepper({required this.minutes, required this.onChanged});
  final int minutes;
  final ValueChanged<int> onChanged;

  /// Tap the value to type an exact minute (1-min precision without 100 taps).
  Future<void> _promptMinutes(BuildContext context) async {
    final controller = TextEditingController(text: '$minutes');
    final entered = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('복용 간격 (분)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: '분',
            helperText: '$_offsetMinValue ~ $_offsetMaxValue분',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v.trim())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (entered != null) {
      onChanged(entered.clamp(_offsetMinValue, _offsetMaxValue));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDec = minutes > _offsetMinValue;
    final canInc = minutes < _offsetMaxValue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lineNormalNormal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            enabled: canDec,
            onTap: () => onChanged((minutes - _offsetStep).clamp(_offsetMinValue, _offsetMaxValue)),
          ),
          GestureDetector(
            onTap: () => _promptMinutes(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 52),
              alignment: Alignment.center,
              child: Text(
                '$minutes분',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.065,
                  color: AppColors.labelStrong,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            enabled: canInc,
            onTap: () => onChanged((minutes + _offsetStep).clamp(_offsetMinValue, _offsetMaxValue)),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary08 : AppColors.fillAlternative,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.labelAlternative,
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.lines});
  final List<({String label, String time})> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary04,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '알림 시각',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88, // 0.08em
                color: AppColors.primary,
              ),
            ),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.065,
                        color: AppColors.labelStrong,
                      ),
                    ),
                  ),
                  Text(
                    line.time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFeatures: [FontFeature.tabularFigures()],
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

// ─── Schedule edit sheet (long-press → 편집) ─────────────────────────
/// Edits a single existing schedule item's name / time / dose. Unlike the
/// register sheets (which fan one med out across meals × timings), this maps
/// 1:1 to a stored doc — the only shape you can meaningfully edit after the
/// fact. Days aren't carried on [ScheduleItem], so they're left as-is.
class ScheduleEditSheet extends StatefulWidget {
  const ScheduleEditSheet({super.key, required this.item});

  final ScheduleItem item;

  static Future<void> show(BuildContext context, ScheduleItem item) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        builder: (_) => ScheduleEditSheet(item: item),
      );

  @override
  State<ScheduleEditSheet> createState() => _ScheduleEditSheetState();
}

class _ScheduleEditSheetState extends State<ScheduleEditSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item.name);
  late final TextEditingController _dose =
      TextEditingController(text: widget.item.dose ?? '');
  late String _time = widget.item.time;

  bool get _isMed => widget.item.kind == ScheduleKind.med;
  bool get _canSave => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) {
      setState(() => _time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final dose = _isMed && _dose.text.trim().isNotEmpty ? _dose.text.trim() : null;
    try {
      await context.read<CareProvider>().updateItem(
            widget.item.id,
            name: _name.text.trim(),
            time: _time,
            dose: dose,
          );
      messenger.showSnackBar(const SnackBar(content: Text('일정을 수정했어요.')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: _isMed ? '복용 약 수정' : '식사 일정 수정',
      canSave: _canSave,
      onSave: _save,
      children: [
        FieldLabel(_isMed ? '약 이름' : '식사 이름'),
        SheetTextField(controller: _name, onChanged: (_) => setState(() {})),
        const SizedBox(height: 18),

        if (_isMed) ...[
          const FieldLabel('용량'),
          SheetTextField(controller: _dose, placeholder: '예: 5mg 1정'),
          const SizedBox(height: 18),
        ],

        const FieldLabel('시간'),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lineNormalNormal),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _time,
                    style: const TextStyle(
                      fontFamily: AppType.displayFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.216,
                      color: AppColors.labelStrong,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  _periodOf(_time),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.23,
                    color: AppColors.labelAlternative,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Shared sheet pieces ─────────────────────────────────────────────

/// The bottom-sheet chrome: drag handle, header (title + 취소), scrollable
/// body, and a pinned 저장 CTA. Caps height at 92% and pads for the keyboard.
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    required this.title,
    required this.children,
    required this.canSave,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.lineNormalNormal,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppType.displayFamily,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.342,
                      color: AppColors.labelStrong,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelNeutral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              margin: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineNormalNeutral)),
              ),
              child: GestureDetector(
                onTap: canSave ? onSave : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canSave ? AppColors.primary : AppColors.fillAlternative,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: canSave
                        ? const [BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.24), blurRadius: 14, offset: Offset(0, 6))]
                        : null,
                  ),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.075,
                      color: canSave ? Colors.white : AppColors.labelAlternative,
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
}

/// Small uppercase caps field label.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.inline = false});
  final String text;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: inline ? 0 : 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.15, // 0.1em
          color: AppColors.labelNeutral,
        ),
      ),
    );
  }
}

/// Bordered text input matching the sheet spec (radius 12, focus → primary).
class SheetTextField extends StatefulWidget {
  const SheetTextField({super.key, required this.controller, this.placeholder, this.onChanged});
  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;

  @override
  State<SheetTextField> createState() => _SheetTextFieldState();
}

class _SheetTextFieldState extends State<SheetTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _focus.hasFocus ? AppColors.primary : AppColors.lineNormalNormal),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.07,
          color: AppColors.labelStrong,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.labelAlternative,
          ),
        ),
      ),
    );
  }
}

/// Quick-select pill (매일 / 평일).
class QuickBtn extends StatelessWidget {
  const QuickBtn({super.key, required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary08 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.primary : AppColors.lineNormalNormal),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.055,
            color: active ? AppColors.primary : AppColors.labelNeutral,
          ),
        ),
      ),
    );
  }
}

/// Square (radius 6) checkbox — distinguishes register sheets from the round
/// schedule checkboxes.
class SquareCheck extends StatelessWidget {
  const SquareCheck({super.key, required this.checked, this.size = 22});
  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: checked ? null : Border.all(color: AppColors.lineNormalNormal, width: 1.5),
      ),
      child: checked ? Icon(Icons.check_rounded, size: size * 0.64, color: Colors.white) : null,
    );
  }
}

