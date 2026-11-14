import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String listingId;
  final String listingTitle;
  final DateTime? savedAt;

  FavoriteModel({
    required this.listingId,
    required this.listingTitle,
    this.savedAt,
  });

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FavoriteModel(
      listingId: doc.id,
      listingTitle: data['listingTitle'] ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingTitle': listingTitle,
      'savedAt': FieldValue.serverTimestamp(),
    };
  }
}

class RatingModel {
  final String listingId; // used as document ID to prevent duplicate ratings
  final String sellerId;
  final String buyerId;
  final int stars;
  final String comment;
  final DateTime? createdAt;

  RatingModel({
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.stars,
    required this.comment,
    this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RatingModel(
      listingId: doc.id,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      stars: (data['stars'] as num?)?.toInt() ?? 5,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'buyerId': buyerId,
      'stars': stars,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
