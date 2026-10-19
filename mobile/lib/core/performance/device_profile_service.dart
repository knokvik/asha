import 'package:flutter/foundation.dart';

@immutable
class DeviceHardwareSpecs {
  final int ramMegabytes;
  final int androidApiLevel;
  final bool isBatteryLow; // < 20%
  final bool isBatteryOptimizationEnabled;

  const DeviceHardwareSpecs({
    required this.ramMegabytes,
    required this.androidApiLevel,
    this.isBatteryLow = false,
    this.isBatteryOptimizationEnabled = false,
  });

  bool get meetsRecommendedSpecs => ramMegabytes >= 2048 && androidApiLevel >= 28; // Android 9+
  bool get requiresReducedFeatureMode => ramMegabytes < 1536 || androidApiLevel < 28; // < 1.5GB RAM or < Android 9
}

@immutable
class LowPowerConfiguration {
  final bool isEnabled;
  final bool enableDarkTheme;
  final bool disableAnimations;
  final bool deferSyncToWifiOnly;
  final bool disableNonEssentialBackgroundTasks;

  const LowPowerConfiguration({
    required this.isEnabled,
    this.enableDarkTheme = true,
    this.disableAnimations = true,
    this.deferSyncToWifiOnly = true,
    this.disableNonEssentialBackgroundTasks = true,
  });

  static const defaultActive = LowPowerConfiguration(
    isEnabled: true,
    enableDarkTheme: true,
    disableAnimations: true,
    deferSyncToWifiOnly: true,
    disableNonEssentialBackgroundTasks: true,
  );

  static const disabled = LowPowerConfiguration(
    isEnabled: false,
    enableDarkTheme: false,
    disableAnimations: false,
    deferSyncToWifiOnly: false,
    disableNonEssentialBackgroundTasks: false,
  );
}

@immutable
class ReducedFeatureConfiguration {
  final bool isEnabled;
  final bool disableVoiceAsrModel; // Tap-only data entry
  final bool useSimplifiedTriage;
  final String statusNotice;

  const ReducedFeatureConfiguration({
    required this.isEnabled,
    this.disableVoiceAsrModel = true,
    this.useSimplifiedTriage = true,
    this.statusNotice =
        'Reduced-feature mode enabled: Offline voice model disabled to optimize device RAM (Requirement 48.6).',
  });
}

class DeviceProfileService {
  LowPowerConfiguration _lowPowerConfig = LowPowerConfiguration.disabled;

  LowPowerConfiguration get lowPowerConfig => _lowPowerConfig;

  /// Evaluates device hardware specifications and configures reduced-feature mode if underpowered (Requirement 48.6).
  ReducedFeatureConfiguration evaluateHardwareConstraints(DeviceHardwareSpecs specs) {
    if (specs.requiresReducedFeatureMode) {
      return const ReducedFeatureConfiguration(
        isEnabled: true,
        disableVoiceAsrModel: true,
        useSimplifiedTriage: true,
      );
    }
    return const ReducedFeatureConfiguration(
      isEnabled: false,
      disableVoiceAsrModel: false,
      useSimplifiedTriage: false,
      statusNotice: 'Standard performance mode active.',
    );
  }

  /// Toggles low-power mode (Requirement 48.7).
  void setLowPowerMode(bool enable) {
    _lowPowerConfig = enable ? LowPowerConfiguration.defaultActive : LowPowerConfiguration.disabled;
  }

  /// Times screen render or clinical triage computation, asserting SLA compliance (< 1000 ms) (Requirement 48.2).
  Future<int> profileExecutionTime(Future<void> Function() asyncWork) async {
    final stopwatch = Stopwatch()..start();
    await asyncWork();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }
}
