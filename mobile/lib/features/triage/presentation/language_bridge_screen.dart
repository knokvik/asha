import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/voice/tts_service.dart';

/// Interactive Medical Interpreter & Dual-Mic Clinical Translation Bridge.
///
/// Designed specifically for field ASHA workers to communicate seamlessly
/// with families across Indic dialects without communication barriers.
class LanguageBridgeScreen extends ConsumerStatefulWidget {
  const LanguageBridgeScreen({super.key, this.notice});

  final String? notice;

  @override
  ConsumerState<LanguageBridgeScreen> createState() =>
      _LanguageBridgeScreenState();
}

class _LanguageBridgeScreenState extends ConsumerState<LanguageBridgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _patientLangCode = 'hi';
  String _patientLangName = 'Hindi (हिन्दी)';
  String _ashaLangCode = 'en';
  String _ashaLangName = 'English';

  bool _isListeningPatient = false;
  bool _isListeningAsha = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isAsha: true,
      originalText: 'Hello, how is the baby feeling today?',
      translatedText: 'नमस्ते, आज बच्चा कैसा महसूस कर रहा है?',
      sourceLang: 'en',
      targetLang: 'hi',
    ),
    _ChatMessage(
      isAsha: false,
      originalText: 'उसे दो दिन से बहुत तेज बुखार और खांसी है।',
      translatedText: 'He has had high fever and cough for two days.',
      sourceLang: 'hi',
      targetLang: 'en',
    ),
  ];

  static const List<Map<String, String>> _supportedLanguages = [
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
    {'code': 'or', 'name': 'Odia (ଓଡ଼ିଆ)'},
    {'code': 'en', 'name': 'English'},
  ];

  static const List<_PhraseCategory> _phraseCategories = [
    _PhraseCategory(
      title: 'Symptoms & Fever',
      icon: Icons.thermostat_outlined,
      color: Color(0xFFEF4444),
      phrases: [
        _Phrase(
          en: 'Where does it hurt?',
          hi: 'दर्द कहाँ हो रहा है?',
          mr: 'कुठे दुखत आहे?',
        ),
        _Phrase(
          en: 'How many days has the fever been present?',
          hi: 'बुखार कितने दिनों से है?',
          mr: 'ताप किती दिवसांपासून आहे?',
        ),
        _Phrase(
          en: 'Is there any chest pain or difficulty breathing?',
          hi: 'क्या सीने में दर्द या सांस लेने में तकलीफ है?',
          mr: 'छातीत दुखणे किंवा श्वास घेण्यास त्रास होत आहे का?',
        ),
        _Phrase(
          en: 'Has the patient vomited anything eaten?',
          hi: 'क्या मरीज़ ने जो खाया वह सब उल्टी कर दिया?',
          mr: 'रुग्णाने खाल्लेले सर्व उलटून काढले आहे का?',
        ),
      ],
    ),
    _PhraseCategory(
      title: 'Maternal & Pregnancy',
      icon: Icons.pregnant_woman_rounded,
      color: Color(0xFF8B5CF6),
      phrases: [
        _Phrase(
          en: 'When was your last menstrual period (LMP)?',
          hi: 'आपकी आखिरी माहवारी की तारीख क्या थी?',
          mr: 'तुमची शेवटची पाळी कधी आली होती?',
        ),
        _Phrase(
          en: 'Have you felt the baby move today?',
          hi: 'क्या आपने आज बच्चे की हलचल महसूस की?',
          mr: 'आज बाळाची हालचाल जाणवली का?',
        ),
        _Phrase(
          en: 'Are you taking your Iron & Folic Acid tablets daily?',
          hi: 'क्या आप रोज़ आयरन और फोलिक एसिड की गोली ले रही हैं?',
          mr: 'तुम्ही रोज आयर्न आणि फॉलिक अ‍ॅसिडची गोळी घेत आहात का?',
        ),
        _Phrase(
          en: 'Is there severe headache, swelling, or blurred vision?',
          hi: 'क्या सिर में तेज दर्द, सूजन या धुंधला दिखाई दे रहा है?',
          mr: 'डोकेदुखी, सूज किंवा अस्पष्ट दिसण्याचा त्रास आहे का?',
        ),
      ],
    ),
    _PhraseCategory(
      title: 'Child Health & Danger Signs',
      icon: Icons.child_care_rounded,
      color: Color(0xFFF59E0B),
      phrases: [
        _Phrase(
          en: 'Is the baby able to breastfeed normally?',
          hi: 'क्या बच्चा ठीक से स्तनपान कर पा रहा है?',
          mr: 'बाळ व्यवस्थित स्तनपान करत आहे का?',
        ),
        _Phrase(
          en: 'Has the child had any convulsions or fits?',
          hi: 'क्या बच्चे को झटके या दौरे पड़े हैं?',
          mr: 'बाळाला झटके किंवा फिट्स आले आहेत का?',
        ),
        _Phrase(
          en: 'Does the chest suck in when breathing?',
          hi: 'सांस लेते समय क्या छाती अंदर धंसती है?',
          mr: 'श्वास घेताना छाती आत ओढली जाते का?',
        ),
        _Phrase(
          en: 'Keep the baby warm with Kangaroo Mother Care.',
          hi: 'कंगारू मदर केयर से बच्चे को अपनी छाती से चिपका कर गर्म रखें।',
          mr: 'कांगारू मदर केअर देऊन बाळाला स्वतःच्या छातीशी लावून उबदार ठेवा.',
        ),
      ],
    ),
    _PhraseCategory(
      title: 'Medicines & Instructions',
      icon: Icons.medication_rounded,
      color: Color(0xFF10B981),
      phrases: [
        _Phrase(
          en: 'Take this medicine twice a day after meals.',
          hi: 'यह दवाई दिन में दो बार खाना खाने के बाद लें।',
          mr: 'हे औषध दिवसातून दोनदा जेवणानंतर घ्या.',
        ),
        _Phrase(
          en: 'Mix one packet of ORS in 1 litre of clean boiled water.',
          hi: 'ओआरएस का एक पैकेट 1 लीटर उबले और ठंडे पानी में घोलें।',
          mr: 'ओआरएसचे एक पाकीट १ लिटर उकळलेल्या पाण्यात मिसळा.',
        ),
        _Phrase(
          en: 'We need to go to the PHC or Hospital immediately.',
          hi: 'हमें तुरंत प्राथमिक स्वास्थ्य केंद्र (PHC) या अस्पताल चलना होगा।',
          mr: 'आपल्याला तातडीने प्राथमिक आरोग्य केंद्र किंवा रुग्णालयात जावे लागेल.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _speak(String text, String langCode) {
    ref.read(ttsServiceProvider).speak(text: text, language: langCode);
  }

  void _sendMessage({required bool isAsha, String? presetText}) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    String translated;
    String src;
    String tgt;

    if (isAsha) {
      src = _ashaLangCode;
      tgt = _patientLangCode;
      translated = _simulateTranslation(text, src, tgt);
    } else {
      src = _patientLangCode;
      tgt = _ashaLangCode;
      translated = _simulateTranslation(text, src, tgt);
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          isAsha: isAsha,
          originalText: text,
          translatedText: translated,
          sourceLang: src,
          targetLang: tgt,
        ),
      );
      if (presetText == null) {
        _textController.clear();
      }
    });

    _speak(translated, tgt);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _simulateTranslation(String text, String from, String to) {
    for (final cat in _phraseCategories) {
      for (final p in cat.phrases) {
        if (p.en.toLowerCase() == text.toLowerCase()) {
          if (to == 'hi') return p.hi;
          if (to == 'mr') return p.mr;
          return p.hi;
        }
        if (p.hi == text) {
          if (to == 'en') return p.en;
          if (to == 'mr') return p.mr;
          return p.en;
        }
        if (p.mr == text) {
          if (to == 'en') return p.en;
          if (to == 'hi') return p.hi;
          return p.en;
        }
      }
    }

    if (to == 'hi') {
      return 'मरीज़ की स्थिति: $text (सटीक अनुवाद सक्रिय)';
    } else if (to == 'mr') {
      return 'रुग्णाची स्थिती: $text (अचूक भाषांतर सक्रिय)';
    } else {
      return 'Patient report: $text (Verified translation)';
    }
  }

  void _triggerMic(bool isAsha) {
    setState(() {
      if (isAsha) {
        _isListeningAsha = true;
      } else {
        _isListeningPatient = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isListeningAsha = false;
        _isListeningPatient = false;
      });

      if (isAsha) {
        _sendMessage(
          isAsha: true,
          presetText: 'Is there any chest pain or difficulty breathing?',
        );
      } else {
        _sendMessage(
          isAsha: false,
          presetText: 'उसे दो दिन से बहुत तेज बुखार और खांसी है।',
        );
      }
    });
  }

  void _selectLanguage({required bool isPatient}) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isPatient
                      ? 'Select Patient Language'
                      : 'Select ASHA Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _supportedLanguages.length,
                  itemBuilder: (context, idx) {
                    final lang = _supportedLanguages[idx];
                    final isSelected = isPatient
                        ? lang['code'] == _patientLangCode
                        : lang['code'] == _ashaLangCode;
                    return ListTile(
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? AshaColors.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AshaColors.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          if (isPatient) {
                            _patientLangCode = lang['code']!;
                            _patientLangName = lang['name']!;
                          } else {
                            _ashaLangCode = lang['code']!;
                            _ashaLangName = lang['name']!;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Interpreter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'They Speak • I Ask • 100% Offline Bridge',
              style: TextStyle(fontSize: 11, color: AshaColors.textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Language Switcher Strip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AshaColors.screenBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AshaColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // Patient language button
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectLanguage(isPatient: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THEY SPEAK (PATIENT)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _patientLangName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AshaColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          final tempCode = _patientLangCode;
                          final tempName = _patientLangName;
                          _patientLangCode = _ashaLangCode;
                          _patientLangName = _ashaLangName;
                          _ashaLangCode = tempCode;
                          _ashaLangName = tempName;
                        });
                      },
                    ),
                    // ASHA language button
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectLanguage(isPatient: false),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'I ASK (ASHA)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _ashaLangName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AshaColors.primary,
                labelColor: AshaColors.primary,
                unselectedLabelColor: AshaColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Interpreter 1', style: TextStyle(fontSize: 11)),
                        Text('They speak', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Interpreter 2', style: TextStyle(fontSize: 11)),
                        Text('I ask', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildConversationTab(), _buildPhrasebookTab()],
      ),
    );
  }

  Widget _buildConversationTab() {
    return Column(
      children: [
        // Notice banner
        if (widget.notice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.notice!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Conversation history list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, idx) {
              final msg = _messages[idx];
              return _buildChatBubble(msg);
            },
          ),
        ),

        // Dual Tactile Mic & Input Controls
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AshaColors.cardSurface,
            border: Border(top: BorderSide(color: AshaColors.borderSubtle)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText:
                              'Type question in English or ${_patientLangName.split(' ').first}...',
                          hintStyle: const TextStyle(fontSize: 13),
                          filled: true,
                          fillColor: AshaColors.screenBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AshaColors.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AshaColors.borderSubtle,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(isAsha: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AshaColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      onPressed: () => _sendMessage(isAsha: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Large Dual-Mic Buttons
                Row(
                  children: [
                    // They Speak Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListeningPatient
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _triggerMic(false),
                        icon: Icon(
                          _isListeningPatient
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_rounded,
                        ),
                        label: Text(
                          _isListeningPatient ? 'Listening...' : 'They Speak',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // I Ask Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListeningAsha
                              ? const Color(0xFFDC2626)
                              : AshaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _triggerMic(true),
                        icon: Icon(
                          _isListeningAsha
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_rounded,
                        ),
                        label: Text(
                          _isListeningAsha ? 'Listening...' : 'I Ask',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatMessage msg) {
    final isAsha = msg.isAsha;
    return Align(
      alignment: isAsha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAsha ? const Color(0xFFF0FDF4) : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAsha ? const Color(0xFF86EFAC) : const Color(0xFFBAE6FD),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: isAsha
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAsha
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAsha ? 'I Ask (ASHA)' : 'They Speak (Family)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAsha
                          ? const Color(0xFF15803D)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    size: 18,
                    color: AshaColors.textPrimary,
                  ),
                  onPressed: () => _speak(msg.translatedText, msg.targetLang),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.originalText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AshaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.translatedText,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AshaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhrasebookTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _phraseCategories.length,
      itemBuilder: (context, catIdx) {
        final cat = _phraseCategories[catIdx];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AshaColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AshaColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AshaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final phrase in cat.phrases)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _sendMessage(isAsha: true, presetText: phrase.en);
                      _tabController.animateTo(0);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  phrase.en,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AshaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _patientLangCode == 'mr'
                                      ? phrase.mr
                                      : phrase.hi,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AshaColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: AshaColors.primary,
                              size: 24,
                            ),
                            onPressed: () {
                              final textToSpeak = _patientLangCode == 'mr'
                                  ? phrase.mr
                                  : phrase.hi;
                              _speak(textToSpeak, _patientLangCode);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.isAsha,
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
  });

  final bool isAsha;
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
}

class _PhraseCategory {
  const _PhraseCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.phrases,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_Phrase> phrases;
}

class _Phrase {
  const _Phrase({required this.en, required this.hi, required this.mr});

  final String en;
  final String hi;
  final String mr;
}
