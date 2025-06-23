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

  // Métodos para serialización con la base de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] is int) ? (json['price'] as int).toDouble() : json['price'] as double,
      stock: json['stock'] as int,
    );
  }
}
