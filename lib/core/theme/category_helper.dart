import 'package:flutter/material.dart';

class CategoryHelper {
  static const List<String> categories = [
    'All',
    'Books',
    'Electronics',
    'Bikes & Cycles',
    'Fashion',
    'Stationery',
    'Furniture',
    'Other',
  ];

  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'books':
        return Icons.menu_book_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'bikes & cycles':
      case 'bikes':
        return Icons.pedal_bike_rounded;
      case 'fashion':
        return Icons.checkroom_rounded;
      case 'stationery':
        return Icons.edit_note_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'books':
        return const Color(0xFF3B82F6); // Blue
      case 'electronics':
        return const Color(0xFF8B5CF6); // Purple
      case 'bikes & cycles':
      case 'bikes':
        return const Color(0xFF10B981); // Emerald
      case 'fashion':
        return const Color(0xFFEC4899); // Pink
      case 'stationery':
        return const Color(0xFFF59E0B); // Amber
      case 'furniture':
        return const Color(0xFF6366F1); // Indigo
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
