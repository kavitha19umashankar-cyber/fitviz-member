import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

class HealthData {
  final int? steps;
  final double? heartRate;
  final double? caloriesBurned;
  final bool authorized;

  const HealthData({
    this.steps,
    this.heartRate,
    this.caloriesBurned,
    this.authorized = false,
  });
}

class HealthService {
  static final _health = Health();

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  static Future<HealthData> fetchTodayData() async {
    try {
      final authorized = await _health.requestAuthorization(_types);
      if (!authorized) return const HealthData(authorized: false);

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: _types,
      );
      final cleanData = _health.removeDuplicates(data);

      int steps = 0;
      double heartRateSum = 0;
      int heartRateCount = 0;
      double calories = 0;

      for (final point in cleanData) {
        if (point.value is NumericHealthValue) {
          final val = (point.value as NumericHealthValue).numericValue;
          switch (point.type) {
            case HealthDataType.STEPS:
              steps += val.toInt();
              break;
            case HealthDataType.HEART_RATE:
              heartRateSum += val.toDouble();
              heartRateCount++;
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              calories += val.toDouble();
              break;
            default:
              break;
          }
        }
      }

      return HealthData(
        steps: steps > 0 ? steps : null,
        heartRate:
            heartRateCount > 0 ? heartRateSum / heartRateCount : null,
        caloriesBurned: calories > 0 ? calories : null,
        authorized: true,
      );
    } catch (_) {
      return const HealthData(authorized: false);
    }
  }
}

final healthDataProvider = FutureProvider<HealthData>((ref) async {
  return HealthService.fetchTodayData();
});
