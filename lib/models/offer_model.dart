import 'package:cloud_firestore/cloud_firestore.dart';

class OfferHistoryItem {
  final String by; // seller | buyer
  final int amount;
  final DateTime at;

  OfferHistoryItem({
    required this.by,
    required this.amount,
    required this.at,
  });

  factory OfferHistoryItem.fromMap(Map<String, dynamic> map) {
    DateTime parsedAt = DateTime.now();
    if (map['at'] is Timestamp) {
      parsedAt = (map['at'] as Timestamp).toDate();
    } else if (map['at'] is String) {
      parsedAt = DateTime.tryParse(map['at']) ?? DateTime.now();
    }
    return OfferHistoryItem(
      by: map['by'] ?? 'buyer',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      at: parsedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'by': by,
      'amount': amount,
      'at': Timestamp.fromDate(at),
    };
  }
}

class OfferModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final int amount; // latest amount on table
  final List<OfferHistoryItem> history;
  final String message;
  final String status; // pending | countered | accepted | declined | withdrawn
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    required this.history,
    required this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Rule: Offers older than 48 hours are shown as expired and no longer actionable
  bool get isExpired {
    if (status == 'accepted' || status == 'declined' || status == 'withdrawn') {
      return false;
    }
    final checkTime = updatedAt ?? createdAt;
    if (checkTime == null) return false;
    return DateTime.now().difference(checkTime).inHours >= 48;
  }

  String get effectiveStatus {
    if (isExpired && (status == 'pending' || status == 'countered')) {
      return 'expired';
    }
    return status;
  }

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawHistory = data['history'] as List<dynamic>? ?? [];
    return OfferModel(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'Student Buyer',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      history: rawHistory.map((h) => OfferHistoryItem.fromMap(Map<String, dynamic>.from(h))).toList(),
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'amount': amount,
      'history': history.map((e) => e.toMap()).toList(),
      'message': message,
      'status': status,
      'createdAt': isNew
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
