import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No-op, пока Supabase-проект не настроен (см. docs/SUPABASE_SETUP.md).
  await AuthService.init();
  runApp(const BreathinApp());
}
