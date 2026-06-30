import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/connection/connection_provider.dart';
import 'features/layout/presentation/screens/room_screen.dart';

class ScreenShareApp extends ConsumerStatefulWidget {
  const ScreenShareApp({super.key});

  @override
  ConsumerState<ScreenShareApp> createState() => _ScreenShareAppState();
}

class _ScreenShareAppState extends ConsumerState<ScreenShareApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  void _initConnection() {
    if (_initialized) return;
    _initialized = true;
    ref.read(connectionManagerProvider).initialize();
  }

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
