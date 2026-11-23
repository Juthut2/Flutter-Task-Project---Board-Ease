import 'package:material_ui/material_ui.dart';

import '../services/psgc_service.dart';
import 'message_banner.dart';
import 'psgc_dropdown_field.dart';
import 'psgc_street_field.dart';

/// Presentational PSGC dropdown stack used by [PsgcAddressFields].
class PsgcAddressFormView extends StatelessWidget {
  const PsgcAddressFormView({
    super.key,
    required this.provinces,
    required this.cities,
    required this.barangays,
    required this.provinceCode,
    required this.cityCode,
    required this.barangayCode,
    required this.loadingProvinces,
    required this.loadingCities,
    required this.loadingBarangays,
    required this.enabled,
    required this.streetController,
    required this.onProvinceChanged,
    required this.onCityChanged,
    required this.onBarangayChanged,
    required this.onStreetChanged,
    this.error,
    this.onRetry,
  });

  final String? error;
  final VoidCallback? onRetry;

  final List<PsgcOption> provinces;
  final List<PsgcOption> cities;
  final List<PsgcOption> barangays;
  final String? provinceCode;
  final String? cityCode;
  final String? barangayCode;
  final bool loadingProvinces;
  final bool loadingCities;
  final bool loadingBarangays;
  final bool enabled;
  final TextEditingController streetController;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onBarangayChanged;
  final ValueChanged<String> onStreetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (error != null) ...[
          MessageBanner(message: error!, icon: Icons.cloud_off_rounded),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry address lookup'),
            ),
          ),
        ],
        PsgcDropdownField(
          label: 'Province',
          icon: Icons.map_outlined,
          hint: loadingProvinces ? 'Loading provinces...' : 'Select province',
          items: provinces,
          value: provinceCode,
          enabled: enabled && !loadingProvinces,
          onChanged: onProvinceChanged,
        ),
        const SizedBox(height: 12),
        PsgcDropdownField(
          label: 'City / Municipality',
          icon: Icons.location_city_outlined,
          hint: provinceCode == null
              ? 'Select a province first'
              : loadingCities
              ? 'Loading cities...'
              : 'Select city or municipality',
          items: cities,
          value: cityCode,
          enabled: enabled && provinceCode != null && !loadingCities,
          onChanged: onCityChanged,
        ),
        const SizedBox(height: 12),
        PsgcDropdownField(
          label: 'Barangay',
          icon: Icons.holiday_village_outlined,
          hint: cityCode == null
              ? 'Select a city first'
              : loadingBarangays
              ? 'Loading barangays...'
              : 'Select barangay',
          items: barangays,
          value: barangayCode,
          enabled: enabled && cityCode != null && !loadingBarangays,
          onChanged: onBarangayChanged,
        ),
        const SizedBox(height: 12),
        PsgcStreetField(
          controller: streetController,
          enabled: enabled,
          onChanged: onStreetChanged,
        ),
      ],
    );
  }
}
