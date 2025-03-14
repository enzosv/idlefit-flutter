import 'package:flutter/material.dart';

class Constants {
  static final Color barColor = Colors.grey.shade900;
  static final Color primaryColor = Colors.orange.shade700;
  static const IconData coinIcon = Icons.speed;
  static const IconData spaceIcon = Icons.space_dashboard_rounded;
  static const IconData energyIcon = Icons.bolt_rounded;
  static const tickTime = 1000; // miliseconds
  static const inactiveThreshold = 10000; // 10 seconds in milliseocnds
  static const calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel
  static const stepsToSpaceMultiplier = 1;
  static const notificationId = 1;
}
