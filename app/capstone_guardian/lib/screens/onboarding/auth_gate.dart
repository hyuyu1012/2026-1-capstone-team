import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../state/care_provider.dart';
import '../main_scaffold.dart';
import 'branch_screen.dart';
import 'login_screen.dart';

/// Root router. Three states for a signed-in user:
///   • [CareProvider.patientLoading] — first Firestore tick hasn't arrived
///   • patient == null — onboarding: pick connect-by-code or register new
///   • patient != null — main app
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScaffold();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _SignedInGate(uid: user.uid);
      },
    );
  }
}

class _SignedInGate extends StatefulWidget {
  const _SignedInGate({required this.uid});
  final String uid;

  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  @override
  void initState() {
    super.initState();
    context.read<CareProvider>().bindToGuardian(widget.uid);
  }

  @override
  void didUpdateWidget(_SignedInGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      context.read<CareProvider>().bindToGuardian(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CareProvider>();
    if (care.patientLoading) return const _SplashScaffold();
    return care.patient == null ? const BranchScreen() : const MainScaffold();
  }
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
}
