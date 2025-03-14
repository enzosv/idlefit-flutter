import 'package:flutter/material.dart';
import 'package:idlefit/screens/game_home_screen.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/health_service.dart';
import 'services/storage_service.dart';
import 'services/object_box.dart';
import 'services/notification_service.dart';

// Create providers for our services
final healthServiceProvider = Provider<HealthService>((ref) => HealthService());
final objectBoxProvider = Provider<ObjectBox>(
  (ref) => throw UnimplementedError('Initialize in main'),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('Initialize in main'),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final healthService = HealthService();
  final objectBox = await ObjectBox.create();

  // Initialize notifications
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Override the providers with initialized instances
        healthServiceProvider.overrideWithValue(healthService),
        objectBoxProvider.overrideWithValue(objectBox),
        storageServiceProvider.overrideWithValue(storageService),
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
    final storageService = ref.read(storageServiceProvider);
    final objectBox = ref.read(objectBoxProvider);

    // Initialize the game state
    await ref
        .read(gameStateProvider.notifier)
        .initialize(storageService, objectBox.store);

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
