import 'dart:math';
import 'package:objectbox/objectbox.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/services/object_box.dart';

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
    this.name = '',
    this.baseCost = 0,
    this.baseOutput = 0,
    this.description = '',
  });

  // Base cost formula: C_n = C_0 * 1.15^n
  double get cost {
    return baseCost.toDouble() * pow(1.15, count);
  }

  // Base CPS formula: CPS = CPS_0 * N
  double get output {
    return baseOutput * count * pow(2, level);
  }

  double upgradeCost(BigInt baseCost, int level) {
    const List<int> multipliers = [
      100,
      500,
      5000,
      50000,
      500000,
      5000000,
      50000000,
      500000000,
      5000000000,
      50000000000,
    ];

    if (level < 1 || level > multipliers.length) {
      throw ArgumentError("Tier must be between 1 and ${multipliers.length}");
    }

    return baseCost.toDouble() * multipliers[level - 1];
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

Future<List<CoinGenerator>> parseCoinGenerators(
  String jsonString,
  Store objectBoxService,
) async {
  final String response = await rootBundle.loadString(jsonString);
  final List<dynamic> data = jsonDecode(response);

  // TODO: load at same time as json
  final generatorStore = objectBoxService.box<CoinGenerator>();
  // final stored = generatorStore.getAll();
  // return stored.map((generator) {
  //   final d = data.firstWhere((item) => item['tier'] == generator.id);
  //   if (d == null) {
  //     return generator;
  //   }
  //   final jsonData = CoinGenerator.fromJson(d);
  //   generator.name = jsonData.name;
  //   generator.description = jsonData.description;
  //   generator.baseCost = jsonData.baseCost;
  //   generator.baseOutput = jsonData.baseCost;
  //   return generator;
  // }).toList();
  return data.map((item) {
    CoinGenerator generator = CoinGenerator.fromJson(item);
    final stored = generatorStore.get(generator.tier);
    if (stored == null) {
      return generator;
    }
    generator.count = stored.count;
    generator.level = stored.level;
    return generator;
  }).toList();
}

// final List<CoinGenerator> coinGenerators = [
//   CoinGenerator(1, "Training Shoes", BigInt.from(10), 0.07),
//   CoinGenerator(2, "Training Buddy", BigInt.from(80), 0.8),
//   CoinGenerator(3, "Supplements", BigInt.from(900), 6.5),
//   CoinGenerator(4, "Bicycle", BigInt.from(10_000), 40),
//   CoinGenerator(5, "Gym Membership", BigInt.from(110_000), 220),
//   CoinGenerator(6, "Fitness Tracker", BigInt.from(1_200_000), 1_200),
//   CoinGenerator(7, "Group Exercise Class", BigInt.from(17_000_000), 6_800),
//   CoinGenerator(8, "Personal Trainer", BigInt.from(280_000_000), 37_500),
//   CoinGenerator(9, "Home Gym Setup", BigInt.from(4_200_000_000), 220_000),
//   CoinGenerator(
//     10,
//     "Marathon Training",
//     BigInt.from(61_000_000_000),
//     1_300_000,
//   ),
//   CoinGenerator(
//     11,
//     "Strength Training",
//     BigInt.from(800_000_000_000),
//     8_000_000,
//   ),
//   CoinGenerator(
//     12,
//     "Peak Human Performance",
//     BigInt.from(11_000_000_000_000),
//     50_000_000,
//   ),
//   CoinGenerator(
//     13,
//     "World Record Achievements",
//     BigInt.from(130_000_000_000_000),
//     320_000_000,
//   ),
//   CoinGenerator(
//     14,
//     "Olympic Glory",
//     BigInt.from(1_600_000_000_000_000),
//     2_200_000_000,
//   ),
//   CoinGenerator(
//     15,
//     "Hyper-Optimized Training",
//     BigInt.from(20_000_000_000_000_000),
//     16_500_000_000,
//   ),
//   CoinGenerator(
//     16,
//     "Biomechanical Augmentations",
//     BigInt.from(230_000_000_000_000_000),
//     115_000_000_000,
//   ),
//   CoinGenerator(
//     17,
//     "Gene Editing for Performance",
//     BigInt.from(5_500_000_000_000_000_000),
//     900_000_000_000,
//   ),
//   CoinGenerator(
//     18,
//     "Post-Human Evolution",
//     BigInt.parse('93000000000000000000'),
//     6_500_000_000_000,
//   ),
//   CoinGenerator(
//     19,
//     "Longevity Research",
//     BigInt.parse('1500000000000000000000'),
//     50_500_000_000_000,
//   ),
//   CoinGenerator(
//     20,
//     "Immortality Project",
//     BigInt.parse('25000000000000000000000'),
//     420_000_000_000_000,
//   ),
// ];
