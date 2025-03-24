import 'package:flutter/material.dart';
import 'package:idlefit/screens/game_home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/health_service.dart';
import 'services/object_box.dart';
import 'package:idlefit/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final objectBox = await ObjectBox.create();
  final healthService = HealthService();

  runApp(
    ProviderScope(
      overrides: [
        // Override the providers with initialized instances
        healthServiceProvider.overrideWithValue(healthService),
        objectBoxProvider.overrideWithValue(objectBox),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Idle Game',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      home: const GameInitializer(),
    );
  }
}

// A widget to initialize the game state before showing the home page
class GameInitializer extends ConsumerStatefulWidget {
  const GameInitializer({super.key});

  @override
  ConsumerState<GameInitializer> createState() => _GameInitializerState();
}

class _GameInitializerState extends ConsumerState<GameInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGameState();
  }

  Future<void> _initializeGameState() async {
    final objectBox = ref.read(objectBoxProvider);

    // Initialize the game state
    await ref.read(gameStateProvider.notifier).initialize(objectBox.store);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const GameHomePage();
  }
}
