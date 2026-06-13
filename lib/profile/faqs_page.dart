import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  int? _expandedIndex;
  static const _expansionDuration = Duration(milliseconds: 280);
  static const _expansionCurve = Curves.easeInOutCubic;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.05);

  List<Map<String, String>> get _faqs => [
    {
      'question': context.l10n.getString('auto_kakSdelatZakaz'),
      'answer':
          context.l10n.getString('auto_chtobySdelatZakazVyber'),
    },
    {
      'question': context.l10n.getString('auto_kakieSposobyOplatyDost'),
      'answer':
          context.l10n.getString('auto_myPrinimaemOplatuNalic'),
    },
    {
      'question': context.l10n.getString('auto_skolkoVremeniZanimaetD'),
      'answer':
          context.l10n.getString('auto_standartnayaDostavkaZan'),
    },
    {
      'question': context.l10n.getString('auto_moguLiYaOtmenitZakaz'),
      'answer':
          context.l10n.getString('auto_vyMozheteOtmenitZakaz'),
    },
    {
      'question': context.l10n.getString('auto_kakIzmenitAdresDostavk'),
      'answer':
          'Вы можете изменить адрес доставки в разделе ${context.l10n.getString('auto_profil')} -> ${context.l10n.getString('auto_adresa')}. Также можно указать новый адрес при оформлении заказа.',
    },
    {
      'question': context.l10n.getString('auto_chtoDelatEsliTovarNe'),
      'answer':
          context.l10n.getString('auto_vyMozheteVernutTovarV'),
    },
    {
      'question': context.l10n.getString('auto_kakSvyazatsyaSPodderzh'),
      'answer':
          'Вы можете связаться с нами через раздел ${context.l10n.getString('auto_tehpodderzhka')} в приложении, по электронной почте или по телефону горячей линии.',
    },
    {
      'question': context.l10n.getString('auto_estLiMinimalnayaSumma'),
      'answer':
          context.l10n.getString('auto_minimalnayaSummaZakaza'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          context.l10n.getString('auto_voprosyIOtvety'),
          style: _theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          final isExpanded = _expandedIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              faq['question']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: _expansionDuration,
                            curve: _expansionCurve,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: _expansionDuration,
                    reverseDuration: _expansionDuration,
                    switchInCurve: _expansionCurve,
                    switchOutCurve: _expansionCurve,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: _expansionCurve,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SizeTransition(
                          sizeFactor: curved,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: isExpanded
                        ? Padding(
                            key: const ValueKey('expanded'),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['answer']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _mutedText,
                                height: 1.5,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('collapsed')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }
}
