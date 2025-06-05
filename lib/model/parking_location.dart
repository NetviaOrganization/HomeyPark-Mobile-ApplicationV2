class ParkingLocation {
  final int? id;
  final String address;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final String numDirection;
  final String street;

  ParkingLocation({
    this.id,
    required this.address,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.numDirection,
    required this.street,
  });

  factory ParkingLocation.fromJson(Map<String, dynamic> json) {
    return ParkingLocation(
      id: json['id'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'])
          : json['latitude'],
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'])
          : json['longitude'],
      numDirection: json['numDirection'],
      street: json['street'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'district': district,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'numDirection': numDirection,
      'street': street,
    };
  }
}