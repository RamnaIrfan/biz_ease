// lib/main.dart - FIXED VERSION
import 'package:biz_ease/models/owner_model.dart';
import 'package:biz_ease/screens/login_business.dart';
import 'package:biz_ease/screens/register_business_page.dart';
import 'package:biz_ease/screens/signup_business.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_provider.dart';
import 'screens/cart_provider.dart';
import 'screens/wishlist_provider.dart';
import 'screens/order_provider.dart';
import 'screens/recent_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_page.dart';
import 'screens/login_customer.dart'; // ADD THIS IMPORT
import 'screens/signup_customer.dart'; // ADD THIS IMPORT
import 'screens/home_page.dart';
import 'screens/user_profile_page.dart';
import 'screens/owner_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RecentProvider()),
      ],
      child: MaterialApp(
        title: 'biZEase',
        theme: ThemeData(
          primaryColor: const Color(0xFFD88A1F),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD88A1F),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/welcome': (context) => const WelcomePage(),
          '/loginBusiness': (context) => const LoginBusinessPage(),
          '/signupBusiness': (context) => const SignupBusinessPage(),
          '/registerBusiness': (context) => const RegisterBusinessPage(),
           '/ownerDashboard': (context) {
    final owner = ModalRoute.of(context)!.settings.arguments as OwnerModel;
    return OwnerDashboardPage(owner: owner);
  },
          '/home': (context) => const HomePage(),
          '/loginCustomer': (context) => const LoginCustomerPage(),
          '/signupCustomer': (context) => const SignupCustomerPage(),
          '/profile': (context) => const UserProfilePage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}