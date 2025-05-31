import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/reservation.dart';
import 'base_service.dart';

class ReservationService {
  static final String url = "${BaseService.baseUrl}/reservations";

  static Future<List<Reservation>> getAllReservations() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<Reservation?> createReservation(
      Reservation newReservation, String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['reservation'] = jsonEncode(newReservation.toJson());

    final response = await request.send();

    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      return Reservation.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to create reservation');
    }
  }

  static Future<Reservation?> updateReservation(
      int id, Reservation updatedReservation) async {
    final response = await http.put(
      Uri.parse('$url/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedReservation.toJson()),
    );

    if (response.statusCode == 200) {
      return Reservation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update reservation');
    }
  }

  static Future<Reservation?> updateReservationStatus(
      int id, String status) async {
    final response = await http.put(
      Uri.parse('$url/$id/status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Reservation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update reservation status');
    }
  }

  static Future<Reservation> getReservationById(int id) async {
    final response = await http.get(Uri.parse('$url/$id'));

    if (response.statusCode == 200) {
      return Reservation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reservation');
    }
  }

  static Future<List<Reservation>> getReservationsByHostId(int hostId) async {
    final response = await http.get(Uri.parse('$url/host/$hostId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load reservations by host ID');
    }
  }

  static Future<List<Reservation>> getReservationsByGuestId(int guestId) async {
    final response = await http.get(Uri.parse('$url/guest/$guestId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load reservations by guest ID');
    }
  }

  static Future<List<Reservation>> getInProgressReservations() async {
    final response = await http.get(Uri.parse('$url/inProgress'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load in-progress reservations');
    }
  }

  static Future<List<Reservation>> getUpComingReservations() async {
    final response = await http.get(Uri.parse('$url/upComing'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load upcoming reservations');
    }
  }

  static Future<List<Reservation>> getPastReservations() async {
    final response = await http.get(Uri.parse('$url/past'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((reservation) => Reservation.fromJson(reservation)).toList();
    } else {
      throw Exception('Failed to load past reservations');
    }
  }
}