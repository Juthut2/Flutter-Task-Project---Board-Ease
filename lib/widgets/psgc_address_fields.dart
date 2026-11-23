import 'package:material_ui/material_ui.dart';

import '../core/address_selection.dart';
import '../services/psgc_service.dart';
import 'psgc_address_form_view.dart';

/// Cascading PSGC province, city, and barangay dropdowns plus a street field.
class PsgcAddressFields extends StatefulWidget {
  const PsgcAddressFields({
    super.key,
    required this.onChanged,
    this.initialProvince = '',
    this.initialCity = '',
    this.initialBarangay = '',
    this.initialStreet = '',
    this.enabled = true,
  });

  final ValueChanged<AddressSelection> onChanged;
  final String initialProvince;
  final String initialCity;
  final String initialBarangay;
  final String initialStreet;
  final bool enabled;

  @override
  State<PsgcAddressFields> createState() => _PsgcAddressFieldsState();
}

class _PsgcAddressFieldsState extends State<PsgcAddressFields> {
  final PsgcService _service = PsgcService();
  final TextEditingController _streetController = TextEditingController();

  List<PsgcOption> _provinces = const <PsgcOption>[];
  List<PsgcOption> _cities = const <PsgcOption>[];
  List<PsgcOption> _barangays = const <PsgcOption>[];
  String? _provinceCode;
  String? _cityCode;
  String? _barangayCode;
  bool _loadingProvinces = true;
  bool _loadingCities = false;
  bool _loadingBarangays = false;
  String? _error;
  int _cityRequest = 0;
  int _barangayRequest = 0;

  @override
  void initState() {
    super.initState();
    _streetController.text = widget.initialStreet;
    _loadProvinces(showLoading: false);
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces({bool showLoading = true}) async {
    _cityRequest++;
    _barangayRequest++;
    if (showLoading) {
      setState(() {
        _loadingProvinces = true;
        _error = null;
      });
    }
    try {
      final provinces = await _service.fetchProvinces();
      if (!mounted) return;
      final match = PsgcOption.matchByName(provinces, widget.initialProvince);
      setState(() {
        _provinces = provinces;
        _provinceCode = match?.code;
        _cities = const <PsgcOption>[];
        _cityCode = null;
        _barangays = const <PsgcOption>[];
        _barangayCode = null;
        _loadingProvinces = false;
        _loadingCities = false;
        _loadingBarangays = false;
      });
      _emit();
      if (match != null) {
        await _loadCities(
          match.code,
          initialCity: widget.initialCity,
          initialBarangay: widget.initialBarangay,
        );
      }
    } on PsgcFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loadingProvinces = false;
      });
    }
  }

  Future<void> _loadCities(
    String provinceCode, {
    String initialCity = '',
    String initialBarangay = '',
  }) async {
    final request = ++_cityRequest;
    _barangayRequest++;
    setState(() {
      _loadingCities = true;
      _error = null;
      _cities = const <PsgcOption>[];
      _cityCode = null;
      _barangays = const <PsgcOption>[];
      _barangayCode = null;
    });
    _emit();
    try {
      final cities = await _service.fetchCities(provinceCode);
      if (!mounted || request != _cityRequest) return;
      final match = PsgcOption.matchByName(cities, initialCity);
      setState(() {
        _cities = cities;
        _cityCode = match?.code;
        _loadingCities = false;
      });
      _emit();
      if (match != null) {
        await _loadBarangays(match.code, initialName: initialBarangay);
      }
    } on PsgcFailure catch (error) {
      if (!mounted || request != _cityRequest) return;
      setState(() {
        _error = error.message;
        _loadingCities = false;
      });
    }
  }

  Future<void> _loadBarangays(
    String cityCode, {
    String initialName = '',
  }) async {
    final request = ++_barangayRequest;
    setState(() {
      _loadingBarangays = true;
      _error = null;
      _barangays = const <PsgcOption>[];
      _barangayCode = null;
    });
    _emit();
    try {
      final barangays = await _service.fetchBarangays(cityCode);
      if (!mounted || request != _barangayRequest) return;
      final match = PsgcOption.matchByName(barangays, initialName);
      setState(() {
        _barangays = barangays;
        _barangayCode = match?.code;
        _loadingBarangays = false;
      });
      _emit();
    } on PsgcFailure catch (error) {
      if (!mounted || request != _barangayRequest) return;
      setState(() {
        _error = error.message;
        _loadingBarangays = false;
      });
    }
  }

  void _onProvinceChanged(String? code) {
    _cityRequest++;
    _barangayRequest++;
    setState(() {
      _provinceCode = code;
      _cities = const <PsgcOption>[];
      _cityCode = null;
      _barangays = const <PsgcOption>[];
      _barangayCode = null;
      _loadingCities = false;
      _loadingBarangays = false;
    });
    _emit();
    if (code != null) _loadCities(code);
  }

  void _onCityChanged(String? code) {
    _barangayRequest++;
    setState(() {
      _cityCode = code;
      _barangays = const <PsgcOption>[];
      _barangayCode = null;
      _loadingBarangays = false;
    });
    _emit();
    if (code != null) _loadBarangays(code);
  }

  void _onBarangayChanged(String? code) {
    setState(() => _barangayCode = code);
    _emit();
  }

  void _retry() {
    if (_provinces.isEmpty) {
      _loadProvinces();
    } else if (_provinceCode != null && _cities.isEmpty) {
      _loadCities(_provinceCode!);
    } else if (_cityCode != null && _barangays.isEmpty) {
      _loadBarangays(_cityCode!);
    } else {
      _loadProvinces();
    }
  }

  void _emit() {
    if (!mounted) return;
    widget.onChanged(
      AddressSelection(
        province: PsgcOption.nameFor(_provinces, _provinceCode),
        city: PsgcOption.nameFor(_cities, _cityCode),
        barangay: PsgcOption.nameFor(_barangays, _barangayCode),
        street: _streetController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PsgcAddressFormView(
      provinces: _provinces,
      cities: _cities,
      barangays: _barangays,
      provinceCode: _provinceCode,
      cityCode: _cityCode,
      barangayCode: _barangayCode,
      loadingProvinces: _loadingProvinces,
      loadingCities: _loadingCities,
      loadingBarangays: _loadingBarangays,
      enabled: widget.enabled,
      streetController: _streetController,
      error: _error,
      onRetry: _retry,
      onProvinceChanged: _onProvinceChanged,
      onCityChanged: _onCityChanged,
      onBarangayChanged: _onBarangayChanged,
      onStreetChanged: (_) => _emit(),
    );
  }
}
