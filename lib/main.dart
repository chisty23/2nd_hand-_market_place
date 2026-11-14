import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/sell_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/rating_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init: $e");
  }

  runApp(const PassItOnApp());
}

class PassItOnApp extends StatelessWidget {
  const PassItOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ListingProvider>(create: (_) => ListingProvider()),
        ChangeNotifierProvider<SellProvider>(create: (_) => SellProvider()),
        ChangeNotifierProvider<OfferProvider>(create: (_) => OfferProvider()),
        ChangeNotifierProvider<RatingProvider>(create: (_) => RatingProvider()),
      ],
      child: MaterialApp(
        title: 'PassItOn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.bgLight,
          ),
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainNavigationScreen();
    }

    return const AuthScreen();
  }
}
