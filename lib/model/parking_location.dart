class ParkingLocation {
  final int? id;
  final String address;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final String numDirection;
  final String street;
  final String? day;
  final String? startTime;
  final String? endTime;

  ParkingLocation({
    this.id,
    required this.address,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.numDirection,
    required this.street,
    this.day,
    this.startTime,
    this.endTime,
  });

  factory ParkingLocation.fromJson(Map<String, dynamic> json) {
    return ParkingLocation(
      id: json['id'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      numDirection: json['numDirection'],
      street: json['street'],
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
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
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}