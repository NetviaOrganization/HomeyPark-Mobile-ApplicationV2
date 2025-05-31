class Vehicle {
  final int? id;
  final String licensePlate;
  final String model;
  final String brand;
  final int profileId;

  Vehicle({
    this.id,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.profileId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      licensePlate: json['licensePlate'],
      model: json['model'],
      brand: json['brand'],
      profileId: json['profileId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'model': model,
      'brand': brand,
      'profileId': profileId,
    };
  }
}