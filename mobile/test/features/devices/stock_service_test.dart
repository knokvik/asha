import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/devices/data/stock_service.dart';
import 'package:asha_platform/features/devices/domain/stock_models.dart';
import 'package:asha_platform/features/devices/presentation/stock_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 12.6 & 12.7: Stock, Equipment Management & Integration Tests (Requirements 30.1 – 30.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late StockService stockService;

    const testWorkerId = 'asha_sunita_01';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      stockService = StockService(db, null, syncEngine);
      await stockService.ensureStockTablesExist();
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Equipment Kit Registry (Requirement 30.1, 30.5) ─────────────────────
    group('Equipment Kit Registry (Requirement 30.1)', () {
      test('records each equipment item with serial number, issue date, and worker attribution', () async {
        final now = DateTime(2026, 4, 1);
        final item = EquipmentKitItem(
          id: 'kit_bp_01',
          workerId: testWorkerId,
          itemName: 'Digital Blood Pressure Monitor',
          serialNumber: 'OMRON-HEM-7120-SN448',
          issueDate: now,
          calibrationDueDate: now.add(const Duration(days: 365)),
          status: EquipmentStatus.operational,
          notes: 'Standard NHM issue',
        );

        await stockService.registerKitItem(item);

        final items = await stockService.getKitItems(testWorkerId);
        expect(items.length, equals(1));
        expect(items.first.itemName, equals('Digital Blood Pressure Monitor'));
        expect(items.first.serialNumber, equals('OMRON-HEM-7120-SN448'));
        expect(items.first.status, equals(EquipmentStatus.operational));
        expect(items.first.workerId, equals(testWorkerId));
      });

      test('identifies items due for calibration or replacement (Requirement 30.5)', () async {
        final issueDate = DateTime(2025, 1, 1);
        final pastCalibrationDate = DateTime(2026, 1, 1);
        final futureCalibrationDate = DateTime(2027, 1, 1);

        // Due device
        await stockService.registerKitItem(
          EquipmentKitItem(
            id: 'kit_oximeter_01',
            workerId: testWorkerId,
            itemName: 'Pulse Oximeter',
            serialNumber: 'POX-9912',
            issueDate: issueDate,
            calibrationDueDate: pastCalibrationDate,
            status: EquipmentStatus.operational,
          ),
        );

        // Future device (not due)
        await stockService.registerKitItem(
          EquipmentKitItem(
            id: 'kit_thermometer_01',
            workerId: testWorkerId,
            itemName: 'Digital Thermometer',
            serialNumber: 'THM-3321',
            issueDate: issueDate,
            calibrationDueDate: futureCalibrationDate,
            status: EquipmentStatus.operational,
          ),
        );

        final asOf = DateTime(2026, 6, 1);
        final dueList = await stockService.getEquipmentDueForCalibration(
          workerId: testWorkerId,
          asOf: asOf,
        );

        expect(dueList.length, equals(1));
        expect(dueList.first.itemName, equals('Pulse Oximeter'));
        expect(dueList.first.isCalibrationDue(asOf), isTrue);
      });

      test('ANM verifies calibration and extends due date (Requirement 30.5)', () async {
        final issueDate = DateTime(2025, 1, 1);
        final pastCalibration = DateTime(2026, 1, 1);

        await stockService.registerKitItem(
          EquipmentKitItem(
            id: 'kit_bp_cal',
            workerId: testWorkerId,
            itemName: 'Blood Pressure Monitor',
            serialNumber: 'BP-CAL-01',
            issueDate: issueDate,
            calibrationDueDate: pastCalibration,
            status: EquipmentStatus.calibrationDue,
          ),
        );

        final nextDue = DateTime(2027, 6, 1);
        await stockService.recordCalibrationOrReplacement(
          itemId: 'kit_bp_cal',
          replaced: false,
          nextCalibrationDueDate: nextDue,
          notes: 'Tested with standard mercury sphygmomanometer by ANM',
        );

        final items = await stockService.getKitItems(testWorkerId);
        final updated = items.firstWhere((e) => e.id == 'kit_bp_cal');
        expect(updated.status, equals(EquipmentStatus.operational));
        expect(updated.calibrationDueDate, equals(nextDue));
        expect(updated.notes, contains('Tested with standard mercury'));
      });

      test('ANM records replacement of broken unit with new serial number (Requirement 30.5)', () async {
        await stockService.registerKitItem(
          EquipmentKitItem(
            id: 'kit_broken_scale',
            workerId: testWorkerId,
            itemName: 'Infant Weighing Scale',
            serialNumber: 'SCALE-OLD-01',
            issueDate: DateTime(2024, 1, 1),
            status: EquipmentStatus.faulty,
          ),
        );

        final nextDue = DateTime(2027, 10, 1);
        await stockService.recordCalibrationOrReplacement(
          itemId: 'kit_broken_scale',
          replaced: true,
          newSerialNumber: 'SCALE-NEW-99',
          nextCalibrationDueDate: nextDue,
          notes: 'Replaced with digital hanging scale from PHC store',
        );

        final items = await stockService.getKitItems(testWorkerId);
        final updated = items.firstWhere((e) => e.id == 'kit_broken_scale');
        expect(updated.serialNumber, equals('SCALE-NEW-99'));
        expect(updated.status, equals(EquipmentStatus.operational));
      });
    });

    // ── 2. Dispensing & Consumption Calculation (Requirements 30.2, Task 12.7) ─
    group('Stock Dispensing & Run-Out Date (Requirement 30.2)', () {
      setUp(() async {
        // Seed initial consumable items
        await stockService.seedDefaultAshaKitAndStock(testWorkerId);
      });

      test('dispensing decrements quantity and logs transaction to stock_transactions', () async {
        final inventoryBefore = await stockService.getStockInventory(testWorkerId);
        final ifaItem = inventoryBefore.firstWhere((i) => i.itemCode == 'ifa_adult');
        expect(ifaItem.currentQuantity, equals(150.0));

        // Dispense 30 tablets
        final updated = await stockService.dispenseItem(
          itemId: ifaItem.id,
          quantityDispensed: 30.0,
          relatedMemberId: 'mem_anita_01',
        );

        expect(updated.currentQuantity, equals(120.0));
        expect(updated.isStockedOut, isFalse);

        // Verify transaction was written to stock_transactions table
        final txs = await db.select(db.stockTransactions).get();
        expect(txs.length, equals(1));
        expect(txs.first.itemId, equals(ifaItem.id));
        expect(txs.first.quantityDelta, equals(-30.0));
        expect(txs.first.transactionType, equals('DISPENSE'));
        expect(txs.first.relatedMemberId, equals('mem_anita_01'));
      });

      test('calculates daily consumption rate and estimated run-out date (Task 12.7)', () async {
        final inventory = await stockService.getStockInventory(testWorkerId);
        final orsItem = inventory.firstWhere((i) => i.itemCode == 'ors_sachets');
        expect(orsItem.currentQuantity, equals(40.0));

        final now = DateTime(2026, 10, 15);
        // Simulate dispensing 20 sachets 4 days ago
        await stockService.dispenseItem(
          itemId: orsItem.id,
          quantityDispensed: 20.0,
          timestamp: now.subtract(const Duration(days: 4)),
        );

        final dailyRate = await stockService.calculateDailyConsumptionRate(orsItem.id, asOf: now);
        expect(dailyRate, greaterThan(0.0));

        // Remaining 20 sachets at ~5/day gives ~4 days remaining
        final runOutDate = stockService.computeEstimatedRunOutDate(20.0, dailyRate, asOf: now);
        expect(runOutDate, isNotNull);
        expect(runOutDate!.isAfter(now), isTrue);
      });

      test('run-out date returns null when consumption rate is 0 or quantity is 0', () {
        expect(stockService.computeEstimatedRunOutDate(50.0, 0.0), isNull);
        expect(stockService.computeEstimatedRunOutDate(0.0, 5.0), isNull);
      });
    });

    // ── 3. Low Threshold Alerts & Restock Requests (Requirement 30.3, Task 12.7)
    group('Threshold Alerts & Offline Restock (Requirement 30.3)', () {
      setUp(() async {
        await stockService.seedDefaultAshaKitAndStock(testWorkerId);
      });

      test('stock falling below minimum threshold triggers restock alert and queues sync (Task 12.7)', () async {
        final inventory = await stockService.getStockInventory(testWorkerId);
        // ptk_nishchay has quantity: 15.0, minThreshold: 5.0
        final ptk = inventory.firstWhere((i) => i.itemCode == 'ptk_nishchay');
        expect(ptk.currentQuantity, equals(15.0));
        expect(ptk.minThreshold, equals(5.0));

        // Dispense 12 kits -> remaining 3.0 (below 5.0 min threshold)
        final updated = await stockService.dispenseItem(
          itemId: ptk.id,
          quantityDispensed: 12.0,
        );

        expect(updated.currentQuantity, equals(3.0));
        expect(updated.isBelowThreshold, isTrue);

        // Check that an offline restock request was generated
        final pendingRequests = await stockService.getPendingRestockRequests(testWorkerId);
        expect(pendingRequests.isNotEmpty, isTrue);
        final req = pendingRequests.firstWhere((r) => r.itemId == ptk.id);
        expect(req.itemName, equals('Pregnancy Test Kits (Nishchay)'));
        expect(req.currentQuantity, equals(3.0));
        expect(req.requestedQuantity, greaterThan(0.0));

        // Verify write to sync_queue table for offline background sync
        final syncRows = await db.select(db.syncQueue).get();
        expect(syncRows.any((s) => s.targetTable == 'restock_requests'), isTrue);
      });

      test('manual offline restock request enqueues with correct urgency', () async {
        final inventory = await stockService.getStockInventory(testWorkerId);
        final zinc = inventory.firstWhere((i) => i.itemCode == 'zinc_tabs');

        final req = await stockService.requestRestock(
          workerId: testWorkerId,
          itemId: zinc.id,
          requestedQuantity: 100.0,
          urgency: 'standard',
        );

        expect(req.requestedQuantity, equals(100.0));
        expect(req.urgency, equals('standard'));

        final list = await stockService.getPendingRestockRequests(testWorkerId);
        expect(list.any((r) => r.id == req.id), isTrue);
      });
    });

    // ── 4. Stock-Out Event & Backend Supply Chain (Requirement 30.6) ──────────
    group('Stock-Out Event Logging (Requirement 30.6)', () {
      setUp(() async {
        await stockService.seedDefaultAshaKitAndStock(testWorkerId);
      });

      test('dispensing to zero triggers critical stock-out event and priority sync queue entry', () async {
        final inventory = await stockService.getStockInventory(testWorkerId);
        final pcmSyrup = inventory.firstWhere((i) => i.itemCode == 'pcm_syrup');
        expect(pcmSyrup.currentQuantity, equals(8.0));

        // Dispense all 8 bottles
        final updated = await stockService.dispenseItem(
          itemId: pcmSyrup.id,
          quantityDispensed: 8.0,
        );

        expect(updated.currentQuantity, equals(0.0));
        expect(updated.isStockedOut, isTrue);

        // Verify stock_out_events table has the event
        final soRows = await db.customSelect('SELECT * FROM stock_out_events WHERE item_id = ?', variables: [Variable.withString(pcmSyrup.id)]).get();
        expect(soRows.length, equals(1));
        expect(soRows.first.read<String>('item_code'), equals('pcm_syrup'));

        // Verify sync_queue contains priority critical entry for backend supply chain dashboard
        final syncItems = await db.select(db.syncQueue).get();
        final stockOutSync = syncItems.firstWhere((s) => s.targetTable == 'stock_out_events');
        expect(stockOutSync.priority, equals(SyncPriority.critical.value));
      });
    });

    // ── 5. Hardware Fault Reporting (Requirement 30.4) ────────────────────────
    group('Device Fault Reporting (Requirement 30.4)', () {
      test('submits fault report with low battery and implausible readings, marking device faulty', () async {
        const devId = 'dev_bp_fault';
        const serialNo = 'BP-ERR-009';

        await stockService.registerKitItem(
          EquipmentKitItem(
            id: devId,
            workerId: testWorkerId,
            itemName: 'Digital Blood Pressure Monitor',
            serialNumber: serialNo,
            issueDate: DateTime(2025, 1, 1),
            status: EquipmentStatus.operational,
          ),
        );

        final report = await stockService.reportDeviceFault(
          workerId: testWorkerId,
          deviceId: devId,
          serialNumber: serialNo,
          faultDescription: 'Screen flickering and erratic pressure dump E-2 code',
          photoAttachmentPath: '/storage/emulated/0/DCIM/fault_bp.jpg',
          hasLowBatteryAlert: true,
          hasImplausibleReadingsPattern: true,
        );

        expect(report.serialNumber, equals(serialNo));
        expect(report.hasLowBatteryAlert, isTrue);
        expect(report.hasImplausibleReadingsPattern, isTrue);

        // Check that equipment item status changed to faulty
        final items = await stockService.getKitItems(testWorkerId);
        final item = items.firstWhere((e) => e.serialNumber == serialNo);
        expect(item.status, equals(EquipmentStatus.faulty));
        expect(item.notes, contains('Fault reported: Screen flickering'));

        // Check sync queue has fault report entry
        final syncRows = await db.select(db.syncQueue).get();
        expect(syncRows.any((s) => s.targetTable == 'device_fault_reports'), isTrue);
      });
    });

    // ── 6. UI Widget Test: StockManagementScreen ──────────────────────────────
    group('StockManagementScreen UI Widget', () {
      testWidgets('renders tabs, summary KPI cards, and consumable items cleanly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StockManagementScreen(
              stockService: stockService,
              workerId: testWorkerId,
              workerName: 'Sunita Devi (ASHA)',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check title and tabs
        expect(find.text('Stock & Equipment Hub'), findsOneWidget);
        expect(find.text('Sunita Devi (ASHA)'), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text('Total Tracked'), findsOneWidget);
        expect(find.text('Low Stock'), findsOneWidget);
        expect(find.text('Stocked Out'), findsOneWidget);

        // Check presence of items
        expect(find.text('IFA Tablets (Adult)'), findsOneWidget);
        expect(find.text('ORS Sachets'), findsOneWidget);

        // Switch to Kit tab
        await tester.tap(find.textContaining('Kit'));
        await tester.pumpAndSettle();

        expect(find.text('Digital Blood Pressure Monitor'), findsOneWidget);
        expect(find.text('Pulse Oximeter'), findsOneWidget);
        expect(find.text('Fault'), findsWidgets);
      });
    });
  });
}
