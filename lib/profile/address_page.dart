import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
import 'package:flutter/services.dart';
import '../models/user_address.dart';
import 'package:flutter_project/services/localization/localization_extension.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import '../core/ui/theme/app_dimensions.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key, this.initial});

  final AddressDraft? initial;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  static const int _addressLineMaxLength = 500;
  static const int _streetMaxLength = 100;
  static const int _zipMaxLength = 10;
  static const int _apartmentMaxLength = 20;
  static final RegExp _zipPattern = RegExp(r'^\d{3,10}$');
  static final RegExp _apartmentPattern = RegExp(
    r'^[0-9A-Za-zА-Яа-яЁё\-\/ ]+$',
  );
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  late final TextEditingController _addressController;
  late final TextEditingController _streetController;
  late final TextEditingController _zipController;
  late final TextEditingController _apartmentController;

  String _selectedType = 'home';
  String? _addressError;
  String? _streetError;
  String? _zipError;
  String? _apartmentError;

  YandexMapController? _mapController;
  bool _isLoadingLocation = false;
  static const Point _defaultPoint = Point(latitude: 51.128207, longitude: 71.430411);

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _pageBg => _theme.scaffoldBackgroundColor;
  Color get _cardBg => context.colorPalette.card;
  Color get _mutedText => _colorScheme.onSurfaceVariant;
  Color get _inputFill => _colorScheme.surfaceContainerHighest;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _addressController = TextEditingController(
      text: initial?.addressLine ?? '',
    );
    _streetController = TextEditingController(text: initial?.street ?? '');
    _zipController = TextEditingController(text: initial?.zip ?? '');
    _apartmentController = TextEditingController(
      text: initial?.apartment ?? '',
    );
    final label = initial?.label.trim().toLowerCase();
    if (label == 'home' || label == 'work' || label == 'other') {
      _selectedType = label!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _streetController.dispose();
    _zipController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final point = Point(latitude: position.latitude, longitude: position.longitude);

      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0)
      );
      
      _fetchAddress(point);
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchAddress(Point point) async {
    debugPrint("Geocoding started for point: ${point.latitude}, ${point.longitude}");
    final resultWithSession = await YandexSearch.searchByPoint(
      point: point,
      searchOptions: const SearchOptions(
        searchType: SearchType.geo,
        geometry: false,
      ),
    );

    try {
      final result = await resultWithSession.$2;
      if (result.error != null) {
        debugPrint("Geocoding error from Yandex: ${result.error}");
        return;
      }

      final items = result.items;
      debugPrint("Geocoding items found: ${items?.length}");
      if (items != null && items.isNotEmpty) {
        final topItem = items.first;
        final addressDetails = topItem.toponymMetadata?.address;
        
        debugPrint("Address details: ${addressDetails?.formattedAddress}");

        if (addressDetails != null) {
          String street = '';
          String formattedAddress = addressDetails.formattedAddress;

          if (addressDetails.addressComponents.containsKey(SearchComponentKind.street)) {
            street = addressDetails.addressComponents[SearchComponentKind.street] ?? '';
          }

          if (mounted) {
            setState(() {
              if (street.isNotEmpty) {
                _streetController.text = street;
                _streetError = null;
              }
              _addressController.text = formattedAddress;
              _addressError = null;
            });
          }
        } else {
          debugPrint("No address details in the top item");
        }
      }
    } catch (e) {
      debugPrint("Geocoding exception: $e");
    }
  }

  Widget _buildMap() {
    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputFill, width: 2),
      ),
      child: Stack(
        children: [
          YandexMap(
            onMapCreated: (YandexMapController yandexMapController) async {
              _mapController = yandexMapController;
              if (widget.initial == null) {
                await _moveToCurrentLocation();
              } else {
                _mapController?.moveCamera(
                  CameraUpdate.newCameraPosition(
                    const CameraPosition(target: _defaultPoint, zoom: 12)
                  )
                );
              }
            },
            onCameraPositionChanged: (CameraPosition cameraPosition, CameraUpdateReason reason, bool finished) {
              if (finished && reason == CameraUpdateReason.gestures) {
                 _fetchAddress(cameraPosition.target);
              }
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Icon(Icons.location_on, size: 40, color: context.colorPalette.accent),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              backgroundColor: _cardBg,
              onPressed: _isLoadingLocation ? null : _moveToCurrentLocation,
              child: _isLoadingLocation 
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.colorPalette.accent),
                    )
                  : Icon(Icons.my_location, color: context.colorPalette.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorPalette.accent;
    final isEditing = widget.initial != null;
    final titleText = isEditing ? context.l10n.getString('auto_redaktirovatAdres') : context.l10n.getString('auto_dobavitAdres');

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + AppDimensions.minBottomSafePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMap(),
            _buildTextField(
              label: context.l10n.getString('auto_adres'),
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              errorText: _addressError,
              onChanged: _onAddressChanged,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_addressLineMaxLength),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: context.l10n.getString('auto_ulitsa'),
                    controller: _streetController,
                    errorText: _streetError,
                    onChanged: _onStreetChanged,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_streetMaxLength),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: context.l10n.getString('auto_pochtovyyIndeks'),
                    controller: _zipController,
                    keyboardType: TextInputType.number,
                    errorText: _zipError,
                    onChanged: _onZipChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_zipMaxLength),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: context.l10n.getString('auto_kvartira'),
              controller: _apartmentController,
              errorText: _apartmentError,
              onChanged: _onApartmentChanged,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_apartmentMaxLength),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildTypeButton(value: 'home', label: context.l10n.getString('auto_dom')),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'work', label: context.l10n.getString('auto_rabota')),
                const SizedBox(width: 12),
                _buildTypeButton(value: 'other', label: context.l10n.getString('auto_drugoe')),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? context.l10n.getString('auto_sohranit') : context.l10n.getString('auto_sohranitAdres'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _colorScheme.onSurface,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _mutedText)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 0 : 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({required String value, required String label}) {
    final isSelected = _selectedType == value;
    final primaryColor = context.colorPalette.accent;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = value),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : _inputFill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : _colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    _validateForm();
    if (_addressError != null ||
        _streetError != null ||
        _zipError != null ||
        _apartmentError != null) {
      return;
    }

    final addressLine = _normalizeText(_addressController.text);
    final street = _normalizeOptionalText(_streetController.text);
    final zip = _zipController.text.trim();
    final apartment = _apartmentController.text.trim();

    final draft = AddressDraft(
      label: _selectedType,
      addressLine: addressLine,
      street: street ?? '',
      zip: zip,
      apartment: apartment,
    );

    Navigator.pop(context, draft);
  }

  void _validateForm() {
    setState(() {
      _addressError = _validateAddress(_addressController.text);
      _streetError = _validateStreet(_streetController.text);
      _zipError = _validateZip(_zipController.text);
      _apartmentError = _validateApartment(_apartmentController.text);
    });
  }

  void _onAddressChanged(String value) {
    setState(() {
      _addressError = _validateAddress(value);
    });
  }

  void _onStreetChanged(String value) {
    setState(() {
      _streetError = _validateStreet(value);
    });
  }

  void _onZipChanged(String value) {
    setState(() {
      _zipError = _validateZip(value);
    });
  }

  void _onApartmentChanged(String value) {
    setState(() {
      _apartmentError = _validateApartment(value);
    });
  }

  String? _validateAddress(String value) {
    final addressLine = _normalizeText(value);
    if (addressLine.isEmpty) {
      return context.l10n.getString('auto_vvediteAdres');
    }
    if (addressLine.length < 5) {
      return context.l10n.getString('auto_adresSlishkomKorotkiy');
    }
    return null;
  }

  String? _validateStreet(String value) {
    final street = _normalizeOptionalText(value);
    if (street != null && street.length > _streetMaxLength) {
      return context.l10n.getString('auto_ulitsa_1', params: {'streetMaxLength': _streetMaxLength.toString()});
    }
    return null;
  }

  String? _validateZip(String value) {
    final zip = value.trim();
    if (zip.length > _zipMaxLength) {
      return context.l10n.addressZipMaxLength(_zipMaxLength);
    }
    if (zip.isNotEmpty && !_zipPattern.hasMatch(zip)) {
      return context.l10n.getString('auto_indeksDolzhenSoderzhat');
    }
    return null;
  }

  String? _validateApartment(String value) {
    final apartment = value.trim();
    if (apartment.length > _apartmentMaxLength) {
      return context.l10n.getString('auto_kvartira_1', params: {'apartmentMaxLength': _apartmentMaxLength.toString()});
    }
    if (apartment.isNotEmpty && !_apartmentPattern.hasMatch(apartment)) {
      return context.l10n.getString('auto_nekorrektnyyFormatKvart');
    }
    return null;
  }

  String _normalizeText(String value) {
    return value.replaceAll(_whitespaceRegExp, ' ').trim();
  }

  String? _normalizeOptionalText(String value) {
    final normalized = _normalizeText(value);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
