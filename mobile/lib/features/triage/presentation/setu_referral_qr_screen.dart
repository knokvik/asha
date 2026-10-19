import 'package:core_referral/core_referral.dart';
import 'package:core_triage/core_triage.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/setu_case.dart';

/// The Setu referral, on screen and as a QR the facility can scan.
class SetuReferralQrScreen extends StatelessWidget {
  const SetuReferralQrScreen({
    super.key,
    required this.note,
    required this.result,
  });

  final ReferralNote note;
  final ClinicalTriageResult result;

  @override
  Widget build(BuildContext context) {
    final qrText = referralQrText(note);
    final band = result.band.wireName;
    final color = switch (result.band) {
      TriageBand.red => const Color(0xFF9F2D2D),
      TriageBand.yellow => const Color(0xFF8A5A00),
      TriageBand.green => const Color(0xFF0F6E56),
      _ => const Color(0xFF5C564C),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Referral QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            band,
            key: const Key('setu_band'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 8),
          const Text(
            'Decision support from the Setu rules. A clinician confirms it. This is not a diagnosis.',
            style: TextStyle(height: 1.35),
          ),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              key: const Key('setu_referral_qr'),
              data: qrText,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The code is the referral. It leaves out the child’s name and any phone number.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 16),
          SelectableText(note.plainText, style: const TextStyle(fontSize: 14, height: 1.35)),
        ],
      ),
    );
  }
}
