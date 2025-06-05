import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:homeypark_mobile_application/services/base_service.dart';
import 'package:homeypark_mobile_application/model/profile.dart';

class ProfileService extends BaseService {
  static final String baseUrl = "${BaseService.baseUrl}/profiles";

  static Future<List<Profile>> getAllProfiles() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Profile> profiles = body.map((item) => Profile.fromJson(item)).toList();
      return profiles;
    } else {
      return [];
    }
  }

  static Future<Profile?> getProfileById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Error al obtener el perfil: ${response.body}');
    }
  }

  static Future<Profile> createProfile({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'userId': userId,
      }),
    );

    if (response.statusCode == 201) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear el perfil: ${response.body}');
    }
  }

  static Future<Profile> updateProfile(int id, {
    String? firstName,
    String? lastName,
    DateTime? birthDate,
  }) async {
    Map<String, dynamic> updateData = {};
    if (firstName != null) updateData['firstName'] = firstName;
    if (lastName != null) updateData['lastName'] = lastName;
    if (birthDate != null) updateData['birthDate'] = birthDate.toIso8601String().split('T')[0];

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Perfil no encontrado');
    } else {
      throw Exception('Error al actualizar el perfil: ${response.body}');
    }
  }

  static Future<void> deleteProfile(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete/$id'));

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar el perfil');
    }
  }
}