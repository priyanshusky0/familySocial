import 'package:family_socail/app/features/Expense/expense_screen.dart';
import 'package:family_socail/app/features/Welcome/screens/create_family_screen.dart';
import 'package:family_socail/app/modules/Alarm/binding/alarm_binding.dart';
import 'package:family_socail/app/modules/alarm/views/alarm_screen.dart'; // ADD THIS
import 'package:family_socail/app/modules/HomePage/bindings/home_binding.dart';
import 'package:family_socail/app/modules/HomePage/views/home_page.dart';
import 'package:family_socail/app/modules/auth/bindings/auth_binding.dart';
import 'package:family_socail/app/modules/auth/bindings/splash_binding.dart';
import 'package:family_socail/app/modules/auth/views/auth_screen.dart';
import 'package:family_socail/app/modules/auth/views/splash_screen.dart';
import 'package:family_socail/app/routes/app_routes.dart';
import 'package:family_socail/app/features/document/document_upload_screen.dart';
import 'package:family_socail/app/features/password%20/screens/entry_screen.dart';
import 'package:get/get.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    // Splash Screen
    GetPage(
      name: Paths.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Auth Screen
    GetPage(
      name: Paths.auth,
      page: () => const AuthScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Home Screen
    GetPage(
      name: Paths.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Create Family Screen
    GetPage(
      name: Paths.createFamily,
      page: () => const CreateFamilyScreen(),
      // binding: CreateFamilyBinding(), // Add when you refactor
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Alarm Screen
    GetPage(
      name: Paths.alarm,
      page: () => const AlarmScreen(), // CHANGED - No more manual arguments
      binding: AlarmBinding(), // ADDED
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Documents Screen
    GetPage(
      name: Paths.documents,
      page: () => const DocumentSharingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Expense Screen
    GetPage(
      name: Paths.expense,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ExpenseTrackingScreen(
          familyId: args['familyId'],
          currentUserId: args['currentUserId'],
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Passwords Screen
    GetPage(
      name: Paths.passwords,
      page: () => const VaultUnlockScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}