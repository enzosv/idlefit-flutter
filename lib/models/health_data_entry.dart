import 'package:objectbox/objectbox.dart';

@Entity()
class HealthDataEntry {
  int id = 0; // ObjectBox automatically assigns a unique ID
  @Index()
  int timestamp; // Store as milliseconds since epoch
  int duration;
  int recordedAt;
  double value;
  String type; // e.g., "STEPS", "ACTIVE_ENERGY_BURNED"

  @Unique(onConflict: ConflictStrategy.fail)
  String get uniqueKey => '$type|$timestamp';

  HealthDataEntry({
    required this.timestamp,
    required this.duration,
    required this.value,
    required this.type,
    int? recordedAt,
    // this.recordedAt = DateTime.now().millisecondsSinceEpoch,
  }) : recordedAt = recordedAt ?? DateTime.now().millisecondsSinceEpoch;
}
