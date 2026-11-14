import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/offer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offer_provider.dart';
import '../browse/listing_details_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
      if (user != null) {
        Provider.of<OfferProvider>(context, listen: false).initOffers(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCounterDialog(BuildContext context, OfferModel offer) {
    final counterController = TextEditingController();
    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send Counter-Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Offer: ৳${offer.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: counterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Counter Amount (৳)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. Lowest I can do is this',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
            onPressed: () async {
              final newAmt = int.tryParse(counterController.text.trim()) ?? 0;
              if (newAmt <= 0) return;
              Navigator.pop(ctx);

              final offerProvider = Provider.of<OfferProvider>(context, listen: false);
              final success = await offerProvider.counterOffer(
                offerId: offer.id,
                counterAmount: newAmt,
                message: msgController.text.trim(),
              );

              if (context.mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(offerProvider.errorMessage ?? 'Failed to send counter'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Send Counter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Offers Negotiation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryDark,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(text: 'Received (${offerProvider.receivedOffers.length})'),
            Tab(text: 'Made (${offerProvider.madeOffers.length})'),
          ],
        ),
      ),
      body: offerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOffersList(context, offerProvider.receivedOffers, isSellerView: true),
                _buildOffersList(context, offerProvider.madeOffers, isSellerView: false),
              ],
            ),
    );
  }

  Widget _buildOffersList(BuildContext context, List<OfferModel> offers, {required bool isSellerView}) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSellerView ? Icons.inbox_rounded : Icons.outbox_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isSellerView ? 'No offers received yet' : 'You haven\'t made any offers yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _buildOfferCard(context, offer, isSellerView: isSellerView);
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferModel offer, {required bool isSellerView}) {
    final status = offer.effectiveStatus;
    final isActionable = !offer.isExpired && (status == 'pending' || status == 'countered');
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = AppColors.success;
        break;
      case 'declined':
        statusColor = AppColors.error;
        break;
      case 'countered':
        statusColor = AppColors.accent;
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        break;
      case 'expired':
        statusColor = Colors.deepOrange;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListingDetailsScreen(listingId: offer.listingId),
                        ),
                      );
                    },
                    child: Text(
                      offer.listingTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Amount & User
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Offer: ৳${offer.amount}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                Text(
                  isSellerView ? 'From: ${offer.buyerName}' : 'Waiting on Seller',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),

            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${offer.message}"',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ),
            ],

            // Negotiation History preview
            if (offer.history.isNotEmpty) ...[
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Negotiation Trail (${offer.history.length} events)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                children: offer.history.map((h) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      h.by == 'seller' ? Icons.store_rounded : Icons.person_rounded,
                      size: 18,
                      color: h.by == 'seller' ? AppColors.primary : AppColors.secondary,
                    ),
                    title: Text('${h.by.toUpperCase()} offered ৳${h.amount}'),
                    trailing: Text(DateFormat('hh:mm a, dd MMM').format(h.at), style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // State Machine Action Buttons
            if (isActionable) ...[
              const Divider(),
              if (isSellerView) ...[
                // Seller controls: Accept, Decline, Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () => offerProvider.declineOffer(offer.id),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showCounterDialog(context, offer),
                      child: const Text('Counter-offer'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () async {
                        final ok = await offerProvider.acceptOffer(offer.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Offer accepted! Listing marked Reserved.'
                                  : (offerProvider.errorMessage ?? 'Error accepting offer')),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                      child: const Text('Accept', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ] else ...[
                // Buyer controls: If countered by seller, Accept counter or Decline counter. Also withdraw.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () => offerProvider.withdrawOffer(offer.id),
                      child: const Text('Withdraw'),
                    ),
                    if (status == 'countered') ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => offerProvider.declineCounter(offer.id),
                        child: const Text('Decline Counter'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () => offerProvider.acceptCounter(offer.id),
                        child: const Text('Accept Counter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
