import 'package:flutter/material.dart';
import 'package:asha_platform/core/voice/indic_asr_service.dart';
import 'package:asha_platform/core/voice/indic_extractor.dart';

/// Interactive modal sheet for Indic voice input in Hindi, Marathi, and English.
class VoiceInputSheet extends StatefulWidget {
  const VoiceInputSheet({super.key});

  static Future<Map<String, bool>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const VoiceInputSheet(),
    );
  }

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  final _asrService = IndicAsrService();
  final _textController = TextEditingController();
  List<ExtractedSymptom> _extractedSymptoms = [];
  bool _isListening = false;

  void _onTextChange(String text) {
    setState(() {
      _extractedSymptoms = _asrService.processSpeech(text);
    });
  }

  void _applyUtterance(String text) {
    _textController.text = text;
    _onTextChange(text);
  }

  void _confirmAndApply() {
    final questionMap = _asrService.mapSymptomsToQuestions(_extractedSymptoms);
    Navigator.of(context).pop(questionMap);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mic, color: Color(0xFF818CF8), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indic Voice Clinical Input',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'बोलकर बताएं (Hindi / Marathi / English) • Offline NLP',
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
          const SizedBox(height: 16),

          // Live Text Field with Mic Pulse
          TextField(
            controller: _textController,
            maxLines: 3,
            onChanged: _onTextChange,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'उदा. "बच्चे को तेज बुखार और उल्टी है, लेकिन दौरा नहीं आया..."',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? const Color(0xFFF43F5E) : const Color(0xFF818CF8),
                ),
                onPressed: () {
                  setState(() => _isListening = !_isListening);
                  if (_isListening) {
                    // Simulate spoken input from sample
                    _applyUtterance('बच्चे को दो दिन से तेज बुखार है और उल्टी हो रही है। दूध भी नहीं पी रहा है।');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Extracted Concepts Display
          if (_extractedSymptoms.isNotEmpty) ...[
            const Text(
              'Extracted IMCI Concepts (Auto-Scored):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _extractedSymptoms.map((s) {
                final isAffirmative = s.isAffirmative;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAffirmative
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAffirmative ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAffirmative ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: isAffirmative ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${s.concept}: ${isAffirmative ? "YES" : "NO"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAffirmative ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        ),
                      ),
                      Text(
                        ' ("${s.matchedPhrase}")',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Quick Preset Prompts
          const Text(
            'Or select rural field utterance:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: IndicAsrService.sampleFieldUtterances.map((sample) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155)),
                    label: Text(
                      sample['label']!,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
                    ),
                    onPressed: () => _applyUtterance(sample['text']!),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Confirm and Apply button
          ElevatedButton.icon(
            onPressed: _extractedSymptoms.isNotEmpty ? _confirmAndApply : null,
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              _extractedSymptoms.isNotEmpty
                  ? 'Apply to Assessment (${_extractedSymptoms.length} concepts found)'
                  : 'Speak or Enter Symptoms',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: const Color(0xFF334155),
              disabledForegroundColor: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
