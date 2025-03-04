import 'dart:math';

class Generator {
  final String id;
  final String name;
  final String description;
  final int baseCost;
  final double baseOutput;
  int count;

  Generator({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.baseOutput,
    this.count = 0,
  });

  int get currentCost {
    // Cost increases with each purchase
    return (baseCost * pow(1.25, count)).floor();
  }

  double get output {
    return baseOutput * count;
  }
}
