class Client {
  final String name;
  final String email;
  final String phone;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Client({
    required this.name,
    required this.email,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'],
    );
  }
}