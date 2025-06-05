class Vehicle {
  final int id;
  final String licensePlate;
  final String model;
  final String brand;
  final String profileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.profileId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      licensePlate: json['licensePlate'],
      model: json['model'],
      brand: json['brand'],
      profileId: json['profileId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}