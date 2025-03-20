import 'package:flutter/material.dart';

class Constants {
  static final Color barColor = Colors.grey.shade900;
  static final Color primaryColor = Colors.orange.shade700;
  static const tickTime = 1000; // miliseconds
  static const inactiveThreshold = 10000; // 10 seconds in milliseocnds
  static const calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel
  static const stepsToSpaceMultiplier = 1;
  static const notificationId = 1;
  static const baseOfflineCoinsMultiplier = 0.5;
  static const spendEnergyAchivementRequirements = [
    28800000, // 8 hours
    86400000, // 24 hours
    604800000, // 7 days
    1296000000, // 15 days
    2592000000, // 30 days
    5184000000, // 60 days
    15552000000, // 180 days
    31104000000, // 360 days
  ];
  static const double baseSpendEnergyAchivementReward = 1800000; // 30mins
  static const walkAchivementRequirements = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
    2000000,
  ];
  static const walkAchivementRewards = [
    1000,
    2000,
    3000,
    4000,
    5000,
    6000,
    7000,
    8000,
  ];
}
