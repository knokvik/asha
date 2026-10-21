import 'package:flutter/material.dart';

import '../../domain/communication_launcher.dart';
import '../../domain/reminder_models.dart';

/// Modal bottom sheet allowing one-tap call and message actions to ANM, AF, MO, and helplines (Requirement 26.3, 26.6).
class OneTapContactSheet extends StatefulWidget {
  final List<SupervisorContact> contacts;
  final String? beneficiaryName;
  final String? beneficiaryPhone;
  final VoidCallback? onActionTriggered;

  const OneTapContactSheet({
    super.key,
    required this.contacts,
    this.beneficiaryName,
    this.beneficiaryPhone,
    this.onActionTriggered,
  });

  static Future<void> show(
    BuildContext context, {
    required List<SupervisorContact> contacts,
    String? beneficiaryName,
    String? beneficiaryPhone,
    VoidCallback? onActionTriggered,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OneTapContactSheet(
        contacts: contacts,
        beneficiaryName: beneficiaryName,
        beneficiaryPhone: beneficiaryPhone,
        onActionTriggered: onActionTriggered,
      ),
    );
  }

  @override
  State<OneTapContactSheet> createState() => _OneTapContactSheetState();
}

class _OneTapContactSheetState extends State<OneTapContactSheet> {
  final BeneficiaryTemplateType _selectedTemplate =
      BeneficiaryTemplateType.ancCheckup;
  final String _selectedLanguage = 'hi';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.quick_contacts_dialer_rounded,
                    color: Color(0xFF1B5E20),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency & Supervisor Contacts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Beneficiary Direct Actions (if provided)
              if (widget.beneficiaryName != null &&
                  widget.beneficiaryPhone != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beneficiary: ${widget.beneficiaryName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Phone: ${widget.beneficiaryPhone}'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('btn_call_beneficiary'),
                              onPressed: () {
                                CommunicationLauncher.buildPhoneUri(
                                  widget.beneficiaryPhone!,
                                );
                                widget.onActionTriggered?.call();
                              },
                              icon: const Icon(Icons.call, size: 20),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48), // 48dp target
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('btn_sms_beneficiary'),
                              onPressed: () {
                                final text =
                                    BeneficiaryMessageTemplates.formatMessage(
                                      type: _selectedTemplate,
                                      languageCode: _selectedLanguage,
                                      parameters: {
                                        'name': widget.beneficiaryName!,
                                        'date': 'today',
                                        'facility': 'Health Centre',
                                      },
                                    );
                                CommunicationLauncher.buildSmsUri(
                                  widget.beneficiaryPhone!,
                                  text,
                                );
                                widget.onActionTriggered?.call();
                              },
                              icon: const Icon(Icons.sms, size: 20),
                              label: const Text('SMS'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48), // 48dp target
                                foregroundColor: const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Supervisor List
              Text(
                'Clinical Support & Escalation',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),

              ...widget.contacts.map((contact) {
                final isEmergency =
                    contact.role.contains('EMERGENCY') ||
                    contact.phone == '108';

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isEmergency
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        isEmergency
                            ? Icons.local_hospital_rounded
                            : Icons.person_rounded,
                        color: isEmergency
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${contact.role.replaceAll("_", " ")} • ${contact.phone}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('btn_call_${contact.id}'),
                          icon: const Icon(
                            Icons.phone_forwarded,
                            color: Color(0xFF1B5E20),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            CommunicationLauncher.buildPhoneUri(contact.phone);
                            widget.onActionTriggered?.call();
                          },
                          tooltip: 'Call ${contact.name}',
                        ),
                        IconButton(
                          key: Key('btn_msg_${contact.id}'),
                          icon: const Icon(
                            Icons.message_rounded,
                            color: Color(0xFF1B5E20),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            CommunicationLauncher.buildSmsUri(
                              contact.phone,
                              'Urgent: Support needed from ASHA worker.',
                            );
                            widget.onActionTriggered?.call();
                          },
                          tooltip: 'Message ${contact.name}',
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
