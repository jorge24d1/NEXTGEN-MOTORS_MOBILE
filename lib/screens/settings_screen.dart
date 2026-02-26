import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/locale_provider.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late FixedExtentScrollController _scrollController;

  static const _languages = [
    {'locale': Locale('es'), 'flag': '🇪🇸', 'name': 'Español'},
    {'locale': Locale('en'), 'flag': '🇺🇸', 'name': 'English'},
    {'locale': Locale('pt'), 'flag': '🇧🇷', 'name': 'Português'},
    {'locale': Locale('fr'), 'flag': '🇫🇷', 'name': 'Français'},
    {'locale': Locale('de'), 'flag': '🇩🇪', 'name': 'Deutsch'},
    {'locale': Locale('zh'), 'flag': '🇨🇳', 'name': '中文'},
  ];

  @override
  void initState() {
    super.initState();
    final currentLocale = context.read<LocaleProvider>().locale;
    final idx = _languages.indexWhere(
      (l) => (l['locale'] as Locale).languageCode == currentLocale.languageCode,
    );
    _scrollController = FixedExtentScrollController(
      initialItem: idx >= 0 ? idx : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLocale = context.watch<LocaleProvider>().locale;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1219),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header
            Text(
              loc.selectLanguage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 24),

            // Language Wheel
            Expanded(
              child: Center(
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Stack(
                    children: [
                      // Selection indicator
                      Center(
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Wheel
                      ListWheelScrollView.useDelegate(
                        controller: _scrollController,
                        itemExtent: 56,
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          final selected =
                              _languages[index]['locale'] as Locale;
                          context.read<LocaleProvider>().setLocale(selected);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _languages.length,
                          builder: (context, index) {
                            final lang = _languages[index];
                            final isSelected =
                                (lang['locale'] as Locale).languageCode ==
                                currentLocale.languageCode;
                            return Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: isSelected ? 20 : 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      lang['flag'] as String,
                                      style: TextStyle(
                                        fontSize: isSelected ? 28 : 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(lang['name'] as String),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current language indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.language,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _languages.firstWhere(
                              (l) =>
                                  (l['locale'] as Locale).languageCode ==
                                  currentLocale.languageCode,
                              orElse: () => _languages[0],
                            )['name']
                            as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
