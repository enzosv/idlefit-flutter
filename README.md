# IdleFit

A Flutter idle game that integrates with health data.

## Recent Refactoring

### 1. GameState Refactoring

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

### 2. Riverpod Implementation

The codebase was further refactored to use Riverpod for state management:

1. Created domain-specific providers:
   - `CurrencyNotifier`: Manages all currency-related state and operations
   - `PlayerStatsNotifier`: Handles player statistics and background state
   - `CoinGeneratorNotifier`: Manages generators and their operations
   - `ShopItemNotifier`: Handles shop items and upgrades
   - `GameEngine`: Coordinates game logic and interactions between providers

2. Simplified widget code:
   - Widgets now directly access only the state they need
   - Reduced boilerplate with Riverpod's concise syntax
   - Better separation of UI and business logic
   - More testable components with clear dependencies

3. Improved architecture:
   - Single source of truth for each domain object
   - Clear ownership of state and operations
   - Reduced lines of code in UI components
   - More maintainable and scalable codebase

## Architecture

The game now follows a cleaner architecture:

- **Models**: Data entities stored in ObjectBox (Currency, PlayerStats, etc.)
- **Repositories**: Classes responsible for data persistence (CurrencyRepo, PlayerStatsRepo, etc.)
- **Providers**: State containers with business logic (CurrencyNotifier, GameEngine, etc.)
- **UI**: Flutter widgets that consume providers and render the game

## Benefits

This refactoring provides several benefits:

1. **Single Source of Truth**: All game data is stored in ObjectBox and managed by dedicated providers
2. **Simplified Dependencies**: Clear provider hierarchy with explicit dependencies
3. **Improved Testability**: Providers can be easily mocked and tested in isolation
4. **Better Code Organization**: Responsibilities are clearly defined and separated
5. **Reduced Complexity**: Widgets only access the state they need
6. **Easier Maintenance**: Changes to one part of the system have minimal impact on others
7. **Better Performance**: More granular rebuilds with Riverpod's selective state updates

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
