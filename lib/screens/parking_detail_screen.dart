import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/model/profile.dart';
import 'package:homeypark_mobile_application/screens/reservation_form_screen.dart';

class ParkingDetailScreen extends StatelessWidget {
  final int parkingId;

  const ParkingDetailScreen({super.key, required this.parkingId});

  String _getMonthName(int month) {
    const months = [
      "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    late Parking parking;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detalles del garaje",
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: FutureBuilder(
            future: ParkingService.getParkingById(parkingId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              parking = snapshot.data!;

              final latitude = parking.location.latitude;
              final longitude = parking.location.longitude;

              debugPrint("Latitude: $latitude");
              debugPrint("Longitude: $longitude");

              final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

              debugPrint("API Key: $apiKey");

              return Column(
                children: [
                  Stack(
                    children: [
                      Image.network(
                        "https://maps.googleapis.com/maps/api/streetview?size=600x400&location=$latitude,$longitude&key=$apiKey",
                        fit: BoxFit.cover,
                        height: 240,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 240,
                            width: double.infinity,
                            color: Colors.grey,
                            child: const Center(
                              child: Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${parking.location.address} ${parking.location.numDirection}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${parking.location.district}, ${parking.location.street}, ${parking.location.city}",
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.money,
                                  color: theme.primaryColor,
                                ),
                                Text(
                                  "S/ ${parking.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      theme.colorScheme.onSurfaceVariant),
                                ),
                                Text(
                                  "Precio/hora",
                                  style: theme.textTheme.labelMedium,
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.garage,
                                  color: theme.primaryColor,
                                ),
                                Text(
                                  "${parking.space} libres",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      theme.colorScheme.onSurfaceVariant),
                                ),
                                Text(
                                  "Espacios",
                                  style: theme.textTheme.labelMedium,
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Propietario",
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.start,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/1.jpg"),
                                  onBackgroundImageError: (_, __) {
                                    debugPrint('Error loading avatar');
                                  },
                                ),
                                const SizedBox(width: 16),
                                FutureBuilder<Profile?>(
                                    future: ProfileService.getProfileById(parking.profileId),
                                    builder: (context, profileSnapshot) {
                                      if (profileSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Text("Cargando datos del propietario...");
                                      }

                                      if (!profileSnapshot.hasData) {
                                        return const Text("Información del propietario no disponible");
                                      }

                                      final profile = profileSnapshot.data!;
                                      final ownerName = "${profile.firstName} ${profile.lastName}";

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ownerName,
                                            style: theme.textTheme.labelLarge,
                                          ),
                                          Text(
                                            "Se unió a HomeyPark desde ${profile.createdAt.day} ${_getMonthName(profile.createdAt.month)}, ${profile.createdAt.year}",
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      );
                                    }
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Descripción",
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.start,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              parking.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              );
            }),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(  color: Color.fromRGBO(0,0,0, 0.1,),
              blurRadius: 16,
            ),
          ],
        ),
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationFormScreen(parking: parking),
              ),
            );
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          child: const Text("Reservar"),
        ),
      ),
    );
  }
}
