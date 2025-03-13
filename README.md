# IdleFit

A Flutter idle game that integrates with health data.

## Recent Refactoring

The GameState class was refactored to reduce its responsibilities. The changes made were:

1. Created a `PlayerStats` model to store game state data:
   - Moved game state tracking from SharedPreferences to ObjectBox
   - Implemented background state tracking in the model
   - Added methods for managing background state differences

2. Enhanced data persistence:
   - All persistence is now handled through ObjectBox
   - Created `PlayerStatsRepo` to manage player stat persistence
   - Removed dependency on `shared_preferences` package
   - Removed `storage_service.dart` in favor of direct ObjectBox access

3. Simplified `GameState` class:
   - Reduced responsibilities by delegating persistence to repositories
   - Better separation of concerns with player stats in their own model
   - More maintainable code structure with clearer separation of responsibilities

## Architecture

The game now follows a cleaner architecture:

- **Models**: Data entities stored in ObjectBox (Currency, PlayerStats, etc.)
- **Repositories**: Classes responsible for data persistence (CurrencyRepo, PlayerStatsRepo, etc.)
- **Services**: Game logic and state management (GameState, HealthService, etc.)
- **UI**: Flutter widgets for rendering the game

## Benefits

This refactoring provides several benefits:

1. **Single Source of Truth**: All game data is stored in ObjectBox
2. **Simplified Dependencies**: No need for multiple storage solutions
3. **Improved Testability**: Clearer separation of concerns makes testing easier
4. **Better Code Organization**: Responsibilities are more clearly defined
5. **Reduced Complexity**: GameState class has fewer responsibilities

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
