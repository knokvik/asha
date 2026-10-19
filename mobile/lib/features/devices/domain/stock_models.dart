/// Status of an issued medical equipment kit item (Requirements 30.1, 30.5).
enum EquipmentStatus {
  operational('operational', 'Operational & Functional'),
  faulty('faulty', 'Faulty / Hardware Defect'),
  calibrationDue('calibration_due', 'Calibration / Maintenance Due'),
  replaced('replaced', 'Replaced by Block Health Office');

  final String code;
  final String label;
  const EquipmentStatus(this.code, this.label);

  static EquipmentStatus fromCode(String? code) {
    if (code == null) return EquipmentStatus.operational;
    return EquipmentStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => EquipmentStatus.operational,
    );
  }
}

/// Issued medical equipment kit item with serial number and calibration schedule (Requirement 30.1, 30.5).
class EquipmentKitItem {
  final String id;
  final String workerId;
  final String itemName; // e.g. 'Blood Pressure Monitor', 'Pulse Oximeter', 'Digital Thermometer'
  final String serialNumber;
  final DateTime issueDate;
  final DateTime? calibrationDueDate;
  final EquipmentStatus status;
  final String? notes;

  const EquipmentKitItem({
    required this.id,
    required this.workerId,
    required this.itemName,
    required this.serialNumber,
    required this.issueDate,
    this.calibrationDueDate,
    this.status = EquipmentStatus.operational,
    this.notes,
  });

  bool isCalibrationDue(DateTime asOf) {
    if (calibrationDueDate == null) return false;
    return !asOf.isBefore(calibrationDueDate!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'item_name': itemName,
        'serial_number': serialNumber,
        'issue_date': issueDate.toIso8601String(),
        'calibration_due_date': calibrationDueDate?.toIso8601String(),
        'status': status.code,
        'notes': notes,
      };

  factory EquipmentKitItem.fromJson(Map<String, dynamic> json) => EquipmentKitItem(
        id: json['id'] as String,
        workerId: json['worker_id'] as String,
        itemName: json['item_name'] as String,
        serialNumber: json['serial_number'] as String,
        issueDate: DateTime.parse(json['issue_date'] as String),
        calibrationDueDate: json['calibration_due_date'] != null
            ? DateTime.parse(json['calibration_due_date'] as String)
            : null,
        status: EquipmentStatus.fromCode(json['status'] as String?),
        notes: json['notes'] as String?,
      );
}

/// Stock item with real-time consumption rate, run-out date, and threshold alerts (Requirements 30.2, 30.3).
class StockItemWithRunOut {
  final String id;
  final String workerId;
  final String itemCode;
  final String itemName;
  final double currentQuantity;
  final double minThreshold;
  final String unit;
  final double dailyConsumptionRate; // units consumed per day
  final DateTime? estimatedRunOutDate;
  final bool isBelowThreshold;
  final bool isStockedOut;
  final DateTime? stockOutDate;

  const StockItemWithRunOut({
    required this.id,
    required this.workerId,
    required this.itemCode,
    required this.itemName,
    required this.currentQuantity,
    required this.minThreshold,
    required this.unit,
    required this.dailyConsumptionRate,
    this.estimatedRunOutDate,
    required this.isBelowThreshold,
    required this.isStockedOut,
    this.stockOutDate,
  });

  /// Computes days remaining until stock-out occurs
  int? get daysUntilRunOut {
    if (dailyConsumptionRate <= 0.0 || currentQuantity <= 0.0) return null;
    return (currentQuantity / dailyConsumptionRate).floor();
  }
}

/// Offline Restock Request entity (Requirement 30.3).
class RestockRequest {
  final String id;
  final String workerId;
  final String itemId;
  final String itemCode;
  final String itemName;
  final double currentQuantity;
  final double requestedQuantity;
  final String unit;
  final String urgency; // 'standard', 'critical_stockout'
  final DateTime requestedAt;

  const RestockRequest({
    required this.id,
    required this.workerId,
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.currentQuantity,
    required this.requestedQuantity,
    required this.unit,
    this.urgency = 'standard',
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'item_id': itemId,
        'item_code': itemCode,
        'item_name': itemName,
        'current_quantity': currentQuantity,
        'requested_quantity': requestedQuantity,
        'unit': unit,
        'urgency': urgency,
        'requested_at': requestedAt.toIso8601String(),
      };

  factory RestockRequest.fromJson(Map<String, dynamic> json) => RestockRequest(
        id: json['id'] as String,
        workerId: json['worker_id'] as String,
        itemId: json['item_id'] as String,
        itemCode: json['item_code'] as String,
        itemName: json['item_name'] as String,
        currentQuantity: (json['current_quantity'] as num).toDouble(),
        requestedQuantity: (json['requested_quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        urgency: json['urgency'] as String? ?? 'standard',
        requestedAt: DateTime.parse(json['requested_at'] as String),
      );
}

/// Hardware fault report with optional photo attachment (Requirement 30.4).
class DeviceFaultReport {
  final String id;
  final String workerId;
  final String deviceId;
  final String serialNumber;
  final String faultDescription;
  final String? photoAttachmentPath;
  final bool hasLowBatteryAlert;
  final bool hasImplausibleReadingsPattern;
  final DateTime reportedAt;

  const DeviceFaultReport({
    required this.id,
    required this.workerId,
    required this.deviceId,
    required this.serialNumber,
    required this.faultDescription,
    this.photoAttachmentPath,
    this.hasLowBatteryAlert = false,
    this.hasImplausibleReadingsPattern = false,
    required this.reportedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'device_id': deviceId,
        'serial_number': serialNumber,
        'fault_description': faultDescription,
        'photo_attachment_path': photoAttachmentPath,
        'has_low_battery_alert': hasLowBatteryAlert,
        'has_implausible_readings_pattern': hasImplausibleReadingsPattern,
        'reported_at': reportedAt.toIso8601String(),
      };

  factory DeviceFaultReport.fromJson(Map<String, dynamic> json) => DeviceFaultReport(
        id: json['id'] as String,
        workerId: json['worker_id'] as String,
        deviceId: json['device_id'] as String,
        serialNumber: json['serial_number'] as String,
        faultDescription: json['fault_description'] as String,
        photoAttachmentPath: json['photo_attachment_path'] as String?,
        hasLowBatteryAlert: json['has_low_battery_alert'] as bool? ?? false,
        hasImplausibleReadingsPattern: json['has_implausible_readings_pattern'] as bool? ?? false,
        reportedAt: DateTime.parse(json['reported_at'] as String),
      );
}
