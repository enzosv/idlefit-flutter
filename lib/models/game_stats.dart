import 'package:objectbox/objectbox.dart';
import 'package:idlefit/models/base_stats.dart';

@Entity()
class GameStats extends BaseStats {
  @Id()
  int id = 0;

  // Additional game-specific fields can be added here

  // Convert to a map (useful for display or exporting)
  @override
  Map<String, dynamic> toMap() {
    return toBaseMap();
  }
}
