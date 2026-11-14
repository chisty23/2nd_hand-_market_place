import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final int soldCount;
  final int boughtCount;
  final int ratingSum;
  final int ratingCount;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.department = '',
    this.soldCount = 0,
    this.boughtCount = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.createdAt,
  });

  double get averageRating =>
      ratingCount > 0 ? (ratingSum / ratingCount) : 0.0;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      soldCount: (data['soldCount'] as num?)?.toInt() ?? 0,
      boughtCount: (data['boughtCount'] as num?)?.toInt() ?? 0,
      ratingSum: (data['ratingSum'] as num?)?.toInt() ?? 0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'soldCount': soldCount,
      'boughtCount': boughtCount,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
