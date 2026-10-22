import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../../core/pdf/pdf_generator.dart';
import '../../../core/pdf/register_data_service.dart';
import '../../../core/pdf/register_models.dart';
import '../../../core/pdf/template_manager.dart';
import '../../../shared/shell/shell_copy.dart';

/// Full-screen scrollable register viewer with dual on-screen grid and PDF preview,
/// share-to-messaging-apps, and family-friendly health cards (Requirements 34.1, 34.2, 34.4, 34.5).
class RegisterViewerScreen extends StatefulWidget {
  final AppDatabase db;
  final String workerId;
  final String ashaName;
  final String villageName;
  final RegisterType initialRegister;
  final bool startInPdfMode;

  const RegisterViewerScreen({
    super.key,
    required this.db,
    required this.workerId,
    this.ashaName = 'Sunita Devi',
    this.villageName = 'Devpur Gram Panchayat',
    this.initialRegister = RegisterType.rch,
    this.startInPdfMode = false,
  });

  @override
  State<RegisterViewerScreen> createState() => _RegisterViewerScreenState();
}

class _RegisterViewerScreenState extends State<RegisterViewerScreen> {
  late RegisterDataService _dataService;
  RegisterType _selectedRegister = RegisterType.rch;
  String _reportingPeriod = 'October 2026';
  bool _isPdfMode = false;
  bool _isLoading = true;
  String _searchQuery = '';

  RegisterPageData? _currentPageData;
  Uint8List? _cachedPdfBytes;

  @override
  void initState() {
    super.initState();
    _dataService = RegisterDataService(widget.db);
    _selectedRegister = widget.initialRegister;
    _isPdfMode = widget.startInPdfMode;
    _loadRegisterData();
  }

  Future<void> _loadRegisterData() async {
    setState(() => _isLoading = true);
    final data = await _dataService.fetchRegisterData(
      type: _selectedRegister,
      workerId: widget.workerId,
      ashaName: widget.ashaName,
      villageName: widget.villageName,
      reportingPeriod: _reportingPeriod,
    );

    Uint8List? pdfBytes;
    try {
      if (_selectedRegister == RegisterType.monthlyReport) {
        pdfBytes = await PdfGenerator.generateMonthlyReportPdf(data);
      } else {
        pdfBytes = await PdfGenerator.generateRegisterPdf(data);
      }
    } catch (e) {
      debugPrint('Error generating PDF bytes: $e');
    }

    if (mounted) {
      setState(() {
        _currentPageData = data;
        _cachedPdfBytes = pdfBytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCurrentRegister() async {
    if (_cachedPdfBytes == null && _currentPageData != null) {
      if (_selectedRegister == RegisterType.monthlyReport) {
        _cachedPdfBytes = await PdfGenerator.generateMonthlyReportPdf(
          _currentPageData!,
        );
      } else {
        _cachedPdfBytes = await PdfGenerator.generateRegisterPdf(
          _currentPageData!,
        );
      }
    }

    if (_cachedPdfBytes != null) {
      await Printing.sharePdf(
        bytes: _cachedPdfBytes!,
        filename: '${_selectedRegister.code}_$_reportingPeriod.pdf'.replaceAll(
          ' ',
          '_',
        ),
      );
    }
  }

  // ── Family Card Dialog ──────────────────────────────────────────────────────

  void _showFamilyCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FamilyCardSelectorSheet(
        dataService: _dataService,
        ashaContact: '${widget.ashaName} • 9876543210',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final theme = Theme.of(context);
    final template = TemplateManager().getTemplate(_selectedRegister);
    final isDefaultWorker =
        widget.ashaName.isEmpty ||
        widget.ashaName == 'Sunita Devi' ||
        widget.ashaName == 'Sunita Sharma';
    final ashaNameDisplay = (lang != 'en' && isDefaultWorker)
        ? shellText(lang, 'workerName')
        : widget.ashaName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'en'
                  ? 'Official Registers & Reports'
                  : shellText(lang, 'registers'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.villageName} • $ashaNameDisplay',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isPdfMode ? Icons.grid_on : Icons.picture_as_pdf),
            tooltip: _isPdfMode
                ? shellText(lang, 'switchToGrid')
                : shellText(lang, 'switchToPdf'),
            onPressed: () {
              setState(() => _isPdfMode = !_isPdfMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: shellText(lang, 'shareRegister'),
            onPressed: _shareCurrentRegister,
          ),
          IconButton(
            icon: const Icon(Icons.badge),
            tooltip: shellText(lang, 'familyHealthCards'),
            onPressed: _showFamilyCardDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top Selector Bar ──────────────────────────────────────────────
          _buildSelectorHeader(theme, lang),

          // ── Main Content Area ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isPdfMode
                ? _buildPdfPreview()
                : _buildInteractiveGrid(template),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomSummaryBar(theme),
    );
  }

  Widget _buildSelectorHeader(ThemeData theme, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blueGrey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RegisterType>(
                  value: _selectedRegister,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: shellText(lang, 'selectRegisterLabel'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: RegisterType.values.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(
                        '${r.formCode} — ${r.displayName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val != _selectedRegister) {
                      setState(() => _selectedRegister = val);
                      _loadRegisterData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  value: _reportingPeriod,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: shellText(lang, 'periodLabel'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'October 2026',
                      child: Text('Oct 2026', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'September 2026',
                      child: Text('Sep 2026', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'August 2026',
                      child: Text('Aug 2026', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'FY 2026-27',
                      child: Text('FY 26-27', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (p) {
                    if (p != null && p != _reportingPeriod) {
                      setState(() => _reportingPeriod = p);
                      _loadRegisterData();
                    }
                  },
                ),
              ),
            ],
          ),
          if (!_isPdfMode) ...[
            const SizedBox(height: 6),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search beneficiary or hamlet...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Full-Screen Scrollable Interactive Grid Table (Requirement 34.4) ────────

  Widget _buildInteractiveGrid(RegisterTemplateConfig template) {
    if (_currentPageData == null || _currentPageData!.rows.isEmpty) {
      return const Center(
        child: Text('No records recorded for this register period.'),
      );
    }

    final filteredRows = _currentPageData!.rows.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row.values.any((v) => '$v'.toLowerCase().contains(_searchQuery));
    }).toList();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade900),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            dataRowMinHeight: 38,
            dataRowMaxHeight: 48,
            columns: template.columns.map((col) {
              return DataColumn(
                label: Text(col.header),
                numeric: col.alignment == 'right',
              );
            }).toList(),
            rows: filteredRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final isEven = idx % 2 == 0;

              return DataRow(
                color: WidgetStateProperty.all(
                  isEven ? Colors.white : Colors.grey.shade100,
                ),
                cells: template.columns.map((col) {
                  final text = row[col.key]?.toString() ?? '-';
                  final isAlert =
                      text.contains('HIGH RISK') ||
                      text.contains('DUE') ||
                      text.contains('Positive');

                  return DataCell(
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAlert
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAlert ? Colors.red.shade800 : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Print-Ready PDF Preview ─────────────────────────────────────────────────

  Widget _buildPdfPreview() {
    if (_currentPageData == null) {
      return const Center(child: Text('Preparing PDF preview...'));
    }

    return PdfPreview(
      build: (format) async {
        if (_selectedRegister == RegisterType.monthlyReport) {
          return PdfGenerator.generateMonthlyReportPdf(_currentPageData!);
        } else {
          return PdfGenerator.generateRegisterPdf(_currentPageData!);
        }
      },
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share PDF via Messaging Apps',
          onPressed: _shareCurrentRegister,
        ),
      ],
    );
  }

  Widget _buildBottomSummaryBar(ThemeData theme) {
    if (_currentPageData == null || _currentPageData!.summaryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: _currentPageData!.summaryTotals.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${e.value}',
                        style: TextStyle(
                          color: Colors.blueGrey.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share PDF'),
            onPressed: _shareCurrentRegister,
          ),
        ],
      ),
    );
  }
}

// ── Family Health Card Bottom Sheet (Requirement 34.5) ────────────────────────

class _FamilyCardSelectorSheet extends StatefulWidget {
  final RegisterDataService dataService;
  final String ashaContact;

  const _FamilyCardSelectorSheet({
    required this.dataService,
    required this.ashaContact,
  });

  @override
  State<_FamilyCardSelectorSheet> createState() =>
      _FamilyCardSelectorSheetState();
}

class _FamilyCardSelectorSheetState extends State<_FamilyCardSelectorSheet> {
  FamilyCardType _cardType = FamilyCardType.mcpCardUpdate;
  String _beneficiaryName = 'Anita Devi';
  String _language = 'hi';
  bool _isGenerating = false;

  Future<void> _shareCard() async {
    setState(() => _isGenerating = true);
    final cardData = widget.dataService.generateFamilyCard(
      cardType: _cardType,
      beneficiaryName: _beneficiaryName,
      languageCode: _language,
      ashaContact: widget.ashaContact,
    );

    final bytes = await PdfGenerator.generateFamilyFriendlyCardPdf(cardData);
    setState(() => _isGenerating = false);

    if (mounted) {
      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            '${_cardType.code}_${_beneficiaryName.replaceAll(' ', '_')}.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generate Family Health Card',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FamilyCardType>(
            value: _cardType,
            decoration: const InputDecoration(
              labelText: 'Card Format',
              border: OutlineInputBorder(),
            ),
            items: FamilyCardType.values.map((t) {
              return DropdownMenuItem(value: t, child: Text(t.title));
            }).toList(),
            onChanged: (v) => setState(() => _cardType = v ?? _cardType),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Beneficiary Name',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _beneficiaryName),
            onChanged: (v) => _beneficiaryName = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Language: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ChoiceChip(
                label: const Text('Hindi (हिन्दी)'),
                selected: _language == 'hi',
                onSelected: (s) => setState(() => _language = 'hi'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('English'),
                selected: _language == 'en',
                onSelected: (s) => setState(() => _language = 'en'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(
                _isGenerating
                    ? 'Generating...'
                    : 'Share Card to Family (WhatsApp)',
              ),
              onPressed: _isGenerating ? null : _shareCard,
            ),
          ),
        ],
      ),
    );
  }
}
