import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/layout/presentation/screens/room_screen.dart';

class ScreenShareApp extends StatelessWidget {
  const ScreenShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RoomScreen(),
    );
  }
}
