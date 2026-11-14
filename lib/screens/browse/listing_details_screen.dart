import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_helper.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/rating_provider.dart';
import '../../providers/sell_provider.dart';
import '../../services/auth_service.dart';
import '../../services/listing_service.dart';
import '../sell/create_edit_listing_screen.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailsScreen({super.key, required this.listingId});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  bool _isActionLoading = false;

  void _showOfferDialog(ListingModel listing, String currentUserId, String currentUserName) {
    final amountController = TextEditingController();
    final messageController = TextEditingController();
    String? warning;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Make an Offer', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Asking Price: ৳${listing.price}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Your Offer (৳)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val) ?? 0;
                        if (parsed > listing.price) {
                          setDialogState(() {
                            warning = 'Your offer is higher than the asking price!';
                          });
                        } else {
                          setDialogState(() {
                            warning = null;
                          });
                        }
                      },
                    ),
                    if (warning != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        warning!,
                        style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Short Message (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Can meet in campus tomorrow noon',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final enteredAmount = int.tryParse(amountController.text.trim()) ?? 0;
                    if (enteredAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid offer amount.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    setState(() => _isActionLoading = true);

                    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
                    final success = await offerProvider.makeOffer(
                      listingId: listing.id,
                      listingTitle: listing.title,
                      sellerId: listing.sellerId,
                      buyerId: currentUserId,
                      buyerName: currentUserName,
                      amount: enteredAmount,
                      message: messageController.text.trim(),
                    );

                    setState(() => _isActionLoading = false);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Offer submitted successfully!'
                              : (offerProvider.errorMessage ?? 'Failed to send offer')),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Send Offer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _buyAtAskingPrice(ListingModel listing, String currentUserId, String currentUserName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buy at Asking Price'),
        content: Text('Confirm making an instant offer of ৳${listing.price} to reserve this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final success = await offerProvider.makeOffer(
      listingId: listing.id,
      listingTitle: listing.title,
      sellerId: listing.sellerId,
      buyerId: currentUserId,
      buyerName: currentUserName,
      amount: listing.price,
      message: 'Ready to buy immediately at asking price!',
    );
    setState(() => _isActionLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Instant offer submitted to seller!' : (offerProvider.errorMessage ?? 'Error')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showRatingDialog(ListingModel listing, String currentUserId) {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Seller'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How was your purchase experience?'),
                  const SizedBox(height: 12),
                  RatingBar.builder(
                    initialRating: 5,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setDialogState(() {
                        selectedStars = rating.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Review comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
                    final success = await ratingProvider.submitRating(
                      listingId: listing.id,
                      sellerId: listing.sellerId,
                      buyerId: currentUserId,
                      stars: selectedStars,
                      comment: commentController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Rating submitted! Thank you.' : (ratingProvider.errorMessage ?? 'Error')),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.firebaseUser?.uid ?? '';
    final currentUserName = auth.userProfile?.name ?? 'Student';
    final listingProvider = Provider.of<ListingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: StreamBuilder<ListingModel?>(
        stream: _listingService.streamListing(widget.listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listing = snapshot.data;
          if (listing == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Listing')),
              body: const Center(
                child: Text('This listing is no longer available.', style: TextStyle(fontSize: 16)),
              ),
            );
          }

          final isSeller = listing.sellerId == currentUserId;
          final catColor = CategoryHelper.getColor(listing.category);
          final catIcon = CategoryHelper.getIcon(listing.category);
          final isFav = listingProvider.isFavorite(listing.id);

          return CustomScrollView(
            slivers: [
              // Hero App Bar with Image or Icon
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: catColor,
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (!isSeller)
                    CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.secondary : Colors.white,
                        ),
                        onPressed: () {
                          listingProvider.toggleFavorite(
                            userId: currentUserId,
                            listingId: listing.id,
                            listingTitle: listing.title,
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: listing.imageUrl != null && listing.imageUrl!.startsWith('http')
                      ? Image.network(
                          listing.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(catIcon, size: 80, color: Colors.white),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [catColor, catColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(catIcon, size: 90, color: Colors.white),
                          ),
                        ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Condition Chips Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: listing.isAvailable
                                  ? AppColors.statusAvailable.withOpacity(0.15)
                                  : listing.isReserved
                                      ? AppColors.statusReserved.withOpacity(0.15)
                                      : AppColors.statusSold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              listing.status.toUpperCase(),
                              style: TextStyle(
                                color: listing.isAvailable
                                    ? AppColors.statusAvailable
                                    : listing.isReserved
                                        ? AppColors.statusReserved
                                        : AppColors.statusSold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Condition: ${listing.condition.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title & Price
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '৳${listing.price}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (listing.negotiable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Price Negotiable',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),

                      // Seller Card
                      StreamBuilder<UserModel?>(
                        stream: _authService.streamUserProfile(listing.sellerId),
                        builder: (context, sellerSnap) {
                          final seller = sellerSnap.data;
                          final sellerName = seller?.name ?? listing.sellerName;
                          final rating = seller?.averageRating ?? 0.0;
                          final count = seller?.ratingCount ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                                  child: Text(
                                    sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sellerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating > 0
                                                ? '${rating.toStringAsFixed(1)} ($count reviews)'
                                                : 'New Seller (No ratings yet)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description.isNotEmpty
                            ? listing.description
                            : 'No description provided by the seller.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      if (_isActionLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (isSeller) ...[
                        // Seller Controls
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateEditListingScreen(listingToEdit: listing),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (!listing.isSold)
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  label: const Text('Mark Sold', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () async {
                                    final sellProvider = Provider.of<SellProvider>(context, listen: false);
                                    await sellProvider.markSold(
                                      listing.id,
                                      listing.sellerId,
                                      buyerId: listing.reservedFor,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Listing marked as sold!')),
                                      );
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (listing.isReserved)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                final sellProvider = Provider.of<SellProvider>(context, listen: false);
                                await sellProvider.setStatus(listing.id, 'available', reservedFor: null);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Released back to Available status')),
                                  );
                                }
                              },
                              child: const Text('Release back to Available'),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            label: const Text('Delete Listing', style: TextStyle(color: AppColors.error)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Listing'),
                                  content: const Text('Are you sure you want to permanently delete this listing?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final sellProvider = Provider.of<SellProvider>(context, listen: false);
                                await sellProvider.deleteListing(listing.id);
                                if (mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ] else ...[
                        // Buyer Controls
                        if (listing.isAvailable) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  onPressed: () => _showOfferDialog(listing, currentUserId, currentUserName),
                                  child: const Text(
                                    'Make Offer',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => _buyAtAskingPrice(listing, currentUserId, currentUserName),
                                  child: const Text(
                                    'Buy at Asking',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (listing.isSold && listing.reservedFor == currentUserId) ...[
                          // Buyer who bought this item can leave a 1-5 star review
                          FutureBuilder<bool>(
                            future: Provider.of<RatingProvider>(context, listen: false).hasRated(listing.id),
                            builder: (context, hasRatedSnap) {
                              final alreadyRated = hasRatedSnap.data ?? false;
                              if (alreadyRated) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✓ You have rated this transaction. Thank you!',
                                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                              return SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.star_rounded, color: Colors.white),
                                  label: const Text('Leave Seller Review (1-5 Stars)', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => _showRatingDialog(listing, currentUserId),
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                listing.isReserved
                                    ? 'This item is currently reserved.'
                                    : 'This item has already been sold.',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
