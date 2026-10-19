import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:triage/triage.dart';

/// The IMCI referral. The QR is the SMS line, which has no child name and no phone number.
class AdaptiveReferralScreen extends StatelessWidget {
  const AdaptiveReferralScreen({
    super.key,
    required this.decision,
    required this.note,
  });

  final HybridDecision decision;
  final ReferralNote note;

  @override
  Widget build(BuildContext context) {
    final flag = decision.flag.wireName;
    final color = switch (decision.flag) {
      TriageFlag.red => const Color(0xFF9F2D2D),
      TriageFlag.yellow => const Color(0xFF8A5A00),
      TriageFlag.green => const Color(0xFF0F6E56),
    };
    final sms = note.toSms();
    return Scaffold(
      appBar: AppBar(title: const Text('Referral QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            flag,
            key: const Key('triage_flag'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 8),
          Text(decision.flag.urgency, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Decision support from the on-device IMCI rules. A clinician confirms it. This is not a diagnosis. The voice page does not set this colour.',
            style: TextStyle(height: 1.35),
          ),
          if (decision.modelContribution.escalated) ...[
            const SizedBox(height: 8),
            Text(decision.modelContribution.note, style: const TextStyle(height: 1.35)),
          ],
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              key: const Key('triage_referral_qr'),
              data: sms,
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
          const SizedBox(height: 8),
          SelectableText(sms, key: const Key('triage_sms'), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          SelectableText(note.toMarkdown(), style: const TextStyle(fontSize: 14, height: 1.35)),
        ],
      ),
    );
  }
}
