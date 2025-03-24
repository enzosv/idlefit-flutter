import 'package:idlefit/models/background_activity.dart';

class GameState {
  // Game state
  final bool _isPaused;
  final int _lastGenerated;
  final int _doubleCoinExpiry;

  // Services
  final BackgroundActivity _backgroundActivity;

  GameState({
    required bool isPaused,
    required int lastGenerated,
    required int doubleCoinExpiry,
    BackgroundActivity? backgroundActivity,
  }) : _isPaused = isPaused,
       _lastGenerated = lastGenerated,
       _doubleCoinExpiry = doubleCoinExpiry,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  bool get isPaused => _isPaused;
  int get lastGenerated => _lastGenerated;
  int get doubleCoinExpiry => _doubleCoinExpiry;
  BackgroundActivity get backgroundActivity => _backgroundActivity;

  /// **CopyWith (Immutable Updates)**
  GameState copyWith({
    bool? isPaused,
    int? lastGenerated,
    int? doubleCoinExpiry,
    BackgroundActivity? backgroundActivity,
  }) {
    return GameState(
      isPaused: isPaused ?? _isPaused,
      lastGenerated: lastGenerated ?? _lastGenerated,
      doubleCoinExpiry: doubleCoinExpiry ?? _doubleCoinExpiry,
      backgroundActivity: backgroundActivity ?? _backgroundActivity,
    );
  }

  /// **Convert to JSON (Persistence)**
  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': _lastGenerated,
      'doubleCoinExpiry': _doubleCoinExpiry,
    };
  }
}
