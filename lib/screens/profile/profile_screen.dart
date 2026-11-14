import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/listing_service.dart';
import '../browse/listing_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ListingService _listingService = ListingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userProfile;
    final listingProvider = Provider.of<ListingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Profile Header with Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 28, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? 'Campus User',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                        ),
                        if (user?.department.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user!.department,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // User Statistics Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          title: 'Sold',
                          value: '${user?.soldCount ?? 0}',
                          icon: Icons.sell_rounded,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          title: 'Bought',
                          value: '${user?.boughtCount ?? 0}',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          title: 'Rating',
                          value: user != null && user.ratingCount > 0
                              ? user.averageRating.toStringAsFixed(1)
                              : 'N/A',
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar for Favorites & Settings
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primaryDark,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: [
                      Tab(text: 'Saved Favorites (${listingProvider.favorites.length})'),
                      const Tab(text: 'Account Settings'),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Favorites Tab
            _buildFavoritesList(context, listingProvider),

            // Account Settings Tab
            _buildSettingsTab(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, ListingProvider listingProvider) {
    final favs = listingProvider.favorites;

    if (favs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No favorite listings yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the heart icon on any listing to save it here.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favs.length,
      itemBuilder: (context, index) {
        final fav = favs[index];
        return FutureBuilder<ListingModel?>(
          future: _listingService.getListing(fav.listingId),
          builder: (context, snapshot) {
            final listing = snapshot.data;
            final isAvailable = listing != null && listing.isAvailable;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAvailable ? AppColors.primaryLight.withOpacity(0.2) : Colors.grey.shade200,
                  child: Icon(
                    isAvailable ? Icons.shopping_bag_outlined : Icons.remove_shopping_cart_outlined,
                    color: isAvailable ? AppColors.primaryDark : Colors.grey,
                  ),
                ),
                title: Text(
                  listing?.title ?? fav.listingTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  listing == null
                      ? 'No longer available'
                      : listing.isSold
                          ? 'Sold out'
                          : listing.isReserved
                              ? 'Reserved'
                              : '৳${listing.price} • ${listing.condition.toUpperCase()}',
                  style: TextStyle(
                    color: isAvailable ? AppColors.primaryDark : AppColors.error,
                    fontWeight: isAvailable ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.secondary),
                  onPressed: () {
                    final uid = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid;
                    if (uid != null) {
                      listingProvider.toggleFavorite(
                        userId: uid,
                        listingId: fav.listingId,
                        listingTitle: fav.listingTitle,
                      );
                    }
                  },
                ),
                onTap: isAvailable
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListingDetailsScreen(listingId: fav.listingId),
                          ),
                        );
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Colors.white,
          leading: const Icon(Icons.security_rounded, color: AppColors.primary),
          title: const Text('Campus Verified Account'),
          subtitle: const Text('Authentication secured by Firebase'),
          trailing: const Icon(Icons.check_circle, color: AppColors.success),
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Colors.white,
          leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
          title: const Text('Marketplace Guidelines'),
          subtitle: const Text('Read safety and negotiation rules'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'PassItOn Campus',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Second-hand Marketplace for University Students',
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Provider.of<ListingProvider>(context, listen: false).cancelSubscriptions();
              await auth.logout();
            },
          ),
        ),
      ],
    );
  }
}
