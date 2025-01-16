class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime startDate;
  final DateTime endDate;
  bool isActive;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}