import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final List<String> keywords;
  final String description;
  final String category;
  final String condition; // new | like-new | used | worn
  final int price; // integer in BDT/cents
  final bool negotiable;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  final String status; // available | reserved | sold
  final String? reservedFor; // buyerId
  final DateTime? createdAt;

  ListingModel({
    required this.id,
    required this.title,
    required this.keywords,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.negotiable,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    this.reservedFor,
    this.createdAt,
  });

  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isSold => status == 'sold';

  static List<String> generateKeywords(String title) {
    final clean = title.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    // Also include prefix or sub-elements if appropriate, words are primary
    return words.toSet().toList();
  }

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ListingModel(
      id: doc.id,
      title: data['title'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      condition: data['condition'] ?? 'used',
      price: (data['price'] as num?)?.toInt() ?? 0,
      negotiable: data['negotiable'] ?? false,
      imageUrl: data['imageUrl'] as String?,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      status: data['status'] ?? 'available',
      reservedFor: data['reservedFor'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'title': title,
      'keywords': keywords,
      'description': description,
      'category': category,
      'condition': condition,
      'price': price,
      'negotiable': negotiable,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'status': status,
      'reservedFor': reservedFor,
      'createdAt': isNew
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()),
    };
  }
}
