import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:homeypark_mobile_application/model/vehicle.dart';
import 'package:homeypark_mobile_application/services/base_service.dart';

class VehicleService extends BaseService {
  static final String baseUrl = "${BaseService.baseUrl}/vehicles";

  static Future<Vehicle?> getVehicleById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        dynamic body = jsonDecode(response.body);
        return Vehicle.fromJson(body);
      } else {
        debugPrint("Error obteniendo vehículo: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Excepción obteniendo vehículo: $e");
      return null;
    }
  }

  static Future<List<Vehicle>> getVehiclesByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Vehicle.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error obteniendo vehículos del usuario: $e");
    }
    return [];
  }
}