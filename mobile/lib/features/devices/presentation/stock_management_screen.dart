import 'package:flutter/material.dart';
import '../data/stock_service.dart';
import '../domain/stock_models.dart';

/// Stock and Equipment Management Screen (Requirements 30.1 – 30.6).
///
/// Features:
/// 1. Consumable Stock: Real-time inventory, dispensing log, estimated run-out dates, and threshold alerts.
/// 2. Medical Equipment Kit: Serial numbers, issue dates, and fault reporting.
/// 3. Calibration & Replacement Due List: ANM supervisor workspace for device maintenance.
class StockManagementScreen extends StatefulWidget {
  final StockService stockService;
  final String workerId;
  final String workerName;

  const StockManagementScreen({
    super.key,
    required this.stockService,
    required this.workerId,
    this.workerName = 'Sunita Devi (ASHA)',
  });

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<StockItemWithRunOut> _inventory = [];
  List<EquipmentKitItem> _equipmentKit = [];
  List<EquipmentKitItem> _calibrationDueList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await widget.stockService.ensureStockTablesExist();
    await widget.stockService.seedDefaultAshaKitAndStock(widget.workerId);

    final inv = await widget.stockService.getStockInventory(widget.workerId);
    final kit = await widget.stockService.getKitItems(widget.workerId);
    final cal = await widget.stockService.getEquipmentDueForCalibration(workerId: widget.workerId);

    if (mounted) {
      setState(() {
        _inventory = inv;
        _equipmentKit = kit;
        _calibrationDueList = cal;
        _isLoading = false;
      });
    }
  }

  // ── Dispense Dialog ─────────────────────────────────────────────────────────

  Future<void> _showDispenseDialog(StockItemWithRunOut item) async {
    final qtyController = TextEditingController(text: '1.0');
    final memberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dispense ${item.itemName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock: ${item.currentQuantity.toStringAsFixed(1)} ${item.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity to Dispense (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memberController,
                decoration: const InputDecoration(
                  labelText: 'Beneficiary Name / ID (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 1.0;
              if (qty <= 0) return;
              Navigator.pop(ctx);

              final updated = await widget.stockService.dispenseItem(
                itemId: item.id,
                quantityDispensed: qty,
                relatedMemberId: memberController.text.isNotEmpty ? memberController.text : null,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dispensed $qty ${item.unit}. Remaining: ${updated.currentQuantity.toStringAsFixed(1)} ${item.unit}',
                    ),
                    backgroundColor: updated.isStockedOut
                        ? Colors.red.shade700
                        : updated.isBelowThreshold
                            ? Colors.amber.shade800
                            : Colors.green.shade700,
                  ),
                );
                await _loadData();
              }
            },
            child: const Text('Dispense'),
          ),
        ],
      ),
    );
  }

  // ── Manual Restock Request Dialog ───────────────────────────────────────────

  Future<void> _showRestockDialog(StockItemWithRunOut item) async {
    final qtyController = TextEditingController(text: '${(item.minThreshold * 3).toInt()}');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Restock: ${item.itemName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${item.currentQuantity.toStringAsFixed(1)} ${item.unit}'),
            Text('Minimum Threshold: ${item.minThreshold.toStringAsFixed(1)} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Requested Quantity (${item.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 20.0;
              Navigator.pop(ctx);

              final req = await widget.stockService.requestRestock(
                workerId: widget.workerId,
                itemId: item.id,
                requestedQuantity: qty,
                urgency: item.isStockedOut ? 'critical_stockout' : 'standard',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Offline restock request for ${req.requestedQuantity} ${req.unit} queued for sync.'),
                    backgroundColor: Colors.blue.shade700,
                  ),
                );
                await _loadData();
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  // ── Hardware Fault Report Dialog ────────────────────────────────────────────

  Future<void> _showFaultReportDialog(EquipmentKitItem item) async {
    final descController = TextEditingController();
    bool lowBattery = false;
    bool implausibleReadings = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Report Fault: ${item.itemName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Serial Number: ${item.serialNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Low Battery Warning Pattern'),
                  subtitle: const Text('Repeated device alerts or rapid drain'),
                  value: lowBattery,
                  onChanged: (v) => setDialogState(() => lowBattery = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Implausible Readings Pattern'),
                  subtitle: const Text('Erratic or physically impossible values'),
                  value: implausibleReadings,
                  onChanged: (v) => setDialogState(() => implausibleReadings = v ?? false),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Fault Description',
                    hintText: 'Describe physical damage, error codes, or symptoms',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              onPressed: () async {
                if (descController.text.trim().isEmpty) return;
                Navigator.pop(ctx);

                await widget.stockService.reportDeviceFault(
                  workerId: widget.workerId,
                  deviceId: item.id,
                  serialNumber: item.serialNumber,
                  faultDescription: descController.text.trim(),
                  hasLowBatteryAlert: lowBattery,
                  hasImplausibleReadingsPattern: implausibleReadings,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fault report enqueued. Equipment marked faulty for supervisor inspection.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  await _loadData();
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  // ── ANM Calibration & Replacement Verification Dialog ───────────────────────

  Future<void> _showCalibrationActionDialog(EquipmentKitItem item) async {
    final serialController = TextEditingController(text: item.serialNumber);
    final notesController = TextEditingController();
    bool isReplaced = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Maintain: ${item.itemName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current S/N: ${item.serialNumber}'),
                const SizedBox(height: 12),
                RadioListTile<bool>(
                  title: const Text('Calibrated & Verified'),
                  subtitle: const Text('Device verified functional; schedule next calibration (+1 year)'),
                  value: false,
                  groupValue: isReplaced,
                  onChanged: (v) => setDialogState(() => isReplaced = v ?? false),
                ),
                RadioListTile<bool>(
                  title: const Text('Replaced with New Unit'),
                  subtitle: const Text('Old unit retired; assign new serial number'),
                  value: true,
                  groupValue: isReplaced,
                  onChanged: (v) => setDialogState(() => isReplaced = v ?? false),
                ),
                if (isReplaced) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: serialController,
                    decoration: const InputDecoration(
                      labelText: 'New Serial Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ANM Notes / Verification Remark',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final nextDue = DateTime.now().add(const Duration(days: 365));

                await widget.stockService.recordCalibrationOrReplacement(
                  itemId: item.id,
                  replaced: isReplaced,
                  newSerialNumber: isReplaced ? serialController.text.trim() : null,
                  nextCalibrationDueDate: nextDue,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isReplaced ? 'Device marked replaced.' : 'Device calibrated & verified.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadData();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock & Equipment Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.workerName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.medication),
              text: 'Consumables (${_inventory.length})',
            ),
            Tab(
              icon: const Icon(Icons.medical_services),
              text: 'Kit (${_equipmentKit.length})',
            ),
            Tab(
              icon: const Icon(Icons.build_circle),
              text: 'Due Service (${_calibrationDueList.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsumablesTab(theme),
                _buildKitTab(theme),
                _buildCalibrationTab(theme),
              ],
            ),
    );
  }

  // ── Tab 1: Consumables & Stock ──────────────────────────────────────────────

  Widget _buildConsumablesTab(ThemeData theme) {
    final lowStockCount = _inventory.where((i) => i.isBelowThreshold).length;
    final stockOutCount = _inventory.where((i) => i.isStockedOut).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // KPI Summary Row
          Row(
            children: [
              _buildKpiCard('Total Tracked', '${_inventory.length}', Colors.blue.shade700),
              const SizedBox(width: 8),
              _buildKpiCard('Low Stock', '$lowStockCount', Colors.amber.shade800),
              const SizedBox(width: 8),
              _buildKpiCard('Stocked Out', '$stockOutCount', Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          ..._inventory.map((item) {
            final isCritical = item.isStockedOut;
            final isWarning = item.isBelowThreshold && !item.isStockedOut;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isCritical
                      ? Colors.red
                      : isWarning
                          ? Colors.amber.shade700
                          : Colors.grey.shade300,
                  width: isCritical || isWarning ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Code: ${item.itemCode.toUpperCase()} • Min Threshold: ${item.minThreshold.toStringAsFixed(0)} ${item.unit}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCritical
                                ? Colors.red.shade100
                                : isWarning
                                    ? Colors.amber.shade100
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${item.currentQuantity.toStringAsFixed(1)} ${item.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCritical
                                  ? Colors.red.shade900
                                  : isWarning
                                      ? Colors.amber.shade900
                                      : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Run-out estimate banner
                    if (item.daysUntilRunOut != null) ...[
                      Row(
                        children: [
                          Icon(Icons.hourglass_bottom, size: 16, color: Colors.blueGrey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Est. run-out: ${item.daysUntilRunOut} days (${item.estimatedRunOutDate?.toLocal().toString().split(' ')[0]})',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
                          ),
                        ],
                      ),
                    ] else if (item.isStockedOut) ...[
                      const Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'STOCKED OUT — Immediate Restock Required',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'No recent consumption logged • Stock stable',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Restock'),
                          onPressed: () => _showRestockDialog(item),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.remove_circle_outline, size: 16),
                          label: const Text('Dispense'),
                          onPressed: () => _showDispenseDialog(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Tab 2: Equipment Kit ────────────────────────────────────────────────────

  Widget _buildKitTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _equipmentKit.length,
        itemBuilder: (ctx, i) {
          final eq = _equipmentKit[i];
          final isFaulty = eq.status == EquipmentStatus.faulty;
          final isCalDue = eq.isCalibrationDue(DateTime.now());

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: isFaulty
                    ? Colors.red.shade100
                    : isCalDue
                        ? Colors.amber.shade100
                        : Colors.blue.shade100,
                child: Icon(
                  isFaulty
                      ? Icons.error
                      : isCalDue
                          ? Icons.warning
                          : Icons.check_circle,
                  color: isFaulty
                      ? Colors.red
                      : isCalDue
                          ? Colors.amber.shade900
                          : Colors.blue.shade900,
                ),
              ),
              title: Text(eq.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Serial No: ${eq.serialNumber}'),
                  Text('Issued: ${eq.issueDate.toLocal().toString().split(' ')[0]}'),
                  if (eq.calibrationDueDate != null)
                    Text('Next Calibration: ${eq.calibrationDueDate!.toLocal().toString().split(' ')[0]}'),
                  if (eq.notes != null)
                    Text('Notes: ${eq.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.report_problem, size: 16),
                label: const Text('Fault'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                onPressed: () => _showFaultReportDialog(eq),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 3: Calibration & Replacement Due ────────────────────────────────────

  Widget _buildCalibrationTab(ThemeData theme) {
    if (_calibrationDueList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 56, color: Colors.green),
            SizedBox(height: 12),
            Text(
              'All Equipment Valid & Operational',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text('No devices currently due for calibration or replacement.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _calibrationDueList.length,
      itemBuilder: (ctx, i) {
        final eq = _calibrationDueList[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(eq.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eq.status == EquipmentStatus.faulty ? Colors.red.shade100 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        eq.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eq.status == EquipmentStatus.faulty ? Colors.red.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('S/N: ${eq.serialNumber} • Issued: ${eq.issueDate.toLocal().toString().split(' ')[0]}'),
                if (eq.notes != null) Text('Reason: ${eq.notes}'),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verify / Replace (ANM)'),
                    onPressed: () => _showCalibrationActionDialog(eq),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
