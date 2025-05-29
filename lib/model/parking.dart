import 'package:homeypark_mobile_application/model/parking_location.dart';

class Parking {
  final int id;
  final int profileId;
  final ParkingLocation location;
  final String space;
  final double width;
  final double length;
  final double height;
  final double price;
  final String phone;
  final String description;

  Parking({
    required this.id,
    required this.profileId,
    required this.location,
    required this.space,
    required this.width,
    required this.length,
    required this.height,
    required this.price,
    required this.phone,
    required this.description,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'],
      profileId: json['profileId'],
      location: ParkingLocation(
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
      ),
      space: json['space'],
      width: json['width'],
      length: json['length'],
      height: json['height'],
      price: json['price'],
      phone: json['phone'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'location': location.toJson(),
      'space': space,
      'width': width,
      'length': length,
      'height': height,
      'price': price,
      'phone': phone,
      'description': description,
    };
  }
}