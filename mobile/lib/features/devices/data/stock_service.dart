import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../reminders/data/local_notification_service.dart';
import '../domain/stock_models.dart';

/// Service managing ASHA medical kit registry, drug & supply dispensing,
/// real-time consumption rates, automated restock requests, hardware fault reporting,
/// calibration schedules, and stock-out event logging (Requirements 30.1 – 30.6).
class StockService {
  final AppDatabase _db;
  final LocalNotificationService? _notificationService;
  final SyncEngine? _syncEngine;
  static const _uuid = uuid_pkg.Uuid();

  StockService(
    this._db, [
    this._notificationService,
    this._syncEngine,
  ]);

  // ── 1. Database Initialisation ───────────────────────────────────────────────

  /// Ensures SQLite tables for equipment kit items, offline restock requests,
  /// device fault reports, and stock-out event logs exist.
  Future<void> ensureStockTablesExist() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS equipment_kit_items (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        serial_number TEXT NOT NULL,
        issue_date TEXT NOT NULL,
        calibration_due_date TEXT,
        status TEXT NOT NULL DEFAULT 'operational',
        notes TEXT
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS restock_requests (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_code TEXT NOT NULL,
        item_name TEXT NOT NULL,
        current_quantity REAL NOT NULL,
        requested_quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        urgency TEXT NOT NULL DEFAULT 'standard',
        requested_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS device_fault_reports (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        serial_number TEXT NOT NULL,
        fault_description TEXT NOT NULL,
        photo_attachment_path TEXT,
        has_low_battery_alert INTEGER NOT NULL DEFAULT 0,
        has_implausible_readings_pattern INTEGER NOT NULL DEFAULT 0,
        reported_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      );
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS stock_out_events (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_code TEXT NOT NULL,
        item_name TEXT NOT NULL,
        stock_out_date TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      );
    ''');
  }

  // ── 2. Equipment Kit Registry (Requirement 30.1) ─────────────────────────────

  /// Registers an equipment kit item with serial number, issue date, and calibration schedule.
  Future<void> registerKitItem(EquipmentKitItem item) async {
    await ensureStockTablesExist();
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO equipment_kit_items (
        id, worker_id, item_name, serial_number, issue_date, calibration_due_date, status, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        item.id,
        item.workerId,
        item.itemName,
        item.serialNumber,
        item.issueDate.toIso8601String(),
        item.calibrationDueDate?.toIso8601String(),
        item.status.code,
        item.notes,
      ],
    );

    await _enqueueSync(
      table: 'equipment_kit_items',
      recordId: item.id,
      operation: 'UPSERT',
      payload: item.toJson(),
      priority: SyncPriority.metadata,
    );
  }

  /// Retrieves all equipment kit items issued to an ASHA worker.
  Future<List<EquipmentKitItem>> getKitItems(String workerId) async {
    await ensureStockTablesExist();
    final rows = await _db.customSelect(
      'SELECT * FROM equipment_kit_items WHERE worker_id = ? ORDER BY item_name ASC',
      variables: [Variable.withString(workerId)],
    ).get();

    return rows.map((row) {
      return EquipmentKitItem(
        id: row.read<String>('id'),
        workerId: row.read<String>('worker_id'),
        itemName: row.read<String>('item_name'),
        serialNumber: row.read<String>('serial_number'),
        issueDate: DateTime.parse(row.read<String>('issue_date')),
        calibrationDueDate: row.readNullable<String>('calibration_due_date') != null
            ? DateTime.parse(row.read<String>('calibration_due_date'))
            : null,
        status: EquipmentStatus.fromCode(row.read<String>('status')),
        notes: row.readNullable<String>('notes'),
      );
    }).toList();
  }

  // ── 3. Stock Dispensing & Transactions (Requirement 30.2) ───────────────────

  /// Dispenses consumable items (IFA, ORS, Zinc, Contraceptives), decrements local stock,
  /// writes transaction record to `stock_transactions`, calculates run-out date,
  /// triggers threshold alerts if below minimum, and logs stock-outs (Requirements 30.2, 30.3, 30.6).
  Future<StockItemWithRunOut> dispenseItem({
    required String itemId,
    required double quantityDispensed,
    String? relatedEncounterId,
    String? relatedMemberId,
    DateTime? timestamp,
  }) async {
    await ensureStockTablesExist();
    final now = timestamp ?? DateTime.now();

    // 1. Fetch current item from stock_items
    final itemQuery = await (_db.select(_db.stockItems)..where((t) => t.id.equals(itemId))).getSingleOrNull();
    if (itemQuery == null) {
      throw ArgumentError('Stock item with id $itemId not found.');
    }

    final newQuantity = math.max(0.0, itemQuery.quantity - quantityDispensed);
    final nowMs = now.millisecondsSinceEpoch;

    // 2. Update stock item quantity
    await (_db.update(_db.stockItems)..where((t) => t.id.equals(itemId))).write(
      StockItemsCompanion(
        quantity: Value(newQuantity),
        lastUpdatedAt: Value(nowMs),
      ),
    );

    // 3. Insert transaction into stock_transactions
    final transactionId = _uuid.v4();
    await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            id: transactionId,
            itemId: itemId,
            transactionType: 'DISPENSE',
            quantityDelta: -quantityDispensed,
            relatedEncounterId: Value(relatedEncounterId),
            relatedMemberId: Value(relatedMemberId),
            recordedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    await _enqueueSync(
      table: 'stock_transactions',
      recordId: transactionId,
      operation: 'INSERT',
      payload: {
        'id': transactionId,
        'item_id': itemId,
        'transaction_type': 'DISPENSE',
        'quantity_delta': -quantityDispensed,
        'related_encounter_id': relatedEncounterId,
        'related_member_id': relatedMemberId,
        'recorded_at': nowMs,
      },
      priority: SyncPriority.clinical,
    );

    // 4. Calculate daily consumption rate & run-out date
    final dailyRate = await calculateDailyConsumptionRate(itemId, asOf: now);
    final runOutDate = computeEstimatedRunOutDate(newQuantity, dailyRate, asOf: now);

    final isBelowThreshold = newQuantity <= itemQuery.minThreshold;
    final isStockedOut = newQuantity <= 0.0;

    // 5. Handle low stock threshold alert & offline restock request generation (Requirement 30.3)
    if (isBelowThreshold) {
      final recommendedRestock = (itemQuery.minThreshold * 3.0) - newQuantity;
      await requestRestock(
        workerId: itemQuery.workerId,
        itemId: itemId,
        requestedQuantity: math.max(recommendedRestock, 10.0),
        urgency: isStockedOut ? 'critical_stockout' : 'standard',
        requestedAt: now,
      );
    }

    // 6. Record stock-out event if reached 0 (Requirement 30.6)
    if (isStockedOut) {
      await _recordStockOutEvent(
        workerId: itemQuery.workerId,
        itemId: itemId,
        itemCode: itemQuery.itemCode,
        itemName: itemQuery.itemName,
        stockOutDate: now,
      );
    }

    return StockItemWithRunOut(
      id: itemQuery.id,
      workerId: itemQuery.workerId,
      itemCode: itemQuery.itemCode,
      itemName: itemQuery.itemName,
      currentQuantity: newQuantity,
      minThreshold: itemQuery.minThreshold,
      unit: itemQuery.unit,
      dailyConsumptionRate: dailyRate,
      estimatedRunOutDate: runOutDate,
      isBelowThreshold: isBelowThreshold,
      isStockedOut: isStockedOut,
      stockOutDate: isStockedOut ? now : null,
    );
  }

  // ── 4. Consumption Rate & Run-Out Date Calculation (Requirement 30.2) ───────

  /// Computes average daily consumption rate over a sliding window (default 30 days).
  Future<double> calculateDailyConsumptionRate(
    String itemId, {
    DateTime? asOf,
    int windowDays = 30,
  }) async {
    final now = asOf ?? DateTime.now();
    final windowStartMs = now.subtract(Duration(days: windowDays)).millisecondsSinceEpoch;

    final txRows = await (_db.select(_db.stockTransactions)
          ..where(
            (t) =>
                t.itemId.equals(itemId) &
                t.transactionType.equals('DISPENSE') &
                t.recordedAt.isBiggerOrEqualValue(windowStartMs),
          ))
        .get();

    if (txRows.isEmpty) return 0.0;

    double totalDispensed = 0.0;
    for (final tx in txRows) {
      totalDispensed += tx.quantityDelta.abs();
    }

    // Determine span between earliest transaction in window and now, min 1 day
    final earliestMs = txRows.map((t) => t.recordedAt).reduce(math.min);
    final daysElapsed = math.max(1.0, (now.millisecondsSinceEpoch - earliestMs) / (1000 * 3600 * 24));

    return totalDispensed / daysElapsed;
  }

  /// Calculates the estimated date when stock will hit zero given current quantity and daily rate.
  DateTime? computeEstimatedRunOutDate(
    double currentQuantity,
    double dailyConsumptionRate, {
    DateTime? asOf,
  }) {
    if (dailyConsumptionRate <= 0.0 || currentQuantity <= 0.0) return null;
    final now = asOf ?? DateTime.now();
    final daysRemaining = (currentQuantity / dailyConsumptionRate).floor();
    return now.add(Duration(days: daysRemaining));
  }

  // ── 5. Full Inventory Fetch (Requirements 30.2, 30.3) ────────────────────────

  /// Fetches complete inventory for an ASHA worker with real-time run-out estimates and alert flags.
  Future<List<StockItemWithRunOut>> getStockInventory(
    String workerId, {
    DateTime? asOf,
  }) async {
    await ensureStockTablesExist();
    final now = asOf ?? DateTime.now();

    final items = await (_db.select(_db.stockItems)..where((t) => t.workerId.equals(workerId))).get();

    final result = <StockItemWithRunOut>[];
    for (final item in items) {
      final dailyRate = await calculateDailyConsumptionRate(item.id, asOf: now);
      final runOutDate = computeEstimatedRunOutDate(item.quantity, dailyRate, asOf: now);
      final isBelow = item.quantity <= item.minThreshold;
      final isStockedOut = item.quantity <= 0.0;

      result.add(
        StockItemWithRunOut(
          id: item.id,
          workerId: item.workerId,
          itemCode: item.itemCode,
          itemName: item.itemName,
          currentQuantity: item.quantity,
          minThreshold: item.minThreshold,
          unit: item.unit,
          dailyConsumptionRate: dailyRate,
          estimatedRunOutDate: runOutDate,
          isBelowThreshold: isBelow,
          isStockedOut: isStockedOut,
          stockOutDate: isStockedOut ? DateTime.fromMillisecondsSinceEpoch(item.lastUpdatedAt) : null,
        ),
      );
    }

    return result;
  }

  // ── 6. Offline Restock Requests (Requirement 30.3) ──────────────────────────

  /// Generates and enqueues an offline restock request, notifying the ASHA (Requirement 30.3).
  Future<RestockRequest> requestRestock({
    required String workerId,
    required String itemId,
    required double requestedQuantity,
    String urgency = 'standard',
    DateTime? requestedAt,
  }) async {
    await ensureStockTablesExist();
    final now = requestedAt ?? DateTime.now();

    final itemQuery = await (_db.select(_db.stockItems)..where((t) => t.id.equals(itemId))).getSingleOrNull();
    final itemCode = itemQuery?.itemCode ?? itemId;
    final itemName = itemQuery?.itemName ?? 'Item $itemId';
    final currentQuantity = itemQuery?.quantity ?? 0.0;
    final unit = itemQuery?.unit ?? 'units';

    final request = RestockRequest(
      id: _uuid.v4(),
      workerId: workerId,
      itemId: itemId,
      itemCode: itemCode,
      itemName: itemName,
      currentQuantity: currentQuantity,
      requestedQuantity: requestedQuantity,
      unit: unit,
      urgency: urgency,
      requestedAt: now,
    );

    // Write to offline restock_requests table
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO restock_requests (
        id, worker_id, item_id, item_code, item_name, current_quantity,
        requested_quantity, unit, urgency, requested_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ''',
      [
        request.id,
        request.workerId,
        request.itemId,
        request.itemCode,
        request.itemName,
        request.currentQuantity,
        request.requestedQuantity,
        request.unit,
        request.urgency,
        request.requestedAt.toIso8601String(),
      ],
    );

    // Enqueue to sync_queue for upload to ASHA Facilitator / Backend on next connection
    await _enqueueSync(
      table: 'restock_requests',
      recordId: request.id,
      operation: 'INSERT',
      payload: request.toJson(),
      priority: urgency == 'critical_stockout' ? SyncPriority.critical : SyncPriority.metadata,
    );

    // Dispatch local notification alert
    if (_notificationService != null) {
      try {
        await _notificationService.showUrgentAlert(
          title: 'Low Stock Alert: $itemName',
          body: 'Stock is down to $currentQuantity $unit (Threshold: ${itemQuery?.minThreshold ?? 5} $unit). Restock request enqueued.',
          payload: {'requestId': request.id, 'itemId': itemId},
        );
      } catch (e) {
        debugPrint('StockService: Could not dispatch notification: $e');
      }
    }

    return request;
  }

  /// Retrieves pending offline restock requests.
  Future<List<RestockRequest>> getPendingRestockRequests(String workerId) async {
    await ensureStockTablesExist();
    final rows = await _db.customSelect(
      'SELECT * FROM restock_requests WHERE worker_id = ? ORDER BY requested_at DESC',
      variables: [Variable.withString(workerId)],
    ).get();

    return rows.map((r) {
      return RestockRequest(
        id: r.read<String>('id'),
        workerId: r.read<String>('worker_id'),
        itemId: r.read<String>('item_id'),
        itemCode: r.read<String>('item_code'),
        itemName: r.read<String>('item_name'),
        currentQuantity: r.read<double>('current_quantity'),
        requestedQuantity: r.read<double>('requested_quantity'),
        unit: r.read<String>('unit'),
        urgency: r.read<String>('urgency'),
        requestedAt: DateTime.parse(r.read<String>('requested_at')),
      );
    }).toList();
  }

  // ── 7. Hardware Fault Reporting (Requirement 30.4) ──────────────────────────

  /// Submits a hardware fault report with optional photo attachment and updates equipment status.
  Future<DeviceFaultReport> reportDeviceFault({
    required String workerId,
    required String deviceId,
    required String serialNumber,
    required String faultDescription,
    String? photoAttachmentPath,
    bool hasLowBatteryAlert = false,
    bool hasImplausibleReadingsPattern = false,
    DateTime? reportedAt,
  }) async {
    await ensureStockTablesExist();
    final now = reportedAt ?? DateTime.now();

    final report = DeviceFaultReport(
      id: _uuid.v4(),
      workerId: workerId,
      deviceId: deviceId,
      serialNumber: serialNumber,
      faultDescription: faultDescription,
      photoAttachmentPath: photoAttachmentPath,
      hasLowBatteryAlert: hasLowBatteryAlert,
      hasImplausibleReadingsPattern: hasImplausibleReadingsPattern,
      reportedAt: now,
    );

    // Insert into local device_fault_reports table
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO device_fault_reports (
        id, worker_id, device_id, serial_number, fault_description,
        photo_attachment_path, has_low_battery_alert, has_implausible_readings_pattern,
        reported_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ''',
      [
        report.id,
        report.workerId,
        report.deviceId,
        report.serialNumber,
        report.faultDescription,
        report.photoAttachmentPath,
        report.hasLowBatteryAlert ? 1 : 0,
        report.hasImplausibleReadingsPattern ? 1 : 0,
        report.reportedAt.toIso8601String(),
      ],
    );

    // Update equipment kit item status to faulty
    await _db.customStatement(
      '''
      UPDATE equipment_kit_items
      SET status = ?, notes = ?
      WHERE serial_number = ? OR id = ?
    ''',
      [
        EquipmentStatus.faulty.code,
        'Fault reported: $faultDescription',
        serialNumber,
        deviceId,
      ],
    );

    // Enqueue to sync queue
    await _enqueueSync(
      table: 'device_fault_reports',
      recordId: report.id,
      operation: 'INSERT',
      payload: report.toJson(),
      priority: SyncPriority.clinical,
    );

    return report;
  }

  // ── 8. Calibration & Replacement Due List for ANM (Requirement 30.5) ────────

  /// Returns equipment due for calibration or replacement based on schedule.
  Future<List<EquipmentKitItem>> getEquipmentDueForCalibration({
    String? workerId,
    DateTime? asOf,
  }) async {
    await ensureStockTablesExist();
    final now = asOf ?? DateTime.now();

    final rows = workerId != null
        ? await _db.customSelect(
            "SELECT * FROM equipment_kit_items WHERE worker_id = ? AND status != 'replaced' ORDER BY item_name ASC",
            variables: [Variable.withString(workerId)],
          ).get()
        : await _db.customSelect(
            "SELECT * FROM equipment_kit_items WHERE status != 'replaced' ORDER BY item_name ASC",
          ).get();

    return rows
        .map((r) => EquipmentKitItem(
              id: r.read<String>('id'),
              workerId: r.read<String>('worker_id'),
              itemName: r.read<String>('item_name'),
              serialNumber: r.read<String>('serial_number'),
              issueDate: DateTime.parse(r.read<String>('issue_date')),
              calibrationDueDate: r.readNullable<String>('calibration_due_date') != null
                  ? DateTime.parse(r.read<String>('calibration_due_date'))
                  : null,
              status: EquipmentStatus.fromCode(r.read<String>('status')),
              notes: r.readNullable<String>('notes'),
            ))
        .where((e) => e.isCalibrationDue(now) || e.status == EquipmentStatus.faulty || e.status == EquipmentStatus.calibrationDue)
        .toList();
  }

  /// Records action taken by ANM on calibration or replacement (Requirement 30.5).
  Future<void> recordCalibrationOrReplacement({
    required String itemId,
    required bool replaced,
    String? newSerialNumber,
    DateTime? nextCalibrationDueDate,
    String? notes,
    DateTime? actionDate,
  }) async {
    await ensureStockTablesExist();
    final now = actionDate ?? DateTime.now();

    if (replaced) {
      await _db.customStatement(
        '''
        UPDATE equipment_kit_items
        SET status = ?,
            serial_number = COALESCE(?, serial_number),
            issue_date = ?,
            calibration_due_date = ?,
            notes = ?
        WHERE id = ?
      ''',
        [
          EquipmentStatus.operational.code,
          newSerialNumber,
          now.toIso8601String(),
          nextCalibrationDueDate?.toIso8601String(),
          notes ?? 'Replaced by Block Health Office',
          itemId,
        ],
      );
    } else {
      await _db.customStatement(
        '''
        UPDATE equipment_kit_items
        SET status = ?,
            calibration_due_date = ?,
            notes = ?
        WHERE id = ?
      ''',
        [
          EquipmentStatus.operational.code,
          nextCalibrationDueDate?.toIso8601String(),
          notes ?? 'Calibrated and verified',
          itemId,
        ],
      );
    }

    await _enqueueSync(
      table: 'equipment_kit_items',
      recordId: itemId,
      operation: 'UPDATE',
      payload: {
        'id': itemId,
        'action': replaced ? 'REPLACED' : 'CALIBRATED',
        'serial_number': newSerialNumber,
        'action_date': now.toIso8601String(),
        'next_calibration_due': nextCalibrationDueDate?.toIso8601String(),
      },
      priority: SyncPriority.metadata,
    );
  }

  // ── 9. Stock-Out Event Recording (Requirement 30.6) ─────────────────────────

  Future<void> _recordStockOutEvent({
    required String workerId,
    required String itemId,
    required String itemCode,
    required String itemName,
    required DateTime stockOutDate,
  }) async {
    final eventId = _uuid.v4();
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO stock_out_events (
        id, worker_id, item_id, item_code, item_name, stock_out_date, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, 'pending')
    ''',
      [
        eventId,
        workerId,
        itemId,
        itemCode,
        itemName,
        stockOutDate.toIso8601String(),
      ],
    );

    // Sync to backend supply-chain dashboards (Requirement 30.6)
    await _enqueueSync(
      table: 'stock_out_events',
      recordId: eventId,
      operation: 'INSERT',
      payload: {
        'id': eventId,
        'worker_id': workerId,
        'item_id': itemId,
        'item_code': itemCode,
        'item_name': itemName,
        'stock_out_date': stockOutDate.toIso8601String(),
      },
      priority: SyncPriority.critical,
    );
  }

  // ── 10. Seed Helper ─────────────────────────────────────────────────────────

  /// Seeds default NHM standard stock items and equipment kit for an ASHA.
  Future<void> seedDefaultAshaKitAndStock(String workerId) async {
    await ensureStockTablesExist();
    final now = DateTime.now();

    final defaultItems = [
      ('ifa_adult', 'IFA Tablets (Adult)', 150.0, 30.0, 'tablets'),
      ('ifa_syrup', 'IFA Syrup (Pediatric)', 12.0, 3.0, 'bottles'),
      ('ors_sachets', 'ORS Sachets', 40.0, 10.0, 'sachets'),
      ('zinc_tabs', 'Zinc Tablets (20mg)', 100.0, 20.0, 'tablets'),
      ('pcm_tabs', 'Paracetamol Tablets (500mg)', 60.0, 15.0, 'tablets'),
      ('pcm_syrup', 'Paracetamol Syrup', 8.0, 2.0, 'bottles'),
      ('condoms', 'Nirodh (Condoms)', 80.0, 20.0, 'pieces'),
      ('ocp_mala_n', 'Mala-N (Oral Contraceptive Pills)', 30.0, 10.0, 'cycles'),
      ('chhaya_tabs', 'Chhaya (Centchroman)', 25.0, 5.0, 'strips'),
      ('ptk_nishchay', 'Pregnancy Test Kits (Nishchay)', 15.0, 5.0, 'kits'),
    ];

    for (final item in defaultItems) {
      final existing = await (_db.select(_db.stockItems)
            ..where((t) => t.workerId.equals(workerId) & t.itemCode.equals(item.$1)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.stockItems).insert(
              StockItemsCompanion.insert(
                id: _uuid.v4(),
                workerId: workerId,
                itemCode: item.$1,
                itemName: item.$2,
                quantity: Value(item.$3),
                minThreshold: Value(item.$4),
                unit: item.$5,
                lastUpdatedAt: now.millisecondsSinceEpoch,
              ),
            );
      }
    }

    final defaultEquipment = [
      EquipmentKitItem(
        id: _uuid.v4(),
        workerId: workerId,
        itemName: 'Digital Blood Pressure Monitor',
        serialNumber: 'BP-OMRON-${workerId.substring(0, math.min(6, workerId.length)).toUpperCase()}-01',
        issueDate: now.subtract(const Duration(days: 120)),
        calibrationDueDate: now.add(const Duration(days: 245)),
        status: EquipmentStatus.operational,
      ),
      EquipmentKitItem(
        id: _uuid.v4(),
        workerId: workerId,
        itemName: 'Pulse Oximeter',
        serialNumber: 'POX-${workerId.substring(0, math.min(6, workerId.length)).toUpperCase()}-02',
        issueDate: now.subtract(const Duration(days: 120)),
        calibrationDueDate: now.add(const Duration(days: 245)),
        status: EquipmentStatus.operational,
      ),
      EquipmentKitItem(
        id: _uuid.v4(),
        workerId: workerId,
        itemName: 'Digital Thermometer',
        serialNumber: 'THM-${workerId.substring(0, math.min(6, workerId.length)).toUpperCase()}-03',
        issueDate: now.subtract(const Duration(days: 120)),
        calibrationDueDate: now.add(const Duration(days: 60)),
        status: EquipmentStatus.operational,
      ),
      EquipmentKitItem(
        id: _uuid.v4(),
        workerId: workerId,
        itemName: 'MUAC Shakir Tape',
        serialNumber: 'MUAC-WHO-2026',
        issueDate: now.subtract(const Duration(days: 180)),
        calibrationDueDate: null,
        status: EquipmentStatus.operational,
      ),
    ];

    for (final eq in defaultEquipment) {
      await registerKitItem(eq);
    }
  }

  // ── 11. Helper Sync ─────────────────────────────────────────────────────────

  Future<void> _enqueueSync({
    required String table,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
    required SyncPriority priority,
  }) async {
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: table,
        recordId: recordId,
        operation: operation,
        payload: payload,
        priority: priority,
      );
    } else {
      // Direct insertion into sync_queue table
      await _db.into(_db.syncQueue).insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              targetTable: table,
              recordId: recordId,
              priority: Value(priority.value),
              operation: operation,
              payloadJson: jsonEncode(payload),
              eventLogJson: const Value('[]'),
              syncStatus: const Value('pending'),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }
  }
}
