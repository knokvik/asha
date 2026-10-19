import 'package:flutter/material.dart';
import '../data/ble_service.dart';
import '../domain/ble_models.dart';

/// Screen for capturing physiological measurements from BLE medical devices
/// with automatic plausibility bounds checking and instant manual fallback (Requirements 28.1 – 28.7).
class MeasurementCaptureScreen extends StatefulWidget {
  final DeviceProfileConfig profile;
  final String patientId;
  final String patientName;
  final String workerId;
  final BleService? bleService;
  final Function(DeviceMeasurementRecord record)? onMeasurementSaved;

  const MeasurementCaptureScreen({
    super.key,
    required this.profile,
    required this.patientId,
    required this.patientName,
    required this.workerId,
    this.bleService,
    this.onMeasurementSaved,
  });

  @override
  State<MeasurementCaptureScreen> createState() => _MeasurementCaptureScreenState();
}

class _MeasurementCaptureScreenState extends State<MeasurementCaptureScreen> {
  late final BleService _bleService;
  bool _isManualMode = false;
  double? _primaryValue;
  double? _secondaryValue;
  String? _activeDeviceId;
  String? _activeDeviceName;
  String? _validationWarning;

  final TextEditingController _primaryInputController = TextEditingController();
  final TextEditingController _secondaryInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bleService = widget.bleService ?? BleService();
  }

  @override
  void dispose() {
    // Critical battery conservation: disconnect BLE immediately when screen is disposed (Requirement 28.6)
    _bleService.disconnect();
    _primaryInputController.dispose();
    _secondaryInputController.dispose();
    super.dispose();
  }

  void _validateCurrentValues() {
    if (_primaryValue == null) {
      setState(() => _validationWarning = null);
      return;
    }

    final isPlausible = widget.profile.isPlausible(_primaryValue!, _secondaryValue);
    setState(() {
      _validationWarning = isPlausible
          ? null
          : widget.profile.getValidationWarning(_primaryValue!, _secondaryValue);
    });
  }

  void _saveMeasurement() {
    if (_primaryValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or capture a measurement value first.')),
      );
      return;
    }

    final isPlausible = widget.profile.isPlausible(_primaryValue!, _secondaryValue);

    // Out-of-range bounds gate (Requirement 28.3)
    if (!isPlausible) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Physiological Out of Bounds'),
            ],
          ),
          content: Text(
            widget.profile.getValidationWarning(_primaryValue!, _secondaryValue) ??
                'This reading is outside normal physiological bounds.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Remeasure Now'),
            ),
          ],
        ),
      );
      return;
    }

    // Provenance Tagging & Attribution (Requirements 28.4, 28.7)
    final record = BleService.createMeasurementRecord(
      profile: widget.profile,
      value: _primaryValue!,
      secondaryValue: _secondaryValue,
      deviceId: _isManualMode ? null : _activeDeviceId,
      deviceName: _isManualMode ? 'Manual Entry' : _activeDeviceName,
      patientId: widget.patientId, // Associated with active patient
      authenticatedWorkerId: widget.workerId, // Authenticated ASHA
      isManual: _isManualMode || _activeDeviceId == null,
    );

    widget.onMeasurementSaved?.call(record);
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final isBp = widget.profile.measurementType == MeasurementType.bloodPressure;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.deviceName),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          // Manual Fallback Toggle Button (Requirement 28.2)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isManualMode = !_isManualMode;
              });
            },
            icon: Icon(
              _isManualMode ? Icons.bluetooth : Icons.edit,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _isManualMode ? 'Switch to BLE' : 'Manual Entry',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient Info Card ─────────────────────────────────────────────
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF1B5E20),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Target: ${widget.profile.measurementType.label} (${widget.profile.unit})',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Provenance & Source Tag Badge (Requirements 28.1, 28.4) ──────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isManualMode ? Colors.amber.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isManualMode ? Colors.amber.shade400 : Colors.blue.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isManualMode ? Icons.edit_note : Icons.bluetooth_connected,
                    color: _isManualMode ? Colors.amber.shade900 : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isManualMode
                          ? 'Source: MANUAL ENTRY (No hardware required)'
                          : 'Source: BLE ${_activeDeviceId != null ? '($_activeDeviceId)' : '(Ready to pair)'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isManualMode ? Colors.amber.shade900 : Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Measurement Value Inputs / Readings ───────────────────────────
            if (_isManualMode) ...[
              // Manual Numeric Entry Fields
              TextField(
                controller: _primaryInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isBp ? 'Systolic BP (mmHg)' : 'Measured Value (${widget.profile.unit})',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.speed),
                ),
                onChanged: (val) {
                  _primaryValue = double.tryParse(val);
                  _validateCurrentValues();
                },
              ),
              if (isBp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _secondaryInputController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Diastolic BP (mmHg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  onChanged: (val) {
                    _secondaryValue = double.tryParse(val);
                    _validateCurrentValues();
                  },
                ),
              ],
            ] else ...[
              // BLE Reading Display Card
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _primaryValue != null
                            ? (isBp
                                ? '${_primaryValue!.round()} / ${_secondaryValue?.round() ?? '--'}'
                                : '$_primaryValue')
                            : '--',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _primaryValue != null ? const Color(0xFF1B5E20) : Colors.grey,
                        ),
                      ),
                      Text(
                        widget.profile.unit,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Simulate mock BLE GATT reading for testing / demo
                          setState(() {
                            _activeDeviceId = 'DEV-BLE-9981';
                            _activeDeviceName = widget.profile.deviceName;
                            if (isBp) {
                              _primaryValue = 120.0;
                              _secondaryValue = 80.0;
                            } else if (widget.profile.measurementType == MeasurementType.pulseOximetry) {
                              _primaryValue = 98.0;
                              _secondaryValue = 72.0;
                            } else {
                              _primaryValue = (widget.profile.minPlausible + widget.profile.maxPlausible) / 2.0;
                            }
                            _validateCurrentValues();
                          });
                        },
                        icon: const Icon(Icons.sensors),
                        label: const Text('Capture BLE Reading'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Out-of-Bounds Physiological Warning (Requirement 28.3) ────────
            if (_validationWarning != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationWarning!,
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ── Save Button ───────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _saveMeasurement,
              icon: const Icon(Icons.check),
              label: const Text('Save & Tag Measurement'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
