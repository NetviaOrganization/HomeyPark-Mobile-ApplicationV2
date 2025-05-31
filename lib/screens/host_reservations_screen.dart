import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/screens/reservation_detail_screen.dart';
import 'package:homeypark_mobile_application/widgets/reservation_card.dart';

class HostReservationsScreen extends StatefulWidget {
  const HostReservationsScreen({super.key});

  @override
  State<HostReservationsScreen> createState() => _HostReservationsScreenState();
}

class _HostReservationsScreenState extends State<HostReservationsScreen> {
  var _loading = true;
  var _reservationsList = [];
  var _incomingReservationsList = [];
  var _pastReservationsList = [];
  var _inProgressReservationList = [];
  var _toAcceptReservationList = [];

  Future onTapReservation(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReservationDetailScreen(id: id)),
    );

    _loadHostReservations();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _loading = true;
    });
    _loadHostReservations();
  }

  void _loadHostReservations() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = await preferences.getUserId();
      final reservations = await ReservationService.getReservationsByHostId(userId);

      final toAcceptReservations = reservations
          .where((reservation) => reservation.status == ReservationStatus.pending)
          .toList();

      final inProgressReservations = reservations
          .where((reservation) => reservation.status == ReservationStatus.inProgress)
          .toList();

      final incomingReservations = reservations
          .where((reservation) => reservation.status == ReservationStatus.approved)
          .toList();

      final pastReservations = reservations
          .where((reservation) =>
      reservation.status == ReservationStatus.completed ||
          reservation.status == ReservationStatus.cancelled)
          .toList();

      setState(() {
        _reservationsList = reservations;
        _incomingReservationsList = incomingReservations;
        _pastReservationsList = pastReservations;
        _inProgressReservationList = inProgressReservations;
        _toAcceptReservationList = toAcceptReservations;
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
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Tus reservas entrantes",
            style: theme.textTheme.titleMedium,
          ),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: "Por aceptar"),
              Tab(text: "En progreso"),
              Tab(text: "Próximas"),
              Tab(text: "Pasadas"),
            ],
          ),
        ),
        body: TabBarView(children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _toAcceptReservationList.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                "No tienes reservas por aceptar",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _toAcceptReservationList.length,
            itemBuilder: (context, index) {
              final reservation = _toAcceptReservationList[index];

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    return ReservationCard(
                      reservation: reservation,
                      onTapReservation: onTapReservation,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ReservationService.updateReservationStatus(
                                  reservation.id, "CANCELLED");
                              _loadHostReservations();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: theme.colorScheme.error),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Rechazar",
                                style: TextStyle(
                                    color: theme.colorScheme.error)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await ReservationService.updateReservationStatus(
                                  reservation.id, "APPROVED");
                              _loadHostReservations();
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Aceptar"),
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _inProgressReservationList.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                "No tienes reservas en progreso",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _inProgressReservationList.length,
            itemBuilder: (context, index) {
              final reservation = _inProgressReservationList[index];

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    return ReservationCard(
                      reservation: reservation,
                      onTapReservation: onTapReservation,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () async {
                              await ReservationService.updateReservationStatus(
                                  reservation.id, "COMPLETED");
                              _loadHostReservations();
                            },
                            child: const Text("Finalizar servicio"),
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _incomingReservationsList.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                "No tienes reservas próximas",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _incomingReservationsList.length,
            itemBuilder: (context, index) {
              final reservation = _incomingReservationsList[index];

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    return ReservationCard(
                      reservation: reservation,
                      onTapReservation: onTapReservation,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () async {
                              await ReservationService.updateReservationStatus(
                                  reservation.id, "IN_PROGRESS");
                              _loadHostReservations();
                            },
                            child: const Text("Empezar servicio"),
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _pastReservationsList.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                "No tienes reservas pasadas",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pastReservationsList.length,
            itemBuilder: (context, index) {
              final reservation = _pastReservationsList[index];

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    return ReservationCard(
                      reservation: reservation,
                      onTapReservation: onTapReservation,
                    );
                  });
            },
          ),
        ]),
      ),
    );
  }
}