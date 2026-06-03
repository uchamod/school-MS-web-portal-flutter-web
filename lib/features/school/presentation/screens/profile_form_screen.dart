import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:school_portal_web/core/constants/colors.dart';
import 'package:school_portal_web/core/constants/provinces_districts.dart';
import 'package:school_portal_web/core/widgets/custom_button.dart';
import 'package:school_portal_web/core/widgets/custom_text_field.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_bloc.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_event.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_state.dart';
import 'package:school_portal_web/features/school/domain/entities/school_entity.dart';
import 'package:school_portal_web/features/school/domain/entities/school_image.dart';
import 'package:school_portal_web/features/school/presentation/widgets/portal_drawer.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _principalController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // Capacity Controllers
  final _stCountController = TextEditingController();
  final _techCountController = TextEditingController();
  final _buildingCountController = TextEditingController();
  final _labCountController = TextEditingController();
  final _comCountController = TextEditingController();

  String _selectedType = 'Primary';
  String? _selectedProvince;
  String? _selectedDistrict;
  List<String> _districtsForSelectedProvince = [];

  // Boolean toggles
  bool _isSportSchool = false;
  bool _isPrimarySchool = false;
  bool _isPoshkaSchool = false;

  // Databases ID if fetched
  String? _schoolDbId;

  // Images lists
  final List<SchoolImage> _existingImages = [];
  final List<PlatformFile> _newPickedImages = [];

  bool _isInit = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _principalController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _stCountController.dispose();
    _techCountController.dispose();
    _buildingCountController.dispose();
    _labCountController.dispose();
    _comCountController.dispose();
    super.dispose();
  }

  // Pre-populate fields once data is loaded from server
  void _initializeFields(SchoolEntity school) {
    if (_isInit) return;
    _isInit = true;

    _schoolDbId = school.id;
    _nameController.text = school.name;
    _addressController.text = school.address;
    _principalController.text = school.principal;
    _descriptionController.text = school.discription;
    _selectedType = school.type.isEmpty ? 'Primary' : school.type;

    if (school.province.isNotEmpty) {
      _selectedProvince = school.province;
      _districtsForSelectedProvince = ProvincesDistricts.districts[_selectedProvince] ?? [];
    }
    if (school.district.isNotEmpty && _districtsForSelectedProvince.contains(school.district)) {
      _selectedDistrict = school.district;
    }

    _stCountController.text = school.stCount > 0 ? school.stCount.toString() : '';
    _techCountController.text = school.techCount > 0 ? school.techCount.toString() : '';
    _buildingCountController.text = school.buildingCount > 0 ? school.buildingCount.toString() : '';
    _labCountController.text = school.labCount > 0 ? school.labCount.toString() : '';
    _comCountController.text = school.comCount > 0 ? school.comCount.toString() : '';

    _isSportSchool = school.isSportSchool;
    _isPrimarySchool = school.isPrimarySchool;
    _isPoshkaSchool = school.isPoshkaSchool;

    if (school.lat != null) _latController.text = school.lat!.toString();
    if (school.lng != null) _lngController.text = school.lng!.toString();

    _existingImages.clear();
    _existingImages.addAll(school.images);
    _newPickedImages.clear();
  }

  // Handle Province selection update
  void _onProvinceChanged(String? newProvince) {
    setState(() {
      _selectedProvince = newProvince;
      _selectedDistrict = null;
      if (newProvince != null) {
        _districtsForSelectedProvince = ProvincesDistricts.districts[newProvince] ?? [];
      } else {
        _districtsForSelectedProvince = [];
      }
    });
  }

  // Fetch coordinates using flutter geolocator package
  Future<void> _fetchGPSCoordinates() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Location services are disabled. Please enable them on your device/browser.', AppColors.error);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showSnackBar('Location permissions are denied.', AppColors.error);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Location permissions are permanently denied. We cannot request permissions.', AppColors.error);
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        _isLoadingLocation = false;
      });

      _showSnackBar('GPS Location loaded successfully!', AppColors.success);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showSnackBar('Error getting coordinates: $e', AppColors.error);
    }
  }

  // Pick images using file_picker
  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            // Avoid duplicate filenames
            if (!_newPickedImages.any((element) => element.name == file.name)) {
              _newPickedImages.add(file);
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting images: $e', AppColors.error);
    }
  }

  // Submit profile details to BLoC
  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProvince == null || _selectedDistrict == null) {
        _showSnackBar('Please select both Province and District dropdown fields.', AppColors.error);
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final school = SchoolEntity(
          id: _schoolDbId,
          schoolId: authState.user.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          province: _selectedProvince!,
          district: _selectedDistrict!,
          discription: _descriptionController.text.trim(),
          type: _selectedType,
          principal: _principalController.text.trim(),
          stCount: int.tryParse(_stCountController.text) ?? 0,
          techCount: int.tryParse(_techCountController.text) ?? 0,
          buildingCount: int.tryParse(_buildingCountController.text) ?? 0,
          labCount: int.tryParse(_labCountController.text) ?? 0,
          comCount: int.tryParse(_comCountController.text) ?? 0,
          isSportSchool: _isSportSchool,
          isPrimarySchool: _isPrimarySchool,
          isPoshkaSchool: _isPoshkaSchool,
          lat: double.tryParse(_latController.text),
          lng: double.tryParse(_lngController.text),
          images: _existingImages, // Send remaining existing images in JSON part
        );

        context.read<SchoolBloc>().add(
              SchoolSaveRequested(
                userId: authState.user.id,
                school: school,
                newImages: _newPickedImages, // Send new file uploads in Multipart part
              ),
            );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final hasDbId = _schoolDbId != null && _schoolDbId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hasDbId ? 'EDIT SCHOOL PROFILE' : 'CREATE SCHOOL PROFILE',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      drawer: const PortalDrawer(activeRoute: '/profile-setup'),
      body: BlocConsumer<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state is SchoolSaveSuccess) {
            _showSnackBar(
              hasDbId ? 'School profile updated successfully!' : 'School profile created successfully!',
              AppColors.success,
            );
            setState(() {
              _isInit = false;
            });
          } else if (state is SchoolError) {
            _showSnackBar('Failed to save profile: ${state.message}', AppColors.error);
          }
        },
        builder: (context, state) {
          if (state is SchoolLoading && !_isInit) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is SchoolLoaded) {
            _initializeFields(state.school);
          } else if (state is SchoolSaving) {
            _initializeFields(state.school);
          }

          final isSaving = state is SchoolSaving;

          return Container(
            color: AppColors.background,
            height: double.infinity,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 36.0 : 20.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Basic Information
                        _buildSectionCard(
                          title: 'Basic Information',
                          subtitle: 'Primary credentials, Principal details and Description',
                          icon: Icons.info_outline_rounded,
                          children: [
                            CustomTextField(
                              controller: _nameController,
                              label: 'School Name',
                              hint: 'e.g. Richmond College',
                              prefixIcon: Icons.account_balance_rounded,
                              validator: (val) => val == null || val.isEmpty ? 'School name is mandatory' : null,
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _addressController,
                              label: 'Street Address',
                              hint: 'e.g. 12, Galle Road, Colombo 03',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (val) => val == null || val.isEmpty ? 'Street address is mandatory' : null,
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _principalController,
                              label: 'Principal Name',
                              hint: 'e.g. Prof. J. K. Silva',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (val) => val == null || val.isEmpty ? 'Principal name is mandatory' : null,
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _descriptionController,
                              label: 'About School Description',
                              hint: 'Describe the school, facilities, history, etc.',
                              prefixIcon: Icons.description_outlined,
                              maxLines: 4,
                              validator: (val) => val == null || val.isEmpty ? 'School description is mandatory' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            // School Type Toggle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'School Classification Type',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: 'Primary', label: Text('Primary')),
                                      ButtonSegment(value: 'Secondary', label: Text('Secondary')),
                                      ButtonSegment(value: 'Higher Secondary', label: Text('Higher Secondary')),
                                    ],
                                    selected: {_selectedType},
                                    onSelectionChanged: (newSelection) {
                                      setState(() {
                                        _selectedType = newSelection.first;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Card 2: Regions & Geolocation
                        _buildSectionCard(
                          title: 'Region & Location Coordinates',
                          subtitle: 'Select province/district and fetch precise GPS location',
                          icon: Icons.map_outlined,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Province Dropdown
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Province',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedProvince,
                                        hint: const Text('Select Province'),
                                        isExpanded: true,
                                        items: ProvincesDistricts.provinces
                                            .map((prov) => DropdownMenuItem(value: prov, child: Text(prov)))
                                            .toList(),
                                        onChanged: _onProvinceChanged,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // District Dropdown (Cascading)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'District',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedDistrict,
                                        hint: Text(_selectedProvince == null 
                                            ? 'Select Province First' 
                                            : 'Select District'),
                                        isExpanded: true,
                                        disabledHint: const Text('Select Province First'),
                                        items: _districtsForSelectedProvince
                                            .map((dist) => DropdownMenuItem(value: dist, child: Text(dist)))
                                            .toList(),
                                        onChanged: _selectedProvince == null 
                                            ? null 
                                            : (newDist) {
                                                setState(() {
                                                  _selectedDistrict = newDist;
                                                });
                                              },
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Coordinates fields
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _latController,
                                    label: 'Latitude (decimal)',
                                    hint: 'e.g. 6.9271',
                                    prefixIcon: Icons.gps_fixed_outlined,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Latitude required';
                                      if (double.tryParse(val) == null) return 'Must be a decimal number';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _lngController,
                                    label: 'Longitude (decimal)',
                                    hint: 'e.g. 79.8612',
                                    prefixIcon: Icons.gps_fixed_rounded,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Longitude required';
                                      if (double.tryParse(val) == null) return 'Must be a decimal number';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Geolocator fetching trigger
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingLocation ? null : _fetchGPSCoordinates,
                                icon: _isLoadingLocation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                      )
                                    : const Icon(Icons.my_location_rounded, size: 16),
                                label: Text(_isLoadingLocation ? 'Resolving GPS location...' : 'Auto-Detect Current GPS Coordinates'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Card 3: Capacity Inputs (Text fields instead of steppers)
                        _buildSectionCard(
                          title: 'Infrastructure & Capacities',
                          subtitle: 'Input classroom capacities and resource figures',
                          icon: Icons.apartment_rounded,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isFormDesktop = constraints.maxWidth > 550;
                                
                                return GridView.count(
                                  crossAxisCount: isFormDesktop ? 2 : 1,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 16,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: isFormDesktop ? 3.4 : 4.4,
                                  children: [
                                    CustomTextField(
                                      controller: _stCountController,
                                      label: 'Student Population Count',
                                      hint: 'e.g. 1200',
                                      prefixIcon: Icons.people_alt_rounded,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Student count required';
                                        if (int.tryParse(val) == null) return 'Must be an integer';
                                        return null;
                                      },
                                    ),
                                    CustomTextField(
                                      controller: _techCountController,
                                      label: 'Faculty Teachers Count',
                                      hint: 'e.g. 64',
                                      prefixIcon: Icons.supervisor_account_rounded,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Teacher count required';
                                        if (int.tryParse(val) == null) return 'Must be an integer';
                                        return null;
                                      },
                                    ),
                                    CustomTextField(
                                      controller: _buildingCountController,
                                      label: 'Campus Buildings Count',
                                      hint: 'e.g. 10',
                                      prefixIcon: Icons.apartment_rounded,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Buildings count required';
                                        if (int.tryParse(val) == null) return 'Must be an integer';
                                        return null;
                                      },
                                    ),
                                    CustomTextField(
                                      controller: _labCountController,
                                      label: 'Science Labs Count',
                                      hint: 'e.g. 4',
                                      prefixIcon: Icons.biotech_rounded,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Labs count required';
                                        if (int.tryParse(val) == null) return 'Must be an integer';
                                        return null;
                                      },
                                    ),
                                    CustomTextField(
                                      controller: _comCountController,
                                      label: 'Computers Count',
                                      hint: 'e.g. 150',
                                      prefixIcon: Icons.computer_rounded,
                                      keyboardType: TextInputType.number,
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Computers count required';
                                        if (int.tryParse(val) == null) return 'Must be an integer';
                                        return null;
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 28),

                        // Card 4: Special Classifications Toggles
                        _buildSectionCard(
                          title: 'Special Program Classifications',
                          subtitle: 'Toggles for active government and institutional categories',
                          icon: Icons.toggle_on_outlined,
                          children: [
                            SwitchListTile(
                              title: const Text('Is Sports School', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Specialize in athletic curriculum and physical development.', style: TextStyle(fontSize: 12)),
                              value: _isSportSchool,
                              activeColor: AppColors.primary,
                              onChanged: (bool value) {
                                setState(() {
                                  _isSportSchool = value;
                                });
                              },
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            SwitchListTile(
                              title: const Text('Is Primary School', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Cater specifically to elementary primary education cycles.', style: TextStyle(fontSize: 12)),
                              value: _isPrimarySchool,
                              activeColor: AppColors.primary,
                              onChanged: (bool value) {
                                setState(() {
                                  _isPrimarySchool = value;
                                });
                              },
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            SwitchListTile(
                              title: const Text('Is Poshka School', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Entitled to free student nutritional meal program benefits.', style: TextStyle(fontSize: 12)),
                              value: _isPoshkaSchool,
                              activeColor: AppColors.primary,
                              onChanged: (bool value) {
                                setState(() {
                                  _isPoshkaSchool = value;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        
                        // Card 5: Media Gallery Upload
                        _buildSectionCard(
                          title: 'School Campus Media Gallery',
                          subtitle: 'Upload campus pictures (multipart files to server)',
                          icon: Icons.photo_library_outlined,
                          children: [
                            // Show images if any exist
                            if (_existingImages.isEmpty && _newPickedImages.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No Campus Images Selected',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Select images from your device to upload.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _existingImages.length + _newPickedImages.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                ),
                                itemBuilder: (context, index) {
                                  final isExisting = index < _existingImages.length;
                                  
                                  if (isExisting) {
                                    final img = _existingImages[index];
                                    return Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.network(
                                            img.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, err, stack) => const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.black.withOpacity(0.6),
                                            child: IconButton(
                                              icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                setState(() {
                                                  _existingImages.removeAt(index);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    final fileIndex = index - _existingImages.length;
                                    final file = _newPickedImages[fileIndex];
                                    
                                    return Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.primary, width: 1.5),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.memory(
                                            file.bytes!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, err, stack) => const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.black.withOpacity(0.6),
                                            child: IconButton(
                                              icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                setState(() {
                                                  _newPickedImages.removeAt(fileIndex);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        // Badge indicating it is a newly picked file to upload
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
                              label: const Text('Add School Photos'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Submit Row
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: hasDbId ? 'Update Profile' : 'Save and Create Profile',
                            isLoading: isSaving,
                            onPressed: _submitProfile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Section card wrapper utility
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }
}
