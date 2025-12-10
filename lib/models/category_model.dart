import 'package:flutter/material.dart';

class Category {
  final int? id;
  final int userId;
  final String name;
  final String colorValue; // Store color as hex string
  final String icon; // Icon codePoint as string
  final DateTime createdAt;

  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.colorValue,
    required this.icon,
    required this.createdAt,
  });

  Color get color => Color(int.parse(colorValue));

  IconData get iconData => IconData(
        int.parse(icon),
        fontFamily: 'MaterialIcons',
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'colorValue': colorValue,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      colorValue: map['colorValue'],
      icon: map['icon'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Category copyWith({
    int? id,
    int? userId,
    String? name,
    String? colorValue,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Default categories
  static List<Category> getDefaultCategories(int userId) {
    final now = DateTime.now();
    return [
      Category(
        userId: userId,
        name: 'Work',
        colorValue: '0xFF2196F3', // Blue
        icon: '${Icons.work.codePoint}',
        createdAt: now,
      ),
      Category(
        userId: userId,
        name: 'Personal',
        colorValue: '0xFF4CAF50', // Green
        icon: '${Icons.person.codePoint}',
        createdAt: now,
      ),
      Category(
        userId: userId,
        name: 'Shopping',
        colorValue: '0xFFFF9800', // Orange
        icon: '${Icons.shopping_cart.codePoint}',
        createdAt: now,
      ),
      Category(
        userId: userId,
        name: 'Health',
        colorValue: '0xFFE91E63', // Pink
        icon: '${Icons.favorite.codePoint}',
        createdAt: now,
      ),
      Category(
        userId: userId,
        name: 'Study',
        colorValue: '0xFF9C27B0', // Purple
        icon: '${Icons.school.codePoint}',
        createdAt: now,
      ),
    ];
  }
}
