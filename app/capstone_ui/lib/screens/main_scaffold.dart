import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/care_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'home/home_screen.dart';
import 'records/records_screen.dart';
import 'register_sheet.dart';
import 'register_sheets.dart';
import 'settings/settings_screen.dart';
import 'stats/stats_screen.dart';

/// The 4-tab shell: top bar, the active tab, and the notched bottom nav with a
/// center FAB (app.jsx `App` + `BottomNav`).
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tab = 0;

  static const _tabs = [
    HomeScreen(),
    RecordsScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loading = context.select<CareProvider, bool>((c) => c.loading);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CareTopBar(onBell: () {}),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : IndexedStack(index: _tab, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        active: _tab,
        onSelect: (i) => setState(() => _tab = i),
        onFab: _openRegisterMenu,
      ),
    );
  }

  /// FAB → first menu, then the chosen registration sheet.
  Future<void> _openRegisterMenu() async {
    final choice = await RegisterSheet.show(context);
    if (!mounted) return;
    switch (choice) {
      case 'med':
        await MedRegisterSheet.show(context);
      case 'meal':
        await MealRegisterSheet.show(context);
    }
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.active, required this.onSelect, required this.onFab});

  final int active; // 0 home · 1 records · 2 stats · 3 settings
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, '홈'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, '기록'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, '통계'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 84 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Notched white background.
          Positioned.fill(
            child: CustomPaint(painter: _NavBackgroundPainter()),
          ),
          // 5 slots (FAB occupies the middle).
          Padding(
            padding: EdgeInsets.only(top: 18, bottom: bottomInset),
            child: Row(
              children: [
                _slot(0), // home
                _slot(1), // records
                _fabSlot(),
                _slot(2), // stats
                _slot(3), // settings
              ],
            ),
          ),
          // Floating FAB above the notch.
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onFab,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.28), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slot(int index) {
    final item = _items[index];
    final isActive = active == index;
    final color = isActive ? AppColors.primary : AppColors.labelAlternative;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? item.activeIcon : item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.21,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fabSlot() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onFab,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 36),
            Text(
              '등록',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.42,
                color: AppColors.labelAlternative,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the bottom-nav surface: a flat bar with a rounded notch carved out
/// for the FAB (path from shared.jsx `BottomNav`, viewBox 360×84).
class _NavBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360;
    canvas.save();
    canvas.scale(sx, 1);

    final path = Path()
      ..moveTo(0, 12)
      ..lineTo(140, 12)
      ..cubicTo(148, 12, 152, 16, 154, 22)
      ..cubicTo(158, 38, 168, 48, 180, 48)
      ..cubicTo(192, 48, 202, 38, 206, 22)
      ..cubicTo(208, 16, 212, 12, 220, 12)
      ..lineTo(360, 12)
      ..lineTo(360, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Soft top shadow.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Fill + hairline stroke.
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.lineNav,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavBackgroundPainter oldDelegate) => false;
}
