import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/password_reset_screen.dart';
import 'features/school/data/repositories/school_repository_impl.dart';
import 'features/school/presentation/bloc/school_bloc.dart';
import 'features/school/presentation/screens/home_screen.dart';
import 'features/school/presentation/screens/profile_form_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate concrete implementation repositories
    final authRepository = AuthRepositoryImpl();
    final schoolRepository = SchoolRepositoryImpl();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository: authRepository),
        ),
        BlocProvider<SchoolBloc>(
          create: (context) => SchoolBloc(schoolRepository: schoolRepository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EduPortal - School Management System',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/password-reset': (context) => const PasswordResetScreen(insideApp: false),
          '/home': (context) => const HomeScreen(),
          '/profile-setup': (context) => const ProfileFormScreen(),
          '/change-password': (context) => const PasswordResetScreen(insideApp: true),
        },
      ),
    );
  }
}
