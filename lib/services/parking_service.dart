import 'dart:convert';
import 'package:flutter/material.dart'; // Para usar debugPrint

import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/model/parking_location.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:http/http.dart' as http;

class ParkingService extends BaseService {
  static final String baseUrl = "${BaseService.baseUrl}/parking";

  static Future<List<Parking>> getParkings() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);

      List<Parking> parkings =
          body.map((dynamic item) => Parking.fromJson(item)).toList();

      return parkings;
    } else {
      return [];
    }
  }

  static Future<List<Parking>> getNearbyParkings(double lat, double lng) async {
    final response =
        await http.get(Uri.parse("$baseUrl/nearby?lat=$lat&lng=$lng"));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);

      List<Parking> parkings =
          body.map((dynamic item) => Parking.fromJson(item)).toList();

      return parkings;
    } else {
      return [];
    }
  }

  static Future<List<ParkingLocation>> getParkingsLocations() async {
    debugPrint('⚡️ ParkingService: Llamando a getParkingsLocations()');

    try {
      final parkings = await getParkings();
      debugPrint('⚡️ Parkings obtenidos: ${parkings.length}');

      if (parkings.isEmpty) {
        debugPrint('⚠️ No se encontraron parkings');
        return [];
      }

      try {
        List<ParkingLocation> locations = [];
        for (var parking in parkings) {
          debugPrint('⚡️ Procesando parking ID: ${parking.id}');
          if (parking.location != null) {
            locations.add(parking.location);
          } else {
            debugPrint('❌ Parking sin ubicación: ${parking.id}');
          }
        }

        debugPrint('✅ Ubicaciones extraídas: ${locations.length}');
        return locations;
      } catch (e) {
        debugPrint('❌ Error al procesar ubicaciones: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Excepción en getParkingsLocations: $e');
      return [];
    }
  }
  static Future<List<Parking>> getParkingListByUserId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/profile/$id'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      var parkings =
          body.map((dynamic item) => Parking.fromJson(item)).toList();

      return parkings;
    } else {
      return [];
    }
  }

  static Future<Parking> getParkingById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id/details'));

    if (response.statusCode == 200) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load parking');
    }
  }

  static Future<Parking> createParking({
    required int profileId,
    required double width,
    required double length,
    required double height,
    required double price,
    String phone = '',
    required int space,
    required String description,
    required String address,
    required String numDirection,
    required String street,
    required String district,
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'profileId': profileId, // Incluido en el cuerpo
          'width': width,
          'length': length,
          'height': height,
          'price': price,
          'phone': phone,
          'space': space,
          'description': description,
          'address': address,
          'numDirection': numDirection,
          'street': street,
          'district': district,
          'city': city,
          'latitude': latitude,
          'longitude': longitude,
        }));

    if (response.statusCode == 201) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create parking: ${response.body}');
    }
  }

  static Future<Parking> updateParking(int id, dynamic parking) async {
    final response = await http.put(Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(parking));

    if (response.statusCode == 200) {
      return Parking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update parking');
    }
  }

  static Future<void> deleteParking(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete parking');
    }
  }
}
