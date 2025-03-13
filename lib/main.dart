import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import 'package:idlefit/providers/objectbox_provider.dart';
import 'services/health_service.dart';
import 'screens/main_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/shop_screen.dart';
import 'services/object_box.dart';
import 'widgets/background_earnings_popup.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

// Service providers
final objectBoxProvider = Provider<ObjectBox>((ref) {
  // We'll manually trigger the initialization in GameHomePage
  throw UnimplementedError('ObjectBox must be initialized asynchronously');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

// Provider to handle initialization of services
final servicesInitializerProvider = FutureProvider<bool>((ref) async {
  print("Initializing all services via provider");

  // Initialize ObjectBox
  final objectBox = await ObjectBox.create();
  ref.container.updateOverrides([
    objectBoxProvider.overrideWithValue(objectBox),
  ]);

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize ad service
  AdService.initialize();

  return true;
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print("App starting - initializing via Riverpod");

  runApp(const ProviderScope(child: MyApp()));
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
      ),
      themeMode: ThemeMode.dark,
      home: const InitializationScreen(),
    );
  }
}

// Screen to handle initialization before showing the main app
class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationState = ref.watch(servicesInitializerProvider);

    return initializationState.when(
      data: (_) => const GameHomePage(),
      loading:
          () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing game...'),
                ],
              ),
            ),
          ),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error initializing: $error'),
                  ElevatedButton(
                    onPressed: () => ref.refresh(servicesInitializerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class GameHomePage extends ConsumerStatefulWidget {
  const GameHomePage({super.key});

  @override
  ConsumerState<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends ConsumerState<GameHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 1; // Start with main screen

  final List<Widget> _screens = [
    const StatsScreen(),
    const MainScreen(),
    const ShopScreen(),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("App lifecycle state changed: $state");
    if (![
      AppLifecycleState.paused,
      AppLifecycleState.resumed,
    ].contains(state)) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      // going to background
      print("App going to background - pausing game engine");
      ref.read(gameEngineProvider.notifier).setPaused(true);
      ref.read(gameEngineProvider.notifier).saveBackgroundState();
      return;
    }

    // going to foreground
    print("App returning to foreground - resuming game engine");
    final healthService = ref.read(healthServiceProvider);
    await healthService.syncHealthData(
      ref.read(objectBoxProvider),
      ref.read(gameEngineProvider.notifier),
    );

    NotificationService.cancelAllNotifications();

    // Start the game engine
    print("Starting game engine after returning to foreground");
    ref.read(gameEngineProvider.notifier).setPaused(false);

    await Future.delayed(const Duration(seconds: 1)).then((_) {
      if (!mounted) {
        return;
      }

      final earnings =
          ref.read(gameEngineProvider.notifier).getBackgroundDifferences();
      if ((earnings['energy_spent'] ?? 0) > 60000) {
        // do not show popup if energy spent is less than 1 minute
        showDialog(
          context: context,
          builder: (context) => BackgroundEarningsPopup(earnings: earnings),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    print("GameHomePage initializing");
    WidgetsBinding.instance.addObserver(this);

    // We need to wait until after the first build before we can safely access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGameEngine();
    });
  }

  Future<void> _initializeGameEngine() async {
    print("Initializing game engine (post-frame)");

    // First pause the game engine
    print("Setting initial game state to paused");
    ref.read(gameEngineProvider.notifier).setPaused(true);

    // Force a watch on the gameTickProvider to ensure it's created and initialized
    ref.listen(gameTickProvider, (previous, next) {
      print("GameTickProvider state changed");
    });

    // Initialize health data and then start the game
    print("Initializing health data");
    final healthService = ref.read(healthServiceProvider);
    await healthService.initialize();

    print("Health data initialized, syncing health data");
    await healthService.syncHealthData(
      ref.read(objectBoxProvider),
      ref.read(gameEngineProvider.notifier),
    );

    // Important: Start the game engine
    print("Starting game engine after health data sync");
    ref.read(gameEngineProvider.notifier).setPaused(false);

    // Force a check of the game engine state
    final isPaused = ref.read(gameEngineProvider);
    print("Game engine paused state after initialization: $isPaused");

    // Explicitly watch the gameTickProvider to ensure it's activated
    ref
        .read(gameTickProvider.stream)
        .listen(
          (_) => print("Main screen received game tick"),
          onError: (e) => print("Error in game tick stream: $e"),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Monitor game engine state in the build method
    final isPaused = ref.watch(gameEngineProvider);
    print("Game engine paused state during build: $isPaused");

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Constants.primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("GameHomePage disposing");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
