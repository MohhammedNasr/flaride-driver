import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/country_city_service.dart';

class LocationSelectorWidget extends StatefulWidget {
  final String? initialCountryId;
  final String? initialCityId;
  final String? serviceType; // 'rides', 'delivery', 'restaurants'
  final Function(Country country, City city) onLocationSelected;
  final bool showTitle;

  const LocationSelectorWidget({
    super.key,
    this.initialCountryId,
    this.initialCityId,
    this.serviceType,
    required this.onLocationSelected,
    this.showTitle = true,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  final CountryCityService _service = CountryCityService();
  
  List<Country> _countries = [];
  List<City> _cities = [];
  Country? _selectedCountry;
  City? _selectedCity;
  bool _loadingCountries = true;
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      setState(() {
        _loadingCountries = true;
        _error = null;
      });

      final countries = await _service.getCountries(serviceType: widget.serviceType);
      
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });

      // Set initial country if provided
      if (widget.initialCountryId != null) {
        final country = countries.firstWhere(
          (c) => c.id == widget.initialCountryId,
          orElse: () => countries.first,
        );
        _selectCountry(country);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingCountries = false;
      });
    }
  }

  Future<void> _selectCountry(Country country) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _cities = [];
      _loadingCities = true;
    });

    try {
      final cities = await _service.getCities(
        country.id,
        serviceType: widget.serviceType,
      );
      
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });

      // Set initial city if provided and matches country
      if (widget.initialCityId != null) {
        final city = cities.firstWhere(
          (c) => c.id == widget.initialCityId,
          orElse: () => cities.isNotEmpty ? cities.first : City(id: '', name: '', countryId: ''),
        );
        if (city.id.isNotEmpty) {
          _selectCity(city);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingCities = false;
      });
    }
  }

  void _selectCity(City city) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCity = city;
    });
    widget.onLocationSelected(_selectedCountry!, city);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            'Select Your Location',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your country and city to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Country Selection
        Text(
          'Country',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_loadingCountries)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          _buildErrorWidget()
        else
          _buildCountrySelector(),

        const SizedBox(height: 20),

        // City Selection
        Text(
          'City',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_selectedCountry == null)
          _buildPlaceholder('Select a country first')
        else if (_loadingCities)
          const Center(child: CircularProgressIndicator())
        else if (_cities.isEmpty)
          _buildPlaceholder('No cities available')
        else
          _buildCitySelector(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Failed to load locations',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
          TextButton(
            onPressed: _loadCountries,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _countries.map((country) {
          final isSelected = _selectedCountry?.id == country.id;
          return InkWell(
            onTap: () => _selectCountry(country),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryOrange.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: country == _countries.last ? 0 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    country.flagEmoji ?? '🌍',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          style: GoogleFonts.poppins(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryOrange : null,
                          ),
                        ),
                        Text(
                          '${country.currencyCode} • ${country.phoneCode ?? ""}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryOrange,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _cities.map((city) {
          final isSelected = _selectedCity?.id == city.id;
          return InkWell(
            onTap: () => _selectCity(city),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryOrange.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: city == _cities.last ? 0 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: isSelected ? AppColors.primaryOrange : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      city.name,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryOrange : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryOrange,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact dropdown version for settings/profile
class LocationDropdownSelector extends StatefulWidget {
  final String? countryId;
  final String? cityId;
  final String? serviceType;
  final Function(Country country, City city) onChanged;

  const LocationDropdownSelector({
    super.key,
    this.countryId,
    this.cityId,
    this.serviceType,
    required this.onChanged,
  });

  @override
  State<LocationDropdownSelector> createState() => _LocationDropdownSelectorState();
}

class _LocationDropdownSelectorState extends State<LocationDropdownSelector> {
  final CountryCityService _service = CountryCityService();
  
  List<Country> _countries = [];
  List<City> _cities = [];
  Country? _selectedCountry;
  City? _selectedCity;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final countries = await _service.getCountries(serviceType: widget.serviceType);
      setState(() {
        _countries = countries;
        _loading = false;
      });

      if (widget.countryId != null) {
        final country = countries.firstWhere(
          (c) => c.id == widget.countryId,
          orElse: () => countries.first,
        );
        await _onCountryChanged(country);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onCountryChanged(Country? country) async {
    if (country == null) return;
    
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _cities = [];
    });

    try {
      final cities = await _service.getCities(country.id, serviceType: widget.serviceType);
      setState(() => _cities = cities);

      if (widget.cityId != null) {
        final city = cities.firstWhere(
          (c) => c.id == widget.cityId,
          orElse: () => cities.isNotEmpty ? cities.first : City(id: '', name: '', countryId: ''),
        );
        if (city.id.isNotEmpty) {
          _onCityChanged(city);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  void _onCityChanged(City? city) {
    if (city == null || _selectedCountry == null) return;
    setState(() => _selectedCity = city);
    widget.onChanged(_selectedCountry!, city);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Country dropdown
        DropdownButtonFormField<Country>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: _selectedCountry?.flagEmoji != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_selectedCountry!.flagEmoji!, style: const TextStyle(fontSize: 20)),
                  )
                : const Icon(Icons.public),
          ),
          items: _countries.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Row(
                children: [
                  Text(country.flagEmoji ?? '🌍', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(country.name),
                ],
              ),
            );
          }).toList(),
          onChanged: _onCountryChanged,
        ),
        const SizedBox(height: 16),
        // City dropdown
        DropdownButtonFormField<City>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_city),
          ),
          items: _cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city.name),
            );
          }).toList(),
          onChanged: _selectedCountry != null ? _onCityChanged : null,
        ),
      ],
    );
  }
}

/// Bottom sheet for location selection
Future<Map<String, dynamic>?> showLocationSelector(
  BuildContext context, {
  String? initialCountryId,
  String? initialCityId,
  String? serviceType,
}) async {
  Country? selectedCountry;
  City? selectedCity;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LocationSelectorWidget(
                initialCountryId: initialCountryId,
                initialCityId: initialCityId,
                serviceType: serviceType,
                showTitle: false,
                onLocationSelected: (country, city) {
                  selectedCountry = country;
                  selectedCity = city;
                },
              ),
            ),
          ),
          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (result == true && selectedCountry != null && selectedCity != null) {
    return {
      'country': selectedCountry,
      'city': selectedCity,
    };
  }
  return null;
}
