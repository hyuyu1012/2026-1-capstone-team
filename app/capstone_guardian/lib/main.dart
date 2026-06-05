import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/care_repository.dart';
import 'data/daily_log_service.dart';
import 'data/mock_care_repository.dart';
import 'data/patient_service.dart';
import 'data/schedule_service.dart';
import 'firebase_options.dart';
import 'screens/onboarding/auth_gate.dart';
import 'state/care_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final CareRepository repository = MockCareRepository();
  runApp(AnsimCareApp(repository: repository));
}


class AnsimCareApp extends StatelessWidget {
  const AnsimCareApp({super.key, required this.repository});

  final CareRepository repository;

  @override
  Widget build(BuildContext context) {
    final patientService = PatientService();
    final scheduleService = ScheduleService();
    final dailyLogService = DailyLogService();
    return MultiProvider(
      providers: [
        Provider<CareRepository>.value(value: repository),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<PatientService>.value(value: patientService),
        Provider<ScheduleService>.value(value: scheduleService),
        Provider<DailyLogService>.value(value: dailyLogService),
        ChangeNotifierProvider(
          create: (_) => CareProvider(
              repository, patientService, scheduleService, dailyLogService),
        ),
      ],
      child: MaterialApp(
        title: '안심 케어',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
