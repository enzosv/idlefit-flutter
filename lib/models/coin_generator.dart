import 'dart:math';
import 'package:objectbox/objectbox.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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

  double get tapOutput {
    return baseOutput * pow(2, level);
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

class CoinGeneratorRepo {
  final Box<CoinGenerator> box;
  CoinGeneratorRepo({required this.box});

  Future<List<CoinGenerator>> parseCoinGenerators(String jsonString) async {
    final String response = await rootBundle.loadString(jsonString);
    final List<dynamic> data = jsonDecode(response);

    return data.map((item) {
      CoinGenerator generator = CoinGenerator.fromJson(item);
      final stored = box.get(generator.tier);
      if (stored == null) {
        return generator;
      }
      generator.count = stored.count;
      generator.level = stored.level;
      return generator;
    }).toList();
  }
}
