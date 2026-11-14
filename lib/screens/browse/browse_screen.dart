import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_helper.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import 'listing_details_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'recently';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Consumer<ListingProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Sort',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.resetFilters();
                          },
                          child: const Text('Reset All'),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Condition Filter
                    const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'new', 'like-new', 'used', 'worn'].map((cond) {
                        final isSel = provider.selectedCondition.toLowerCase() == cond.toLowerCase();
                        return ChoiceChip(
                          label: Text(cond.toUpperCase()),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => provider.setCondition(cond),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Price Range Slider
                    Text(
                      'Price Range: ৳${provider.priceRange.start.toInt()} - ৳${provider.priceRange.end.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    RangeSlider(
                      values: provider.priceRange,
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      activeColor: AppColors.primary,
                      labels: RangeLabels(
                        '৳${provider.priceRange.start.toInt()}',
                        '৳${provider.priceRange.end.toInt()}',
                      ),
                      onChanged: (vals) => provider.setPriceRange(vals),
                    ),
                    const SizedBox(height: 16),

                    // Sort Order
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    RadioListTile<SortOption>(
                      title: const Text('Newest First'),
                      value: SortOption.newest,
                      groupValue: provider.currentSort,
                      onChanged: (val) {
                        if (val != null) provider.setSortOption(val);
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Price: Low to High'),
                      value: SortOption.priceLowToHigh,
                      groupValue: provider.currentSort,
                      onChanged: (val) {
                        if (val != null) provider.setSortOption(val);
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Price: High to Low'),
                      value: SortOption.priceHighToLow,
                      groupValue: provider.currentSort,
                      onChanged: (val) {
                        if (val != null) provider.setSortOption(val);
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'PassItOn Campus',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
            tooltip: 'Filter & Sort',
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => listingProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search books, bikes, electronics...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: listingProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () => listingProvider.setSearchQuery(''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Categories Horizontal Bar
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: CategoryHelper.categories.length,
              itemBuilder: (context, index) {
                final cat = CategoryHelper.categories[index];
                final isSelected = listingProvider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  child: FilterChip(
                    avatar: Icon(
                      CategoryHelper.getIcon(cat),
                      size: 16,
                      color: isSelected ? Colors.white : CategoryHelper.getColor(cat),
                    ),
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (_) => listingProvider.setCategory(cat),
                  ),
                );
              },
            ),
          ),

          // Items Grid View
          Expanded(
            child: listingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : listingProvider.filteredListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No listings found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => listingProvider.resetFilters(),
                              child: const Text('Reset Filters'),
                            )
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: listingProvider.filteredListings.length,
                        itemBuilder: (context, index) {
                          final item = listingProvider.filteredListings[index];
                          final isFav = listingProvider.isFavorite(item.id);

                          return _buildListingCard(
                            context,
                            item,
                            isFav,
                            currentUserId,
                            listingProvider,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(
    BuildContext context,
    ListingModel item,
    bool isFav,
    String currentUserId,
    ListingProvider provider,
  ) {
    final catColor = CategoryHelper.getColor(item.category);
    final catIcon = CategoryHelper.getIcon(item.category);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailsScreen(listingId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview Container (Image or Category Icon)
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(catIcon, size: 48, color: catColor),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(catIcon, size: 48, color: catColor),
                        ),
                ),
                // Heart Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.secondary : AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        if (currentUserId.isNotEmpty) {
                          provider.toggleFavorite(
                            userId: currentUserId,
                            listingId: item.id,
                            listingTitle: item.title,
                          );
                        }
                      },
                    ),
                  ),
                ),
                // Condition Badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.condition.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeAgo(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '৳${item.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        if (item.negotiable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Neg',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
