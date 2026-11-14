import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';
import '../models/rating_and_favorite_model.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream offers received by seller
  Stream<List<OfferModel>> streamReceivedOffers(String sellerId) {
    return _firestore
        .collection('offers')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final tB = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  // Stream offers made by buyer
  Stream<List<OfferModel>> streamMadeOffers(String buyerId) {
    return _firestore
        .collection('offers')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final tB = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  // Check if buyer already has an active pending/countered offer for this listing
  Future<OfferModel?> getActiveOfferForListing({
    required String listingId,
    required String buyerId,
  }) async {
    final snapshot = await _firestore
        .collection('offers')
        .where('listingId', isEqualTo: listingId)
        .where('buyerId', isEqualTo: buyerId)
        .get();

    for (final doc in snapshot.docs) {
      final offer = OfferModel.fromFirestore(doc);
      if ((offer.status == 'pending' || offer.status == 'countered') && !offer.isExpired) {
        return offer;
      }
    }
    return null;
  }

  // Make or update an offer
  Future<void> makeOffer({
    required String listingId,
    required String listingTitle,
    required String sellerId,
    required String buyerId,
    required String buyerName,
    required int amount,
    required String message,
  }) async {
    // Check if listing is still available
    final listingDoc = await _firestore.collection('listings').doc(listingId).get();
    if (!listingDoc.exists) {
      throw Exception('Listing has been deleted.');
    }
    final listingStatus = listingDoc.data()?['status'] ?? 'sold';
    if (listingStatus != 'available') {
      throw Exception('Listing is already $listingStatus.');
    }

    // Check for existing active offer
    final existing = await getActiveOfferForListing(listingId: listingId, buyerId: buyerId);

    if (existing != null) {
      // Update existing offer with history
      final updatedHistory = List<OfferHistoryItem>.from(existing.history)
        ..add(OfferHistoryItem(by: 'buyer', amount: amount, at: DateTime.now()));

      await _firestore.collection('offers').doc(existing.id).update({
        'amount': amount,
        'message': message,
        'status': 'pending',
        'history': updatedHistory.map((h) => h.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create fresh offer
      final docRef = _firestore.collection('offers').doc();
      final newOffer = OfferModel(
        id: docRef.id,
        listingId: listingId,
        listingTitle: listingTitle,
        sellerId: sellerId,
        buyerId: buyerId,
        buyerName: buyerName,
        amount: amount,
        history: [OfferHistoryItem(by: 'buyer', amount: amount, at: DateTime.now())],
        message: message,
        status: 'pending',
      );
      await docRef.set(newOffer.toMap(isNew: true));
    }
  }

  // Seller Action: Accept Offer (CRITICAL TRANSACTION)
  // Reserves the listing and automatically declines all other pending/countered offers
  Future<void> acceptOffer(String offerId) async {
    final offerRef = _firestore.collection('offers').doc(offerId);

    await _firestore.runTransaction((transaction) async {
      final offerSnapshot = await transaction.get(offerRef);
      if (!offerSnapshot.exists) {
        throw Exception('Offer does not exist.');
      }
      final offerData = offerSnapshot.data()!;
      final listingId = offerData['listingId'] as String;
      final buyerId = offerData['buyerId'] as String;
      final currentOfferStatus = offerData['status'] as String;

      if (currentOfferStatus == 'accepted') return; // already accepted
      if (currentOfferStatus != 'pending' && currentOfferStatus != 'countered') {
        throw Exception('Offer can no longer be accepted (status: $currentOfferStatus).');
      }

      final listingRef = _firestore.collection('listings').doc(listingId);
      final listingSnapshot = await transaction.get(listingRef);
      if (!listingSnapshot.exists) {
        throw Exception('Listing does not exist.');
      }
      final listingData = listingSnapshot.data()!;
      final listingStatus = listingData['status'] as String;

      if (listingStatus == 'sold') {
        throw Exception('Listing is already sold.');
      }
      if (listingStatus == 'reserved') {
        throw Exception('Listing is already reserved for another buyer.');
      }

      // Mark this offer accepted
      transaction.update(offerRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reserve listing
      transaction.update(listingRef, {
        'status': 'reserved',
        'reservedFor': buyerId,
      });
    });

    // Auto-decline other pending/countered offers for this listing
    final offerDoc = await offerRef.get();
    final listingId = offerDoc.data()?['listingId'];
    if (listingId != null) {
      final otherOffers = await _firestore
          .collection('offers')
          .where('listingId', isEqualTo: listingId)
          .get();

      final batch = _firestore.batch();
      for (final doc in otherOffers.docs) {
        if (doc.id != offerId) {
          final s = doc.data()['status'];
          if (s == 'pending' || s == 'countered') {
            batch.update(doc.reference, {
              'status': 'declined',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      await batch.commit();
    }
  }

  // Seller Action: Decline Offer
  Future<void> declineOffer(String offerId) async {
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Seller Action: Counter-offer
  Future<void> counterOffer({
    required String offerId,
    required int counterAmount,
    String? message,
  }) async {
    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) throw Exception('Offer not found');
    final offer = OfferModel.fromFirestore(offerDoc);

    final updatedHistory = List<OfferHistoryItem>.from(offer.history)
      ..add(OfferHistoryItem(by: 'seller', amount: counterAmount, at: DateTime.now()));

    await _firestore.collection('offers').doc(offerId).update({
      'amount': counterAmount,
      'status': 'countered',
      'history': updatedHistory.map((h) => h.toMap()).toList(),
      if (message != null && message.isNotEmpty) 'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Buyer Action: Accept counter
  Future<void> acceptCounter(String offerId) async {
    await acceptOffer(offerId);
  }

  // Buyer Action: Decline counter
  Future<void> declineCounter(String offerId) async {
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Buyer Action: Withdraw offer
  Future<void> withdrawOffer(String offerId) async {
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'withdrawn',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // RATINGS
  Future<bool> hasRated({required String listingId}) async {
    final doc = await _firestore.collection('ratings').doc(listingId).get();
    return doc.exists;
  }

  Future<void> submitRating({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required int stars,
    required String comment,
  }) async {
    final ratingRef = _firestore.collection('ratings').doc(listingId);
    final userRef = _firestore.collection('users').doc(sellerId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ratingRef);
      if (doc.exists) {
        throw Exception('You have already rated this sale.');
      }

      final rating = RatingModel(
        listingId: listingId,
        sellerId: sellerId,
        buyerId: buyerId,
        stars: stars,
        comment: comment,
      );

      transaction.set(ratingRef, rating.toMap());
      transaction.update(userRef, {
        'ratingSum': FieldValue.increment(stars),
        'ratingCount': FieldValue.increment(1),
      });
    });
  }
}
