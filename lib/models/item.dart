import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final String name;
  final double price;
  final int quantity;
  final String category;

  Item({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Item.fromMap(String id, Map<String, dynamic> map) {
    return Item(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      category: map['category'] ?? 'General',
    );
  }
}
