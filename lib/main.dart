import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/game_state.dart';
import 'screens/main_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/shop_screen.dart';
import 'services/health_service.dart';
import 'services/storage_service.dart';
import 'services/object_box.dart';
import 'widgets/background_earnings_popup.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final healthService = HealthService();
  final objectBox = await ObjectBox.create();

  // Load game state
  final gameState = GameState();
  await gameState.initialize(storageService, objectBox.store);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider.value(value: healthService),
        Provider.value(value: storageService),
        Provider.value(value: objectBox),
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
      home: const GameHomePage(),
    );
  }
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  _GameHomePageState createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 1; // Start with main screen

  final List<Widget> _screens = [
    const StatsScreen(),
    const MainScreen(),
    const ShopScreen(),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("new state: $state");
    if (![
      AppLifecycleState.paused,
      AppLifecycleState.resumed,
    ].contains(state)) {
      return;
    }
    final gameState = Provider.of<GameState>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      // going to background
      gameState.isPaused = true;
      gameState.save();
      gameState.saveBackgroundState();
      return;
    }
    // going to foreground
    final healthService = Provider.of<HealthService>(context, listen: false);
    final objectBoxService = Provider.of<ObjectBox>(context, listen: false);
    await healthService.syncHealthData(objectBoxService, gameState);
    gameState.isPaused = false;
    await Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!mounted) {
        return;
      }
      final earnings = gameState.getBackgroundDifferences();
      if (earnings.values.any((value) => value > 0)) {
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
    // Initialize health data
    final healthService = Provider.of<HealthService>(context, listen: false);
    final gameState = Provider.of<GameState>(context, listen: false);
    final objectBoxService = Provider.of<ObjectBox>(context, listen: false);
    gameState.isPaused = true;
    // Initialize ads
    AdService.initialize();
    healthService.initialize().then((_) async {
      await healthService.syncHealthData(objectBoxService, gameState);
      gameState.isPaused = false;
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
