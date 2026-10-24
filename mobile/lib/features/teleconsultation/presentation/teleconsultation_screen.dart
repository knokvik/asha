import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/teleconsultation_service.dart';

class TeleconsultationScreen extends StatefulWidget {
  final String ashaName;
  final String anmPhone;
  final String moPhone;
  final String afPhone;

  const TeleconsultationScreen({
    super.key,
    this.ashaName = 'Sunita Sharma',
    this.anmPhone = '+91 98765 44332',
    this.moPhone = '+91 98765 88776',
    this.afPhone = '+91 94150 11201',
  });

  @override
  State<TeleconsultationScreen> createState() => _TeleconsultationScreenState();
}

class _TeleconsultationScreenState extends State<TeleconsultationScreen> {
  final _service = TeleconsultationService();
  static const _storage = FlutterSecureStorage();
  static const _kPeerMessagesKey = 'clinical_peer_messages_v1';

  bool _consentChecked = false;
  String _patientCodedId = 'MEM-RCH-8921';
  String _chiefComplaint =
      'Fever with respiratory rate 62/min in 25-day infant';
  String? _generatedNote;

  List<PeerMessage> _peerMessages = [
    PeerMessage(
      id: 'p1',
      senderName: 'Sunita Devi (Majra)',
      senderRole: 'ASHA',
      contentText: 'Has anyone faced hesitancy with MR vaccine in Ward 4? Mother worried about slight fever.',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      isModerated: true,
    ),
    PeerMessage(
      id: 'p2',
      senderName: 'Sarita Singh (AF)',
      senderRole: 'Facilitator',
      contentText: 'Remember module on supportive counselling: acknowledge her care first, then explain paracetamol drops.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      isModerated: true,
    ),
    PeerMessage(
      id: 'p3',
      senderName: 'Dr. Verma (PHC MO)',
      senderRole: 'Medical Officer',
      contentText: 'Active dengue surveillance in Ward 3. Refer any high fever with petechiae/rash immediately via 108.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 45)),
      isModerated: true,
    ),
  ];

  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredPeerMessages();
  }

  Future<void> _loadStoredPeerMessages() async {
    try {
      final raw = await _storage.read(key: _kPeerMessagesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        if (decoded.isNotEmpty && mounted) {
          setState(() {
            _peerMessages = decoded.map((m) {
              return PeerMessage(
                id: m['id'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
                senderName: m['senderName'] ?? widget.ashaName,
                senderRole: m['senderRole'] ?? 'ASHA',
                contentText: m['contentText'] ?? '',
                sentAt: DateTime.tryParse(m['sentAt'] ?? '') ?? DateTime.now(),
                isModerated: m['isModerated'] ?? true,
              );
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _persistPeerMessages() async {
    try {
      final encoded = jsonEncode(
        _peerMessages
            .map(
              (m) => {
                'id': m.id,
                'senderName': m.senderName,
                'senderRole': m.senderRole,
                'contentText': m.contentText,
                'sentAt': m.sentAt.toIso8601String(),
                'isModerated': m.isModerated,
              },
            )
            .toList(),
      );
      await _storage.write(key: _kPeerMessagesKey, value: encoded);
    } catch (_) {}
  }

  Future<void> _dialPhone(String phone, {String? label}) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dialing ${label ?? clean} ($phone) on phone dialer...',
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendSmsTo(String phone, String body) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final encodedBody = Uri.encodeComponent(body);
    final uri = Uri.parse('sms:$clean?body=$encodedBody');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Opening SMS to $phone...')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clinical Support & Helplines',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. One-Tap Emergency Helplines (Req 38.1)
          const Text(
            'Emergency Speed Dial (Works over Voice / Zero Data)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHelplineButton(
                  title: '108 Ambulance',
                  subtitle: 'Emergency FRU',
                  color: Colors.red,
                  type: HelplineType.emergencyAmbulance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHelplineButton(
                  title: '102 Transport',
                  subtitle: 'Obstetric / Delivery',
                  color: Colors.pink,
                  type: HelplineType.obstetricTransport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHelplineButton(
                  title: '104 Health Advice',
                  subtitle: 'Clinical Guidance',
                  color: Colors.blue,
                  type: HelplineType.healthAdvice104,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHelplineButton(
                  title: '14416 Tele-MANAS',
                  subtitle: 'Mental Health Support',
                  color: Colors.teal,
                  type: HelplineType.mentalHealthKiran,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHelplineButton(
                  title: '1098 Childline',
                  subtitle: 'Child Emergency',
                  color: Colors.orange,
                  type: HelplineType.childlineEmergency,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHelplineButton(
                  title: '112 Unified Police/FRU',
                  subtitle: 'All-in-One Helpline',
                  color: Colors.indigo,
                  type: HelplineType.nationalEmergency112,
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // 2. Direct Assigned Health Staff (Req 38.1)
          const Text(
            'Assigned Facility Clinical Team',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text('Sub-centre ANM (Kavita Kumari)'),
                  subtitle: Text(widget.anmPhone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.teal,
                        ),
                        tooltip: 'Send SMS',
                        onPressed: () => _sendSmsTo(
                          widget.anmPhone,
                          'Namaste ANM Didi, need urgent clinical advice from Sunita Sharma.',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Call ANM',
                        onPressed: () => _dialPhone(
                          widget.anmPhone,
                          label: 'ANM Kavita Kumari',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.local_hospital, color: Colors.white),
                  ),
                  title: const Text('PHC Medical Officer (Dr. Verma)'),
                  subtitle: Text(widget.moPhone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.teal,
                        ),
                        tooltip: 'Send SMS',
                        onPressed: () => _sendSmsTo(
                          widget.moPhone,
                          'Respected Doctor, clinical consultation request regarding patient in Ward 3.',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.indigo),
                        tooltip: 'Call MO',
                        onPressed: () => _dialPhone(
                          widget.moPhone,
                          label: 'Dr. Verma (PHC MO)',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.supervisor_account, color: Colors.white),
                  ),
                  title: const Text('ASHA Facilitator (Sarita Singh)'),
                  subtitle: Text(widget.afPhone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.teal,
                        ),
                        tooltip: 'Send SMS',
                        onPressed: () => _sendSmsTo(
                          widget.afPhone,
                          'Didi, submitting monthly register queries.',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.phone, color: Colors.amber.shade800),
                        tooltip: 'Call AF',
                        onPressed: () => _dialPhone(
                          widget.afPhone,
                          label: 'Sarita Singh (AF)',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // 3. Async Case Sharing & e-Sanjeevani (Req 38.2, 38.4)
          const Text(
            'Async Case Sharing & e-Sanjeevani Linkage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Formats minimal necessary clinical note for WhatsApp / SMS advice.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Patient Coded ID',
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _patientCodedId),
                    onChanged: (v) => _patientCodedId = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint & Vitals',
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _chiefComplaint),
                    onChanged: (v) => _chiefComplaint = v,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Beneficiary consent obtained to share clinical summary (Req 38.4)',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _consentChecked,
                    onChanged: (v) =>
                        setState(() => _consentChecked = v ?? false),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 390;
                      final generateButton = ElevatedButton.icon(
                        icon: const Icon(Icons.content_copy),
                        label: const Text('Generate Case Note'),
                        onPressed: () {
                          try {
                            final note = _service.formatAsyncCaseSharingNote(
                              patientCodedId: _patientCodedId,
                              ageGender: '25d / M',
                              primaryComplaint: _chiefComplaint,
                              vitals: {'respRate': 62, 'temp': 100.8},
                              redFlags: ['FAST_BREATHING_NEONATE'],
                              hasBeneficiaryConsent: _consentChecked,
                            );
                            setState(() => _generatedNote = note);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                      );
                      final sanjeevaniButton = OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('e-Sanjeevani'),
                        onPressed: () {
                          final link = _service.generateESanjeevaniLink(
                            patientCodedId: _patientCodedId,
                            chiefComplaint: _chiefComplaint,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Opening e-Sanjeevani Teleconsultation: $link',
                              ),
                            ),
                          );
                        },
                      );
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            generateButton,
                            const SizedBox(height: 8),
                            sanjeevaniButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: generateButton),
                          const SizedBox(width: 8),
                          Expanded(child: sanjeevaniButton),
                        ],
                      );
                    },
                  ),
                  if (_generatedNote != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _generatedNote!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 32),

          // 4. Moderated Peer Support Group (Req 38.3)
          const Text(
            'Moderated ASHA Peer Support Group',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Safe community Q&A with colleagues and facilitators.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ..._peerMessages.map(
            (msg) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: msg.senderRole == 'Facilitator'
                      ? Colors.amber.shade100
                      : Colors.blue.shade100,
                  child: Text(msg.senderName.substring(0, 1)),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      msg.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Chip(
                      label: Text(
                        msg.senderRole,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  msg.contentText,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Ask a question to peer group...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  if (_textController.text.trim().isNotEmpty) {
                    setState(() {
                      _peerMessages.add(
                        _service.createPeerMessage(
                          senderName: widget.ashaName,
                          contentText: _textController.text.trim(),
                          containsPatientData: false,
                        ),
                      );
                    });
                    _persistPeerMessages();
                    _textController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineButton({
    required String title,
    required String subtitle,
    required Color color,
    required HelplineType type,
  }) {
    final phone = TeleconsultationService.helplineNumbers[type] ?? '108';
    return Card(
      key: Key('dial_${phone}_button'),
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _dialPhone(phone, label: title);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(Icons.call, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
