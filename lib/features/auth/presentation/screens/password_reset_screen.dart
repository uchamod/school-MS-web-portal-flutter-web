import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_portal_web/core/constants/colors.dart';
import 'package:school_portal_web/core/widgets/custom_button.dart';
import 'package:school_portal_web/core/widgets/custom_text_field.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_portal_web/features/auth/presentation/bloc/auth_state.dart';

class PasswordResetScreen extends StatefulWidget {
  final bool insideApp; // Indicates if navigated from inside the dashboard drawer

  const PasswordResetScreen({super.key, this.insideApp = false});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If inside app, pre-fill email from current active user
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthPasswordResetSubmitted(
              email: _emailController.text.trim(),
              newPassword: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final authState = context.read<AuthBloc>().state;
    final isPreFilled = authState is Authenticated;

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.insideApp ? 'Change Password' : 'Reset Password',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.insideApp 
                ? 'Enter a new secure password for your account'
                : 'Enter your email and specify a new password to recover access',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          
          // Email Input (Readonly if Pre-filled inside App)
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'example@school.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: isPreFilled,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // New Password Input
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_open_rounded,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter a new password';
              }
              if (val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Confirm New Password Input
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please confirm your new password';
              }
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: widget.insideApp ? 'Update Password' : 'Reset Password',
              isLoading: false, // Will be driven by listener below
              onPressed: _submitForm,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.insideApp 
                      ? state.message
                      : 'Password reset successfully! Please log in with your new credentials.',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            if (widget.insideApp) {
              // Simply clear controllers and go back
              _passwordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            } else {
              // Return to login
              Navigator.pushReplacementNamed(context, '/login');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1000 : 450,
                  maxHeight: isDesktop ? 600 : double.infinity,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    // Dual-pane illustration Sidebar (Visible on Desktop only)
                    if (isDesktop)
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Secure Credentials,\nPeace of Mind.',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                      height: 1.3,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Easily change or restore your passwords while maintaining robust encryption and security over your portal.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Form Pane
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                        child: isLoading
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: AppColors.primary),
                                    SizedBox(height: 16),
                                    Text('Processing password reset...'),
                                  ],
                                ),
                              )
                            : content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
