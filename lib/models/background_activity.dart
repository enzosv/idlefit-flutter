class BackgroundActivity {
  final double energyEarned;
  final double spaceEarned;
  final double energySpent;
  final double coinsEarned;

  BackgroundActivity({
    this.energyEarned = 0,
    this.spaceEarned = 0,
    this.energySpent = 0,
    this.coinsEarned = 0,
  });

  BackgroundActivity copyWith({
    double? energyEarned,
    double? spaceEarned,
    double? energySpent,
    double? coinsEarned,
  }) {
    return BackgroundActivity(
      energyEarned: energyEarned ?? this.energyEarned,
      spaceEarned: spaceEarned ?? this.spaceEarned,
      energySpent: energySpent ?? this.energySpent,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }
}
