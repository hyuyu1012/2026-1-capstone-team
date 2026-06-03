import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capstone_ui/data/mock_care_repository.dart';
import 'package:capstone_ui/main.dart';

void main() {
  // Render at a phone-sized surface so the mobile layouts don't overflow the
  // default 800×600 test window.
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('app boots into the login screen', (tester) async {
    await tester.pumpWidget(AnsimCareApp(repository: MockCareRepository()));
    await tester.pump();

    // Login brand + social buttons are present.
    expect(find.text('안심 케어'), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('이메일로 시작하기'), findsOneWidget);
  });

  testWidgets('login advances to the branch screen', (tester) async {
    await tester.pumpWidget(AnsimCareApp(repository: MockCareRepository()));
    await tester.pump();

    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    // Branch (Version A) cards.
    expect(find.text('기존 환자 연결'), findsOneWidget);
    expect(find.text('새 환자 등록'), findsOneWidget);
  });

  testWidgets('branch screen does not overflow on a short screen', (tester) async {
    // A short device (an overflow here would be recorded as a test failure).
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(360, 560);

    await tester.pumpWidget(AnsimCareApp(repository: MockCareRepository()));
    await tester.pump();
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    // Cards still reachable (the content scrolls instead of overflowing).
    expect(find.text('기존 환자 연결'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
