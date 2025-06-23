import 'package:uuid/uuid.dart';

class Product {
  String id;
  String name;
  String category;
  double price;
  int stock;

  Product({
    String? id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
  }) : this.id = id ?? const Uuid().v4();

  // Opcional: Un método para facilitar la creación de una copia con cambios (útil para actualizar el stock)
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  // Métodos para la persistencia con sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: map['price'] as double,
      stock: map['stock'] as int,
    );
  }
}
