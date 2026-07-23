import 'package:flutter/material.dart';

import 'game/domain/game_state.dart';
import 'ui/game_screen.dart';

void main() {
  runApp(const PropertyShotApp());
}

class PropertyShotApp extends StatelessWidget {
  const PropertyShotApp({super.key, this.initialState});

  final GameState? initialState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '속성 한방',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B7A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: GameScreen(initialState: initialState),
    );
  }
}
