import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/messages/app_message_snackbar.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/navigation/role_internal_nav_bar.dart';
import 'add_payment_card.dart';
import '../models/message.dart';
import '../services/storage/payment_card_storage.dart';
import '../services/storage/auth_storage.dart';
import '../services/message/message_localization.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedTopMethod = 'Card';
  String? _selectedCardId;
  List<PaymentCard> _savedCards = [];
  bool _isLoading = true;
  int? get _userId => AuthStorage.userId;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  PaymentCard? get _selectedCard {
    for (final card in _savedCards) {
      if (card.id == _selectedCardId) {
        return card;
      }
    }
    return null;
  }

  String? _normalizedTopBrand(String brand) {
    final lower = brand.toLowerCase();
    if (lower == 'visa') {
      return 'Visa';
    }
    if (lower == 'mastercard') {
      return 'Mastercard';
    }
    return null;
  }

  bool _brandMatches(PaymentCard card, String brand) {
    return card.brand.toLowerCase() == brand.toLowerCase();
  }

  PaymentCard? _firstCardForBrand(String brand) {
    for (final card in _savedCards) {
      if (_brandMatches(card, brand)) {
        return card;
      }
    }
    return null;
  }

  Future<void> _loadSavedCards({String? selectCardId}) async {
    if (_userId == null || _userId! <= 0) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savedCards = [];
        _selectedCardId = null;
        _selectedTopMethod = 'Card';
        _isLoading = false;
      });
      return;
    }

    final cards = await PaymentCardStorage.loadCards(userId: _userId);
    final savedSelection = await PaymentCardStorage.loadSelection(
      userId: _userId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _savedCards = cards;
      _isLoading = false;

      if (selectCardId != null) {
        _selectedCardId = selectCardId;
        final selected = _savedCards
            .where((card) => card.id == selectCardId)
            .toList();
        if (selected.isNotEmpty) {
          final topBrand = _normalizedTopBrand(selected.first.brand);
          if (topBrand != null) {
            _selectedTopMethod = topBrand;
          }
        }
      } else if (savedSelection != null) {
        _selectedTopMethod = savedSelection.method;
        _selectedCardId = savedSelection.cardId;
      } else if (_selectedCardId != null &&
          !_savedCards.any((card) => card.id == _selectedCardId)) {
        _selectedCardId = null;
      }

      if (_selectedTopMethod == 'Cash' || _selectedTopMethod == 'Paypal') {
        _selectedCardId = null;
      } else if (_selectedTopMethod == 'Visa' ||
          _selectedTopMethod == 'Mastercard') {
        if (_selectedCard == null ||
            !_brandMatches(_selectedCard!, _selectedTopMethod)) {
          _selectedCardId = _firstCardForBrand(_selectedTopMethod)?.id;
        }
      } else if (_selectedCardId == null && _savedCards.isNotEmpty) {
        _selectedCardId = _savedCards.first.id;
        final topBrand = _normalizedTopBrand(_savedCards.first.brand);
        if (topBrand != null) {
          _selectedTopMethod = topBrand;
        }
      }
    });
    await _persistSelection();
  }

  void _selectTopMethod(String value) {
    setState(() {
      _selectedTopMethod = value;
      if (value == 'Cash' || value == 'Paypal') {
        _selectedCardId = null;
        return;
      }
      if (value == 'Visa' || value == 'Mastercard') {
        _selectedCardId = _firstCardForBrand(value)?.id;
        return;
      }
    });
    _persistSelection();
  }

  Future<void> _persistSelection() async {
    if (_userId == null || _userId! <= 0) {
      return;
    }
    final selection = PaymentSelection(
      method: _selectedTopMethod,
      cardId: _selectedCardId,
    );
    await PaymentCardStorage.saveSelection(selection, userId: _userId);
  }

  Future<void> _openAddCard() async {
    final result = await Navigator.push<PaymentCard>(
      context,
      MaterialPageRoute(builder: (context) => const AddPaymentCardPage()),
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    await _loadSavedCards(selectCardId: result.id);
    if (!mounted) {
      return;
    }
    AppMessageSnackBar.show(
      context,
      Message(
        id: const Uuid().v4(),
        type: MessageType.notification,
        severity: MessageSeverity.info,
        title: '',
        body: context.l10n.getString('auto_kartaDobavlena'),
        timestamp: DateTime.now(),
        language: MessageLocalizationManager.getCurrentLanguage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorPalette.accent;

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
          context.l10n.getString('auto_metodOplaty'),
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Варианты оплаты
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  iconPath: 'assets/icons/cash.svg',
                  label: context.l10n.getString('auto_nalichnye'),
                  value: 'Cash',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/visa.svg',
                  label: 'Visa',
                  value: 'Visa',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/mastercard.svg',
                  label: 'Mastercard',
                  value: 'Mastercard',
                ),
                _buildPaymentOption(
                  iconPath: 'assets/icons/paypal.svg',
                  label: 'PayPal',
                  value: 'Paypal',
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(child: _buildSavedCardsSection()),

            const SizedBox(height: 16),

            // Кнопка context.l10n.getString('auto_dobavitNovyy')
            TextButton.icon(
              onPressed: _openAddCard,
              icon: Icon(Icons.add, size: 18),
              label: Text(
                context.l10n.getString('auto_dobavitNovyy'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleInternalNavBar(currentIndex: 3),
    );
  }

  Widget _buildSavedCardsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedTopMethod == 'Cash') {
      return _buildCashState();
    }
    if (_selectedTopMethod == 'Paypal') {
      return _buildPaypalState();
    }
    final visibleCards = _visibleCards();
    if (visibleCards.isEmpty) {
      return _buildEmptyState(
        title: _selectedTopMethod == 'Visa'
            ? context.l10n.getString('auto_netKartVisa')
            : _selectedTopMethod == 'Mastercard'
            ? context.l10n.getString('auto_netKartMastercard')
            : null,
        subtitle: _selectedTopMethod == 'Visa'
            ? context.l10n.getString('auto_dobavteKartuVisaChtoby')
            : _selectedTopMethod == 'Mastercard'
            ? context.l10n.getString('auto_dobavteKartuMastercard')
            : null,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: visibleCards.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            _cardsTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _colorScheme.onSurface,
            ),
          );
        }
        final card = visibleCards[index - 1];
        return _buildSavedCardTile(card);
      },
    );
  }

  List<PaymentCard> _visibleCards() {
    if (_selectedTopMethod == 'Visa' || _selectedTopMethod == 'Mastercard') {
      return _savedCards
          .where((card) => _brandMatches(card, _selectedTopMethod))
          .toList();
    }
    return _savedCards;
  }

  String _cardsTitle() {
    if (_selectedTopMethod == 'Visa') {
      return context.l10n.getString('auto_vashiKartyVisa');
    }
    if (_selectedTopMethod == 'Mastercard') {
      return context.l10n.getString('auto_vashiKartyMastercard');
    }
    return context.l10n.getString('auto_vashiKarty');
  }

  Widget _buildCashState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.getString('auto_oplataNalichnymi'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.getString('auto_vyVybraliOplatuNalichn'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildPaypalState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PayPal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.getString('auto_podklyucheniePaypalPoka'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String? title, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title ?? context.l10n.getString('auto_netSposobaOplaty'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? context.l10n.getString('auto_pozhaluystaVyberiteSpos'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardTile(PaymentCard card) {
    final isSelected = _selectedCardId == card.id;
    final primaryColor = context.colorPalette.accent;
    final borderColor = isSelected
        ? primaryColor
        : _colorScheme.surfaceContainerHighest;
    final shadowColor = _theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCardId = card.id;
            final topBrand = _normalizedTopBrand(card.brand);
            if (topBrand != null) {
              _selectedTopMethod = topBrand;
            }
          });
          _persistSelection();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildBrandBadge(card.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.maskedNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.holderName} / ${card.expiryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: _mutedText),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(Icons.check_circle, color: primaryColor, size: 20),
                  if (isSelected) const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteCard(card),
                    icon: Icon(
                      Icons.delete_outline,
                      color: _mutedText,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: context.l10n.getString('auto_udalitKartu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCard(PaymentCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.paymentCardDeleteTitle),
        content: Text(
          context.l10n.paymentMethodDeleteConfirmation(card.last4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colorPalette.accent,
            ),
            child: Text(context.l10n.commonDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await PaymentCardStorage.removeCard(card.id, userId: _userId);
    if (!mounted) {
      return;
    }
    await _loadSavedCards();
    await _persistSelection();
    if (!mounted) {
      return;
    }
    AppMessageSnackBar.show(
      context,
      Message(
        id: const Uuid().v4(),
        type: MessageType.notification,
        severity: MessageSeverity.info,
        title: '',
        body: context.l10n.getString('auto_kartaUdalena'),
        timestamp: DateTime.now(),
        language: MessageLocalizationManager.getCurrentLanguage(),
      ),
    );
  }

  Widget _buildBrandBadge(String brand) {
    final asset = _brandAssetFor(brand);
    final badgeBg = _colorScheme.surfaceContainerHighest;
    if (asset != null) {
      return Container(
        width: 48,
        height: 36,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _buildAssetIcon(asset, width: 28, height: 18),
      );
    }
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.credit_card, size: 20, color: _mutedText),
    );
  }

  String? _brandAssetFor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.svg';
      case 'mastercard':
        return 'assets/icons/mastercard.svg';
      default:
        return null;
    }
  }

  Widget _buildPaymentOption({
    required String iconPath,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedTopMethod == value;
    final primaryColor = context.colorPalette.accent;

    return GestureDetector(
      onTap: () {
        _selectTopMethod(value);
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : _colorScheme.surfaceContainerHighest,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _buildAssetIcon(iconPath, width: 42, height: 42),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: _mutedText)),
        ],
      ),
    );
  }

  Widget _buildAssetIcon(String assetPath, {double? width, double? height}) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }
}
