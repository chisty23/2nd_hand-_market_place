import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_helper.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/sell_provider.dart';
import 'create_edit_listing_screen.dart';
import '../browse/listing_details_screen.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
      if (user != null) {
        Provider.of<SellProvider>(context, listen: false).initUserListings(user.uid);
        Provider.of<OfferProvider>(context, listen: false).initOffers(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellProvider = Provider.of<SellProvider>(context);
    final offerProvider = Provider.of<OfferProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryDark, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
          );
        },
      ),
      body: sellProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sellProvider.myListings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'You haven\'t posted any items yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sell your used textbooks, electronics, cycles, or notes to fellow students.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Post Your First Item', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateEditListingScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellProvider.myListings.length,
                  itemBuilder: (context, index) {
                    final item = sellProvider.myListings[index];
                    final pendingOffersCount = offerProvider.pendingCountForListing(item.id);
                    return _buildMyListingCard(context, item, pendingOffersCount, sellProvider);
                  },
                ),
    );
  }

  Widget _buildMyListingCard(
    BuildContext context,
    ListingModel item,
    int pendingOffersCount,
    SellProvider sellProvider,
  ) {
    final catColor = CategoryHelper.getColor(item.category);
    final catIcon = CategoryHelper.getIcon(item.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ListingDetailsScreen(listingId: item.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail or Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(catIcon, color: catColor, size: 36),
                            ),
                          )
                        : Icon(catIcon, color: catColor, size: 36),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${item.price} • ${item.condition.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.isAvailable
                                    ? AppColors.statusAvailable.withOpacity(0.15)
                                    : item.isReserved
                                        ? AppColors.statusReserved.withOpacity(0.15)
                                        : AppColors.statusSold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: item.isAvailable
                                      ? AppColors.statusAvailable
                                      : item.isReserved
                                          ? AppColors.statusReserved
                                          : AppColors.statusSold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (pendingOffersCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$pendingOffersCount pending offers',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateEditListingScreen(listingToEdit: item)),
                      );
                    },
                  ),
                  if (item.isAvailable)
                    TextButton.icon(
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Reserve'),
                      onPressed: () => sellProvider.setStatus(item.id, 'reserved'),
                    )
                  else if (item.isReserved)
                    TextButton.icon(
                      icon: const Icon(Icons.bookmark_remove_outlined, size: 18),
                      label: const Text('Make Available'),
                      onPressed: () => sellProvider.setStatus(item.id, 'available', reservedFor: null),
                    ),
                  if (!item.isSold)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => sellProvider.markSold(item.id, item.sellerId, buyerId: item.reservedFor),
                      child: const Text('Mark Sold', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
