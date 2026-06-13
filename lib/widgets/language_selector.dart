import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../models/language.dart';
import '../services/store/app_settings.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorPalette;
    
    return ValueListenableBuilder<Language>(
      valueListenable: AppSettings.language,
      builder: (context, currentLanguage, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            children: Language.supported.map((lang) {
              final isSelected = lang.code == currentLanguage.code;
              return InkWell(
                onTap: () {
                  if (!isSelected) {
                    AppSettings.setLanguage(lang);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? colors.primary : colors.ink,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: colors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
