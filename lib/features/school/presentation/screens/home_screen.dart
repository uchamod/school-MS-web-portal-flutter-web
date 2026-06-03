import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_portal_web/core/constants/colors.dart';
import 'package:school_portal_web/features/auth/domain/entities/user_entity.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_bloc.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_event.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_state.dart';
import 'package:school_portal_web/features/school/domain/entities/school_entity.dart';
import 'package:school_portal_web/features/school/domain/entities/school_image.dart';
import 'package:school_portal_web/features/school/presentation/widgets/portal_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch school loading as soon as home is loaded
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SchoolBloc>().add(SchoolLoadRequested(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final authState = context.watch<AuthBloc>().state;

    UserEntity? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EDU PORTAL DASHBOARD',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      drawer: const PortalDrawer(activeRoute: '/home'),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          if (state is SchoolLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading school workspace...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          if (state is SchoolError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading school: ${state.message}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (currentUser != null) {
                        context.read<SchoolBloc>().add(SchoolLoadRequested(currentUser.id));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SchoolLoaded) {
            final school = state.school;
            
            if (school.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/profile-setup');
              });
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Redirecting to profile setup...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            
            return _buildDashboardContent(context, school, currentUser, isDesktop);
          }

          return const Center(child: Text('Initializing dashboard...'));
        },
      ),
    );
  }

  // Beautiful CTA displayed when school profile is unconfigured
  Widget _buildEmptyCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Ring
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      size: 64,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Profile Incomplete!',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your School Profile directory has not been constructed yet. Please click the button below to fill in details such as classroom capacities, teacher metrics, coordinates, and school imagery.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile-setup');
                      },
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                      label: const Text('Complete School Profile Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dashboard layout once school profile data is completed
  Widget _buildDashboardContent(BuildContext context, SchoolEntity school, UserEntity? user, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 36.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Beautiful Welcome Header Banner
          _buildHeaderBanner(context, school, isDesktop),
          
          const SizedBox(height: 32),
          
          Text(
            'KEY CAPACITY METRICS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          
          // Row 2: Grid of Capacity Stats (Responsive: 5 columns on desktop, 2-3 on tablet/mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 1;
              if (width > 1000) {
                crossAxisCount = 5;
              } else if (width > 700) {
                crossAxisCount = 3;
              } else if (width > 450) {
                crossAxisCount = 2;
              }
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 1.4 : 1.7,
                children: [
                  _buildMetricCard(
                    title: 'Students Count',
                    value: school.stCount.toString(),
                    icon: Icons.people_alt_rounded,
                    accentColor: AppColors.primary,
                  ),
                  _buildMetricCard(
                    title: 'Teachers Count',
                    value: school.techCount.toString(),
                    icon: Icons.supervisor_account_rounded,
                    accentColor: AppColors.primaryDark,
                  ),
                  _buildMetricCard(
                    title: 'Buildings Count',
                    value: school.buildingCount.toString(),
                    icon: Icons.apartment_rounded,
                    accentColor: const Color(0xFF06B6D4),
                  ),
                  _buildMetricCard(
                    title: 'Science Labs',
                    value: school.labCount.toString(),
                    icon: Icons.biotech_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                  ),
                  _buildMetricCard(
                    title: 'Computer Count',
                    value: school.comCount.toString(),
                    icon: Icons.computer_rounded,
                    accentColor: const Color(0xFFEC4899),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Row 3: Split layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details, Overview, & Account
              Expanded(
                flex: isDesktop ? 3 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGIONAL DETAILS & LOCATION',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationCard(context, school, isDesktop),
                    const SizedBox(height: 32),
                    
                    Text(
                      'SCHOOL OVERVIEW',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewCard(context, school),
                    
                    if (user != null) ...[
                      const SizedBox(height: 32),
                      Text(
                        'CONNECTED ACCOUNT DETAILS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.5,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildAccountCard(context, user),
                    ],
                  ],
                ),
              ),
              
              if (isDesktop) const SizedBox(width: 32),
              
              // Gallery Panel (Desktop only)
              if (isDesktop)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEDIA & PORTAL IMAGERY',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.5,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildGalleryCard(context, school),
                    ],
                  ),
                ),
            ],
          ),
          
          // Render Gallery below for small screen layouts (Mobile)
          if (!isDesktop) ...[
            const SizedBox(height: 32),
            Text(
              'MEDIA & PORTAL IMAGERY',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            _buildGalleryCard(context, school),
          ],
        ],
      ),
    );
  }

  // Welcome Header Banner Widget
  Widget _buildHeaderBanner(BuildContext context, SchoolEntity school, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 36.0 : 24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        school.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (school.isSportSchool)
                      _buildBannerChip(Icons.sports_soccer_rounded, 'SPORTS SCHOOL'),
                    if (school.isPrimarySchool)
                      _buildBannerChip(Icons.child_care_rounded, 'PRIMARY SCHOOL'),
                    if (school.isPoshkaSchool)
                      _buildBannerChip(Icons.restaurant_rounded, 'POSHKA PROGRAM'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  school.name,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        school.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBannerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Capacity Metric Card Widget
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Location & Map Display Card Widget
  Widget _buildLocationCard(BuildContext context, SchoolEntity school, bool isDesktop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, Icons.map_outlined, 'Province', school.province),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.assistant_direction_outlined, 'District', school.district),
            const SizedBox(height: 12),
            _buildDetailRow(
              context, 
              Icons.gps_fixed_outlined, 
              'GPS Coordinates', 
              school.lat != null && school.lng != null 
                  ? 'Lat: ${school.lat!.toStringAsFixed(6)}, Lng: ${school.lng!.toStringAsFixed(6)}' 
                  : 'Not Configured'
            ),
            const SizedBox(height: 24),
            
            // Map Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _MapPainter(),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: AppColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          school.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          '${school.lat?.toStringAsFixed(4) ?? "0.0"}, ${school.lng?.toStringAsFixed(4) ?? "0.0"}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // School Overview Widget
  Widget _buildOverviewCard(BuildContext context, SchoolEntity school) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, Icons.person_outline_rounded, 'Principal Name', school.principal.isNotEmpty ? school.principal : 'Not Configured'),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Text(
                  'About School',
                  style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                school.discription.isNotEmpty ? school.discription : 'No description provided.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Account Details Card Widget
  Widget _buildAccountCard(BuildContext context, UserEntity user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, Icons.fingerprint_rounded, 'Account UUID (schoolId)', user.id),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.alternate_email_rounded, 'Registration Email', user.email),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.phone_android_rounded, 'Account Phone Number', user.phoneNumber!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Media Gallery Panel Widget
  Widget _buildGalleryCard(BuildContext context, SchoolEntity school) {
    final hasImages = school.images.isNotEmpty;
    
    // Provide gorgeous mock icons representation if no images uploaded yet
    final List<SchoolImage> displayImages = school.images;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'School Campus Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (hasImages)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${school.images.length} Photos',
                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Image list
            if (!hasImages)
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
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[350]),
                    const SizedBox(height: 12),
                    const Text(
                      'No Campus Media',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const Text(
                      'Navigate to School Details form to pick and upload campus pictures.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final img = displayImages[index].imageUrl;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw grid contours resembling water streams / map divisions
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0;

    // Draw coordinate lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }

    // Draw contoured mock river/roads
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width, size.height * 0.6);

    final roadPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
