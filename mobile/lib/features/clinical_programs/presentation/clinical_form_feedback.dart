import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// User-safe feedback shared by every clinical-program form.
///
/// Technical database details stay in the diagnostic log and are never shown
/// beside patient data on a shared device.
void showClinicalSaveError(
  BuildContext context, {
  required String program,
  Object? error,
  VoidCallback? onRetry,
}) {
  if (error != null) {
    developer.log('Failed to save $program record', error: error);
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Could not save. Tap to retry.'),
        backgroundColor: Colors.red.shade800,
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
}

void showClinicalSaveErrorWithMessenger(
  ScaffoldMessengerState messenger, {
  required String program,
  Object? error,
  VoidCallback? onRetry,
}) {
  if (error != null) {
    developer.log('Failed to save $program record', error: error);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Could not save. Tap to retry.'),
        backgroundColor: Colors.red.shade800,
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
}

SnackBar clinicalSavedSnackBar({String message = 'Saved on this phone.'}) {
  return SnackBar(
    content: Text(message),
    backgroundColor: const Color(0xFF2D5F47),
  );
}

/// Persistent, readable patient context used below clinical-program app bars.
/// Keeping the full name out of the title prevents truncation on 360dp screens.
class ClinicalPatientContextCard extends StatelessWidget {
  const ClinicalPatientContextCard({
    super.key,
    required this.name,
    required this.details,
    this.contextLabel,
  });

  final String name;
  final String details;
  final String? contextLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFFE5F2EE),
              child: Icon(Icons.person_outline, color: Color(0xFF2D5F47)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111815),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    details,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5F6B64),
                    ),
                  ),
                  if (contextLabel != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      contextLabel!,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D5F47),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
