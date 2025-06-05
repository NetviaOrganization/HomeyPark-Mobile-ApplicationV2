import 'package:homeypark_mobile_application/model/reservation_status.dart';

class Reservation {
  int id;
  int hoursRegistered;
  double totalFare;
  DateTime reservationDate;
  Time startTime;
  Time endTime;
  ReservationStatus status;
  int guestId;
  int hostId;
  int parkingId;
  int vehicleId;
  String paymentReceiptUrl;
  String paymentReceiptDeleteUrl;
  DateTime createdAt;    // Campo nuevo
  DateTime updatedAt;    // Campo nuevo

  Reservation({
    required this.id,
    required this.hoursRegistered,
    required this.totalFare,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.guestId,
    required this.hostId,
    required this.parkingId,
    required this.vehicleId,
    required this.paymentReceiptUrl,
    required this.paymentReceiptDeleteUrl,
    required this.createdAt,    // Parámetro nuevo
    required this.updatedAt,    // Parámetro nuevo
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      hoursRegistered: json['hoursRegistered'],
      totalFare: json['totalFare'].toDouble(),
      reservationDate: DateTime.parse(json['reservationDate']),
      startTime: Time.fromJson(json['startTime']),
      endTime: Time.fromJson(json['endTime']),
      status: statusFromJson(json['status']),
      guestId: json['guestId'],
      hostId: json['hostId'],
      parkingId: json['parkingId'],
      vehicleId: json['vehicleId'],
      paymentReceiptUrl: json['paymentReceiptUrl'],
      paymentReceiptDeleteUrl: json['paymentReceiptDeleteUrl'],
      createdAt: DateTime.parse(json['createdAt']),    // Parseo nuevo
      updatedAt: DateTime.parse(json['updatedAt']),    // Parseo nuevo
    );
  }

  // Computed getters
  DateTime get startDateTime => startTime.toDateTime();
  DateTime get endDateTime => endTime.toDateTime();
}

// La clase Time se mantiene igual
class Time {
  int hour;
  int minute;
  int second;
  int nano;

  Time({
    required this.hour,
    required this.minute,
    required this.second,
    required this.nano,
  });

  factory Time.fromJson(dynamic json) {
    if (json is String) {
      // Formato "HH:MM:SS" del backend
      List<String> parts = json.split(':');
      return Time(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        second: int.parse(parts[2]),
        nano: 0,
      );
    } else if (json is Map<String, dynamic>) {
      // Formato objeto del backend antiguo
      return Time(
        hour: json['hour'],
        minute: json['minute'],
        second: json['second'],
        nano: json['nano'] ?? 0,
      );
    } else {
      throw ArgumentError('Formato de tiempo inválido: $json');
    }
  }

  DateTime toDateTime() {
    return DateTime(0, 1, 1, hour, minute, second, nano ~/ 1000000);
  }
}