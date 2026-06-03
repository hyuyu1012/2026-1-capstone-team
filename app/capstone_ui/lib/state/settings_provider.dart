import 'package:flutter/foundation.dart';

/// Local UI state for the 설정 tab (toggles + font-size + dark mode). Purely
/// in-memory for now — matches the prototype, which doesn't persist these.
class SettingsProvider extends ChangeNotifier {
  // 알림 toggles
  bool reminder = true;
  bool missedAlert = true;
  bool guardianPush = true;
  bool sound = true;

  // 화면
  bool darkMode = false;
  int fontSizeIndex = 2; // 0 작게 · 1 보통 · 2 크게 · 3 매우 크게

  static const List<String> fontSizeLabels = ['작게', '보통', '크게', '매우 크게'];

  void setReminder(bool v) => _set(() => reminder = v);
  void setMissedAlert(bool v) => _set(() => missedAlert = v);
  void setGuardianPush(bool v) => _set(() => guardianPush = v);
  void setSound(bool v) => _set(() => sound = v);
  void setDarkMode(bool v) => _set(() => darkMode = v);
  void setFontSizeIndex(int i) => _set(() => fontSizeIndex = i);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }
}
