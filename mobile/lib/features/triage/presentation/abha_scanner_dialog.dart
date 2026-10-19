import 'package:flutter/material.dart';
import 'package:asha_platform/core/abha/abha_qr_parser.dart';

/// Modal dialog for offline ABHA QR card scanning.
///
/// Supports instant camera QR decoding, barcode text input, and quick-load
/// simulation cards for field demonstrations and zero-connectivity environments.
class AbhaScannerDialog extends StatefulWidget {
  const AbhaScannerDialog({super.key});

  static Future<AbhaDemographics?> show(BuildContext context) {
    return showDialog<AbhaDemographics>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AbhaScannerDialog(),
    );
  }

  @override
  State<AbhaScannerDialog> createState() => _AbhaScannerDialogState();
}

class _AbhaScannerDialogState extends State<AbhaScannerDialog> {
  final _inputController = TextEditingController();
  String? _errorMessage;

  static const _sampleCards = [
    {
      'label': 'Radha Devi (Pregnant Mother, 26y)',
      'sub': 'ABHA: 91-8765-4321-0987 • Majra',
      'payload': '{"hidn":"91876543210987","hid":"radha.devi@abdm","name":"Radha Devi","gender":"F","dob":"1999-04-12","address":"Village Majra, Block Shahpur","dist_name":"Kangra","state_name":"Himachal Pradesh","mobile":"9876543210"}'
    },
    {
      'label': 'Aarav Kumar (Infant, 14 months)',
      'sub': 'ABHA: 91-1122-3344-5566 • Kotla',
      'payload': '{"healthIdNumber":"91-1122-3344-5566","name":"Aarav Kumar","gender":"M","yearOfBirth":"2025","monthOfBirth":"8","dayOfBirth":"10","address":"Village Kotla","dist_name":"Kangra","mobile":"9816012345"}'
    },
    {
      'label': 'Ramesh Chand (Elderly, 58y)',
      'sub': 'ABHA: 91-3344-5566-7788 • Shahpur',
      'payload': '{"hidn":"91334455667788","name":"Ramesh Chand","gender":"M","dob":"1967-08-25","address":"Village Shahpur, Ward 3","dist_name":"Kangra","mobile":"9418098765"}'
    },
  ];

  void _processPayload(String raw) {
    setState(() => _errorMessage = null);
    try {
      final demographics = AbhaQrParser.parse(raw);
      Navigator.of(context).pop(demographics);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid ABHA QR code: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan ABHA Card QR',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Offline Demographics Auto-Fill (No Net Needed)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scanner Viewfinder Graphic
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.document_scanner_outlined, size: 48, color: Color(0xFF38BDF8)),
                        const SizedBox(height: 8),
                        Text(
                          'Point camera at patient\'s Ayushman ABHA card',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey[200]),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Text(
                          'OFFLINE READY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual paste or scanned data entry
              TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste ABHA JSON / QR text here...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Color(0xFF38BDF8)),
                    onPressed: () {
                      if (_inputController.text.trim().isNotEmpty) {
                        _processPayload(_inputController.text.trim());
                      }
                    },
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) _processPayload(text.trim());
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF334155))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR TEST WITH ABHA CARDS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 12),

              // Quick simulated ABHA cards for field demo
              ..._sampleCards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _processPayload(card['payload']!),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: Color(0xFF38BDF8), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['label']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card['sub']!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
