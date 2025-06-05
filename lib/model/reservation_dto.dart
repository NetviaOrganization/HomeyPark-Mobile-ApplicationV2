class ReservationDto {
  int hoursRegistered;
  double totalFare;
  String reservationDate;
  Time startTime;
  Time endTime;
  int guestId;
  int hostId;
  int parkingId;
  int vehicleId;
  String paymentReceiptUrl;
  String paymentReceiptDeleteUrl;

  ReservationDto({
    required this.hoursRegistered,
    required this.totalFare,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.guestId,
    required this.hostId,
    required this.parkingId,
    required this.vehicleId,
    required this.paymentReceiptUrl,
    required this.paymentReceiptDeleteUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'hoursRegistered': hoursRegistered,
      'totalFare': totalFare,
      'reservationDate': reservationDate,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'guestId': guestId,
      'hostId': hostId,
      'parkingId': parkingId,
      'vehicleId': vehicleId,
      'paymentReceiptUrl': paymentReceiptUrl,
      'paymentReceiptDeleteUrl': paymentReceiptDeleteUrl,
    };
  }
}

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

  factory Time.fromJson(Map<String, dynamic> json) {
    return Time(
      hour: json['hour'],
      minute: json['minute'],
      second: json['second'],
      nano: json['nano'],
    );
  }

  DateTime toDateTime() {
    return DateTime(0, 1, 1, hour, minute, second, nano ~/ 1000000);
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': second,
      'nano': nano,
    };
  }
}