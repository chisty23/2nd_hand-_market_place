import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/sell_provider.dart';
import 'browse/browse_screen.dart';
import 'sell/sell_screen.dart';
import 'offers/offers_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BrowseScreen(),
    SellScreen(),
    OffersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
      if (user != null) {
        Provider.of<ListingProvider>(context, listen: false).initFavoritesStream(user.uid);
        Provider.of<SellProvider>(context, listen: false).initUserListings(user.uid);
        Provider.of<OfferProvider>(context, listen: false).initOffers(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context);
    final pendingOffersCount = offerProvider.receivedOffers
        .where((o) => o.effectiveStatus == 'pending')
        .length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight.withOpacity(0.3),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primaryDark),
              label: 'Browse',
            ),
            const NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box_rounded, color: AppColors.primaryDark),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingOffersCount > 0,
                label: Text('$pendingOffersCount'),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.local_offer_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingOffersCount > 0,
                label: Text('$pendingOffersCount'),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.local_offer_rounded, color: AppColors.primaryDark),
              ),
              label: 'Offers',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryDark),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
