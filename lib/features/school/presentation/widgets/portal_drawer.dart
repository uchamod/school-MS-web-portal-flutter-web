import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_portal_web/core/constants/colors.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_bloc.dart';
import 'package:school_portal_web/features/school/presentation/bloc/school_state.dart';
import 'package:school_portal_web/features/school/domain/entities/school_entity.dart';

class PortalDrawer extends StatelessWidget {
  final String activeRoute;

  const PortalDrawer({super.key, required this.activeRoute});

  int _calculateCompletion(SchoolEntity school) {
    if (school.isEmpty) return 0;
    
    int score = 0;
    if (school.name.trim().isNotEmpty) score += 15;
    if (school.address.trim().isNotEmpty) score += 10;
    if (school.type.trim().isNotEmpty) score += 10;
    if (school.province.isNotEmpty && school.district.isNotEmpty) score += 15;
    if (school.stCount > 0 && school.techCount > 0) score += 15;
    if (school.buildingCount > 0 && school.labCount > 0) score += 15;
    if (school.lat != null && school.lng != null) score += 10;
    if (school.principal.trim().isNotEmpty) score += 10;
    
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final schoolState = context.watch<SchoolBloc>().state;

    String email = 'user@school.com';
    if (authState is Authenticated) {
      email = authState.user.email;
    }

    int completionPercentage = 0;
    if (schoolState is SchoolLoaded) {
      completionPercentage = _calculateCompletion(schoolState.school);
    } else if (schoolState is SchoolSaving) {
      completionPercentage = _calculateCompletion(schoolState.school);
    }

    return Drawer(
      child: Column(
        children: [
          // Drawer Header with Slate-Blue Gradient Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 32,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'School Portal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Completion Meter section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 4.5,
                        ),
                      ),
                      Text(
                        '$completionPercentage%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          completionPercentage == 100 
                              ? 'Fully Configured!'
                              : 'Complete details to activate.',
                          style: TextStyle(
                            fontSize: 11,
                            color: completionPercentage == 100 
                                ? AppColors.success 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Drawer Navigation Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home Dashboard',
                  route: '/home',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.edit_note_outlined,
                  activeIcon: Icons.edit_note_rounded,
                  label: 'School Details Form',
                  route: '/profile-setup',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.lock_reset_outlined,
                  activeIcon: Icons.lock_reset_rounded,
                  label: 'Reset Password',
                  route: '/change-password',
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  // Show logout alert confirmation
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to sign out from the School Portal?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // close modal
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isSelected = activeRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primaryLight.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isSelected) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
