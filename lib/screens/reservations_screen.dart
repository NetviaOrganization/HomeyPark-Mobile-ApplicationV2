import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/screens/reservation_detail_screen.dart';
import 'package:homeypark_mobile_application/widgets/reservation_card.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  var _loading = true;
  var _reservationsList = [];
  var _incomingReservationsList = [];
  var _pastReservationsList = [];
  var _inProgressReservationList = [];

  Future onTapReservation(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReservationDetailScreen(id: id)),
    );

    _loadGuestReservations();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _loading = true;
    });
    _loadGuestReservations();
  }

  void _loadGuestReservations() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = await preferences.getUserId();
      final reservations = await ReservationService.getReservationsByGuestId(userId);

      final incomingReservations = reservations.where((reservation) =>
      reservation.status == ReservationStatus.pending ||
          reservation.status == ReservationStatus.approved).toList();

      final pastReservations = reservations.where((reservation) =>
      reservation.status == ReservationStatus.completed ||
          reservation.status == ReservationStatus.cancelled).toList();

      final inProgressReservations = reservations.where((reservation) =>
      reservation.status == ReservationStatus.inProgress).toList();

      setState(() {
        _reservationsList = reservations;
        _incomingReservationsList = incomingReservations;
        _pastReservationsList = pastReservations;
        _inProgressReservationList = inProgressReservations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reservations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Mis reservas",
            style: theme.textTheme.titleMedium,
          ),
          backgroundColor: Colors.white,
          bottom: const TabBar(tabs: [
            Tab(text: "En progreso"),
            Tab(text: "Próximas"),
            Tab(text: "Pasadas"),
          ]),
        ),
        body: TabBarView(children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._inProgressReservationList.map((reservation) {
                  return FutureBuilder(
                      future: ParkingService.getParkingById(reservation.parkingId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        return ReservationCard(
                          reservation: reservation,
                          onTapReservation: onTapReservation,
                        );
                      });
                }).toList(),
                if (_inProgressReservationList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No tienes reservas en progreso",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._incomingReservationsList.map((reservation) {
                  return FutureBuilder(
                      future: ParkingService.getParkingById(reservation.parkingId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        return ReservationCard(
                          reservation: reservation,
                          onTapReservation: onTapReservation,
                        );
                      });
                }).toList(),
                if (_incomingReservationsList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No tienes reservas próximas",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._pastReservationsList.map((reservation) {
                  return FutureBuilder(
                      future: ParkingService.getParkingById(reservation.parkingId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        return ReservationCard(
                          reservation: reservation,
                          onTapReservation: onTapReservation,
                        );
                      });
                }).toList(),
                if (_pastReservationsList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No tienes reservas pasadas",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}