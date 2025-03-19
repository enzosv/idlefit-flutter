import 'dart:math';
import 'package:objectbox/objectbox.dart';

@Entity()
class CoinGenerator {
  @Id(assignable: true)
  int tier = 0;
  int count = 0;
  int level = 0;
  @Transient()
  String name = "";
  @Transient()
  double baseCost = 0;
  @Transient()
  double baseOutput = 0.0;
  @Transient()
  String description = "";

  CoinGenerator({
    required this.tier,
    this.count = 0,
    this.level = 0,
    this.name = '',
    this.baseCost = 0,
    this.baseOutput = 0,
    this.description = '',
  });

  // CoinGenerator copyWith({int? count, int? level, bool? isUnlocked}) {
  //   return CoinGenerator(
  //     tier: tier,
  //     count: count ?? this.count,
  //     level: level ?? this.level,
  //     isUnlocked: isUnlocked ?? this.isUnlocked,
  //     name: name,
  //     baseCost: baseCost,
  //     baseOutput: baseOutput,
  //     description: description,
  //   );
  // }

  int get maxLevel {
    return 10;
  }

  // Base cost formula: C_n = C_0 * 1.15^n
  double get cost {
    return baseCost.toDouble() * pow(1.15, count);
  }

  // Base CPS formula: CPS = CPS_0 * N
  double get output {
    return singleOutput * count;
  }

  double get singleOutput {
    return baseOutput * (1 + level * 0.1);
  }

  double outputAtLevel(int lvl) {
    return baseOutput * count * (1 + lvl * 0.1);
  }

  double get upgradeCost {
    return 1000.0 * (tier * 0.1) * (level + 1);
  }

  double get upgradeUnlockCost {
    return 1000; // Fixed space cost for unlocking upgrades
  }

  factory CoinGenerator.fromJson(Map<String, dynamic> json) {
    return CoinGenerator(
      tier: json['tier'],
      name: json['name'],
      baseCost: json['cost'].toDouble(),
      baseOutput: json['output'].toDouble(),
      description: json['description'],
    );
  }
}
