import 'package:flutter/material.dart';
import 'reservation_status.dart';

class Reservation {
  int id;
  int hoursRegistered;
  double totalFare;
  DateTime reservationDate;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String paymentReceiptUrl;
  String paymentReceiptDeleteUrl;
  ReservationStatus status;
  int guestId;
  int hostId;
  int parkingId;
  int vehicleId;
  DateTime createdAt;
  DateTime updatedAt;

  Reservation({
    required this.id,
    required this.hoursRegistered,
    required this.totalFare,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.paymentReceiptUrl,
    required this.paymentReceiptDeleteUrl,
    required this.status,
    required this.guestId,
    required this.hostId,
    required this.parkingId,
    required this.vehicleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      hoursRegistered: json['hoursRegistered'],
      totalFare: json['totalFare'].toDouble(),
      reservationDate: DateTime.parse(json['reservationDate']),
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      paymentReceiptUrl: json['paymentReceiptUrl'],
      paymentReceiptDeleteUrl: json['paymentReceiptDeleteUrl'],
      status: statusFromJson(json['status']),
      guestId: json['guestId'],
      hostId: json['hostId'],
      parkingId: json['parkingId'],
      vehicleId: json['vehicleId'],
      createdAt: DateTime.now(), // Default value for POST
      updatedAt: DateTime.now(), // Default value for POST
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hoursRegistered': hoursRegistered,
      'totalFare': totalFare,
      'reservationDate': reservationDate.toIso8601String(),
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'paymentReceiptUrl': paymentReceiptUrl,
      'paymentReceiptDeleteUrl': paymentReceiptDeleteUrl,
      'status': status.name, // Fixed serialization
      'guestId': guestId,
      'hostId': hostId,
      'parkingId': parkingId,
      'vehicleId': vehicleId,
    };
  }
}