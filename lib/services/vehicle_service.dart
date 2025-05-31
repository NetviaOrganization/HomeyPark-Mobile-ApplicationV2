import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/vehicle.dart';
import 'base_service.dart';

class VehicleService {
  static final String url = "${BaseService.baseUrl}/vehicles";

  static Future<Vehicle> getVehicleById(int id) async {
    final response = await http.get(Uri.parse('$url/$id'));

    if (response.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }

  static Future<List<Vehicle>> getVehiclesByUserId(int userId) async {
    final response = await http.get(Uri.parse('$url/user/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  static Future<List<Vehicle>> getAllVehicles() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } else {
      throw Exception('Failed to load all vehicles');
    }
  }

  static Future<Vehicle?> createVehicle(Vehicle newVehicle) async {
    final response = await http.post(
      Uri.parse('$url/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(newVehicle.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Vehicle.fromJson(data);
    } else {
      throw Exception('Failed to create vehicle');
    }
  }

  static Future<Vehicle?> updateVehicle(Vehicle updatedVehicle) async {
    final response = await http.put(
      Uri.parse('$url/update/${updatedVehicle.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedVehicle.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Vehicle.fromJson(data);
    } else {
      throw Exception('Failed to update vehicle');
    }
  }

  static Future<void> deleteVehicle(int id) async {
    final response = await http.delete(Uri.parse('$url/delete/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete vehicle');
    }
  }
}