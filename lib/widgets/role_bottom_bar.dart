import 'package:flutter/material.dart';

class RoleBottomBar extends StatelessWidget {
  const RoleBottomBar({
    super.key,
    required this.onHome,
    this.onCreate,
    this.createLabel = 'Создать товар',
    this.homeLabel = 'Главная',
    this.isCreateEnabled = true,
    this.showCreate = true,
  });

  final VoidCallback onHome;
  final VoidCallback? onCreate;
  final String createLabel;
  final String homeLabel;
  final bool isCreateEnabled;
  final bool showCreate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const accentColor = Color(0xFF6288D5);
    final shadowColor = Colors.black.withValues(alpha: 0.12);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home_outlined),
                  label: Text(homeLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: const BorderSide(color: accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (showCreate) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isCreateEnabled ? onCreate : null,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(createLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accentColor.withValues(
                        alpha: 0.4,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

