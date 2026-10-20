import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 5: Triage Assessment matching the exact Asha Platform mobile design.
class TriageFlowScreen extends StatefulWidget {
  const TriageFlowScreen({super.key});

  @override
  State<TriageFlowScreen> createState() => _TriageFlowScreenState();
}

class _TriageFlowScreenState extends State<TriageFlowScreen> {
  int _currentStep = 1;
  final int _totalSteps = 8;
  int? _selectedAnswer; // 0: Yes, 1: No, 2: Not sure

  final List<_TriageQuestion> _questions = const [
    _TriageQuestion(
      question: 'Does she have severe headache with blurred vision?',
      isDangerSign: true,
    ),
    _TriageQuestion(
      question: 'Is there any vaginal bleeding or fluid leaking?',
      isDangerSign: true,
    ),
    _TriageQuestion(
      question: 'Does she have high fever or chills?',
      isDangerSign: true,
    ),
    _TriageQuestion(
      question: 'Are there convulsions or loss of consciousness?',
      isDangerSign: true,
    ),
    _TriageQuestion(
      question: 'Is there severe abdominal pain or contractions?',
      isDangerSign: true,
    ),
    _TriageQuestion(
      question: 'Does she feel reduced or absent fetal movements?',
      isDangerSign: false,
    ),
    _TriageQuestion(
      question: 'Is there swelling of face, hands, or legs (edema)?',
      isDangerSign: false,
    ),
    _TriageQuestion(
      question: 'Is systolic BP >= 140 or diastolic BP >= 90 mmHg?',
      isDangerSign: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentStep - 1];

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AshaColors.textPrimary),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
                _selectedAnswer = null;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Triage Assessment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AshaColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar: 1 / 8
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _currentStep / _totalSteps,
                        backgroundColor: AshaColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(AshaColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$_currentStep / $_totalSteps',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  const SizedBox(height: 10),

                  // Question Text: Bold, clear, large font
                  Text(
                    currentQ.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AshaColors.textPrimary,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SVG Illustration (Pregnant woman touching forehead in headache pain)
                  Center(
                    child: Container(
                      height: 175,
                      alignment: Alignment.center,
                      child: const AshaTriageHeadacheIllustrationWidget(height: 175),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Option 1: Yes (Red warning icon)
                  _buildOptionCard(
                    index: 0,
                    icon: Icons.warning_rounded,
                    iconColor: AshaColors.alertHighRisk,
                    label: 'Yes',
                    selectedBorderColor: AshaColors.alertHighRisk,
                    selectedBgColor: const Color(0xFFFEF2F2),
                  ),

                  const SizedBox(height: 12),

                  // Option 2: No (Green check icon)
                  _buildOptionCard(
                    index: 1,
                    icon: Icons.check_circle_rounded,
                    iconColor: AshaColors.vitalNormal,
                    label: 'No',
                    selectedBorderColor: AshaColors.vitalNormal,
                    selectedBgColor: const Color(0xFFF0FDF4),
                  ),

                  const SizedBox(height: 12),

                  // Option 3: Not sure (Question icon)
                  _buildOptionCard(
                    index: 2,
                    icon: Icons.help_outline_rounded,
                    iconColor: AshaColors.textSecondary,
                    label: 'Not sure',
                    selectedBorderColor: AshaColors.teleConsultBlue,
                    selectedBgColor: const Color(0xFFEFF6FF),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Navigation Buttons: Previous | Next
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AshaColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AshaColors.borderSubtle, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _currentStep > 1
                            ? () {
                                setState(() {
                                  _currentStep--;
                                  _selectedAnswer = null;
                                });
                              }
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back_rounded, size: 16, color: AshaColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AshaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Next button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AshaColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          if (_currentStep < _totalSteps) {
                            setState(() {
                              _currentStep++;
                              _selectedAnswer = null;
                            });
                          } else {
                            _completeTriage();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Next',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color selectedBorderColor,
    required Color selectedBgColor,
  }) {
    final isSelected = _selectedAnswer == index;

    return Material(
      color: isSelected ? selectedBgColor : AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedAnswer = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? selectedBorderColor : AshaColors.borderSubtle,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: AshaColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: selectedBorderColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _completeTriage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Triage Assessment Complete'),
        content: const Text(
          'Severe headache reported. Protocol suggests Blood Pressure check and emergency referral to Rampur PHC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AshaColors.alertHighRisk),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/referral/new');
            },
            child: const Text('Generate Referral Slip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TriageQuestion {
  const _TriageQuestion({required this.question, required this.isDangerSign});

  final String question;
  final bool isDangerSign;
}
