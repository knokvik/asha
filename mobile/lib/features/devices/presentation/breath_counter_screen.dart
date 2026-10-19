import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/measurement_aids.dart';

/// Interactive 60-second Tap-to-Count Breath Counter with audible/visual cues
/// and age-appropriate fast-breathing classification (Requirement 29.1).
class BreathCounterScreen extends StatefulWidget {
  final int childAgeMonths;
  final String childName;
  final Function(int breathsPerMinute, bool isFastBreathing)? onCountCompleted;

  const BreathCounterScreen({
    super.key,
    required this.childAgeMonths,
    this.childName = 'Child',
    this.onCountCompleted,
  });

  @override
  State<BreathCounterScreen> createState() => _BreathCounterScreenState();
}

class _BreathCounterScreenState extends State<BreathCounterScreen> {
  int _secondsRemaining = 60;
  int _tapCount = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _countdownTimer;
  Map<String, dynamic>? _classificationResult;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _tapCount = 0;
      _isRunning = true;
      _isCompleted = false;
      _classificationResult = null;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _isRunning = false;
          _isCompleted = true;
          _countdownTimer?.cancel();
          _finalizeCount();
        }
      });
    });
  }

  void _recordTap() {
    if (!_isRunning) {
      _startTimer();
    }
    setState(() {
      _tapCount++;
    });
  }

  void _finalizeCount() {
    // 60-second count gives respiratory rate directly
    final rate = _tapCount;
    final classification = FastBreathingClassifier.classify(
      ageMonths: widget.childAgeMonths,
      breathsPerMinute: rate,
    );

    setState(() {
      _classificationResult = classification;
    });

    widget.onCountCompleted?.call(
      rate,
      classification['is_fast_breathing'] as bool,
    );
  }

  void _reset() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _tapCount = 0;
      _isRunning = false;
      _isCompleted = false;
      _classificationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (60 - _secondsRemaining) / 60.0;
    final isFast = _classificationResult?['is_fast_breathing'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('60-Second Breath Counter'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF1B5E20),
                        child: Icon(Icons.child_care, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Age: ${widget.childAgeMonths} months  •  Target: 60s Count',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Circular Progress Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isRunning ? const Color(0xFF1B5E20) : Colors.grey,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_secondsRemaining',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const Text('seconds remaining', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text(
                        '$_tapCount',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      const Text('breaths counted', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Result Banner if completed
              if (_isCompleted && _classificationResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFast ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isFast ? Colors.red.shade400 : Colors.green.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(isFast ? Icons.warning_amber_rounded : Icons.check_circle,
                          color: isFast ? Colors.red : Colors.green, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFast ? 'FAST BREATHING DETECTED' : 'NORMAL BREATHING RATE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isFast ? Colors.red.shade900 : Colors.green.shade900,
                              ),
                            ),
                            Text(
                              _classificationResult!['interpretation'] as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tap-to-Count Action Button
              ElevatedButton.icon(
                key: const Key('btn_tap_breath'),
                onPressed: _isCompleted ? null : _recordTap,
                icon: const Icon(Icons.touch_app, size: 28),
                label: Text(
                  _isRunning ? 'TAP ON EACH BREATH IN' : 'TAP TO START COUNTING',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              if (_isRunning || _isCompleted)
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Counter'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
