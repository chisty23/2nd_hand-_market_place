import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/rating_and_favorite_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stream of all available listings
  Stream<List<ListingModel>> streamAvailableListings() {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    });
  }

  // Real-time stream of single listing
  Stream<ListingModel?> streamListing(String listingId) {
    return _firestore.collection('listings').doc(listingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ListingModel.fromFirestore(doc);
    });
  }

  // Real-time stream for user's own listings (Sell tab)
  Stream<List<ListingModel>> streamUserListings(String userId) {
    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  // Create Listing
  Future<String> createListing(ListingModel listing) async {
    final docRef = _firestore.collection('listings').doc();
    final data = listing.toMap(isNew: true);
    await docRef.set(data);
    return docRef.id;
  }

  // Edit Listing
  Future<void> updateListing(ListingModel listing) async {
    await _firestore.collection('listings').doc(listing.id).update({
      'title': listing.title,
      'keywords': ListingModel.generateKeywords(listing.title),
      'description': listing.description,
      'category': listing.category,
      'condition': listing.condition,
      'price': listing.price,
      'negotiable': listing.negotiable,
      'imageUrl': listing.imageUrl,
    });
  }

  // Update status (e.g. available, reserved, sold)
  Future<void> updateStatus(String listingId, String status, {String? reservedFor}) async {
    await _firestore.collection('listings').doc(listingId).update({
      'status': status,
      'reservedFor': reservedFor,
    });
  }

  // Mark Sold and increment seller & buyer count
  Future<void> markSold({
    required String listingId,
    required String sellerId,
    String? buyerId,
  }) async {
    final batch = _firestore.batch();
    final listingRef = _firestore.collection('listings').doc(listingId);
    batch.update(listingRef, {
      'status': 'sold',
      'reservedFor': buyerId,
    });

    // Increment seller soldCount
    final sellerRef = _firestore.collection('users').doc(sellerId);
    batch.update(sellerRef, {
      'soldCount': FieldValue.increment(1),
    });

    // If buyer known, increment buyer boughtCount
    if (buyerId != null && buyerId.isNotEmpty) {
      final buyerRef = _firestore.collection('users').doc(buyerId);
      batch.update(buyerRef, {
        'boughtCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    await _firestore.collection('listings').doc(listingId).delete();
  }

  // FAVORITES
  Stream<List<FavoriteModel>> streamFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FavoriteModel.fromFirestore(doc)).toList());
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required String listingTitle,
    required bool isCurrentlyFavorited,
  }) async {
    final favRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(listingId);

    if (isCurrentlyFavorited) {
      await favRef.delete();
    } else {
      await favRef.set({
        'listingTitle': listingTitle,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<ListingModel?> getListing(String listingId) async {
    final doc = await _firestore.collection('listings').doc(listingId).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }
}
