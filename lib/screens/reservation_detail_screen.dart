import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/widgets/reservation_badge_status.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int id;

  const ReservationDetailScreen({super.key, required this.id});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _loading = true;

  late ReservationStatus _status;
  late DateTime _createdDate;
  late TimeOfDay _startTime;
  late DateTime _reservationDate;
  late TimeOfDay _endTime;
  late int _parkingId;
  late double _totalFare;
  late int _vehicleId;

  @override
  void initState() {
    super.initState();
    _fetchReservation();
  }

  void _fetchReservation() async {
    try {
      final reservation = await ReservationService.getReservationById(widget.id);

      setState(() {
        _loading = false;
        _status = ReservationStatus.values.firstWhere(
              (e) => e.toString() == reservation.status.toString(),
        );
        _createdDate = reservation.createdAt;
        _reservationDate = reservation.reservationDate;
        _startTime = reservation.startTime;
        _endTime = reservation.endTime;
        _parkingId = reservation.parkingId;
        _totalFare = reservation.totalFare;
        _vehicleId = reservation.vehicleId;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reservation: $e')),
      );
    }
  }

  void _cancelReservation() async {
    Navigator.pop(context, "Ok");

    try {
      await ReservationService.updateReservationStatus(
          widget.id, "CANCELLED");

      setState(() {
        _status = ReservationStatus.cancelled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling reservation: $e')),
      );
    }
  }

  void _showCancelAlertDialog() {
    final theme = Theme.of(context);

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          title:
          Text("Cancelar reserva", style: theme.textTheme.titleMedium),
          content: Text(
            "¿Estas seguro de cancelar esta reserva? Esta acción es irreversible y no se mostrara tu publicación.",
            style: theme.textTheme.bodyMedium
                ?.apply(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context, 'Close');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.tertiary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Cerrar",
                  style: TextStyle(color: theme.colorScheme.tertiary)),
            ),
            FilledButton(
                onPressed: _cancelReservation,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
                child: const Text("Cancelar")),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final day = _loading ? "" : _reservationDate.day.toString().padLeft(2, '0');
    final month = _loading ? "" : _reservationDate.month.toString().padLeft(2, '0');
    final year = _loading ? "" : _reservationDate.year.toString();
    final dateStr = _loading ? "" : "$day/$month/$year";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _loading ? null : _status);
          },
        ),
        title: Text(
          "Detalles de reserva",
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _loading
                ? Container()
                : ReservationBadgeStatus(status: _status),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder(
                  future: ParkingService.getParkingById(_parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData || snapshot.hasError) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text("Error loading parking information")),
                      );
                    }

                    final parking = snapshot.data!;
                    final latitude = parking.location.latitude;
                    final longitude = parking.location.longitude;

                    // Use a placeholder image instead of Google Maps API
                    return Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.location_on, size: 48),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
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
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
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
                    );
                  }),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Horario",
                        style: theme.textTheme.titleMedium
                            ?.apply(color: theme.colorScheme.primary)),
                    const Divider(),
                    Text("Creado:",
                        style: theme.textTheme.labelMedium
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "${_createdDate.day}/${_createdDate.month}/${_createdDate.year} ${_createdDate.hour.toString().padLeft(2, "0")}:${_createdDate.minute.toString().padLeft(2, "0")}",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 20),
                    Text("Horario de reserva:",
                        style: theme.textTheme.labelMedium
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "Desde: ${_startTime.format(context)} - $dateStr",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "Hasta: ${_endTime.format(context)} - $dateStr",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Información adicional",
                        style: theme.textTheme.titleMedium
                            ?.apply(color: theme.colorScheme.primary)),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vehicle ID: $_vehicleId",
                                style: theme.textTheme.labelMedium?.apply(
                                  color: theme.colorScheme.onSurface,
                                )),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.payment),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Fare: \$${_totalFare.toStringAsFixed(2)}",
                                style: theme.textTheme.labelMedium?.apply(
                                  color: theme.colorScheme.onSurface,
                                )),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_status == ReservationStatus.pending)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cancelar reserva",
                          style: theme.textTheme.titleMedium
                              ?.apply(color: theme.colorScheme.primary)),
                      const Divider(),
                      Text(
                        "Puedes cancelar tu reserva hasta 6 horas antes de la hora programada para recibir un reembolso completo del pago realizado.",
                        style: theme.textTheme.bodySmall?.apply(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.error),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showCancelAlertDialog,
                          child: Text(
                            "Cancelar reserva",
                            style: TextStyle(color: theme.colorScheme.error),
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}