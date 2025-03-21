import 'package:flutter/services.dart';

class IosHealthService {
  static const MethodChannel _channel = MethodChannel(
    'com.idlefit/health_statistics',
  );

  Future<(double, double)> queryHealthForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final [steps, calories] =
        await [
          _queryStatistics(start: start, end: end, type: "STEPS"),
          _queryStatistics(
            start: start,
            end: end,
            type: "ACTIVE_ENERGY_BURNED",
          ),
        ].wait;
    return (steps, calories);
  }

  Future<double> _queryStatistics({
    required DateTime start,
    required DateTime end,
    required String type,
  }) async {
    assert(
      ["ACTIVE_ENERGY_BURNED", "STEPS"].contains(type),
      "Unsupported health data type $type",
    );

    try {
      final result = await _channel.invokeMethod('queryStatistics', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
        'type': type,
      });

      return result?.toDouble() ?? 0.0;
    } on PlatformException catch (e) {
      print('Failed to query statistics: ${e.message}');
      return 0.0;
    }
  }
}
