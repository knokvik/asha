import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'language_provider.dart';

/// Modal dialog for selecting one of the 12 supported Indian regional languages.
///
/// Touch targets adhere to WCAG 48×48 dp minimum.
/// Requirements: 3.1, 3.4
class LanguageSelectorDialog extends ConsumerWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.language, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select Language / भाषा चुनें',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: supportedLanguages.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final lang = supportedLanguages[index];
            final isSelected = lang.code == currentLocale.languageCode;

            return ListTile(
              key: Key('lang_option_${lang.code}'),
              minVerticalPadding: 14, // Ensures >= 48dp touch target
              title: Text(
                lang.nativeName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green.shade800 : Colors.black87,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                lang.englishName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                ref
                    .read(languageProvider.notifier)
                    .setLanguageCode(lang.code);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
