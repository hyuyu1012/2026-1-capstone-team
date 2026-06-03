import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/patient_link_service.dart';
import 'data/schedule_service.dart';
import 'firebase_options.dart';
import 'models/patient.dart';
import 'screens/claim_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/schedule_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PatientApp());
}

class PatientApp extends StatelessWidget {
  const PatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<PatientLinkService>(create: (_) => PatientLinkService()),
        Provider<ScheduleService>(create: (_) => ScheduleService()),
      ],
      child: MaterialApp(
        title: '안심 케어 — 환자',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes by auth + claim state: signed-out → Login; signed-in but no claimed
/// patient → Claim; claimed → Schedule.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _PatientHome(uid: user.uid);
      },
    );
  }
}

class _PatientHome extends StatelessWidget {
  const _PatientHome({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final links = context.read<PatientLinkService>();
    return StreamBuilder<Patient?>(
      stream: links.myPatient(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final patient = snap.data;
        if (patient == null) return const ClaimScreen();
        return ScheduleScreen(patient: patient);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
