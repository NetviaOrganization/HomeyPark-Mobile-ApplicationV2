import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/model/reservation.dart';
import 'package:homeypark_mobile_application/screens/reservation_detail_screen.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/widgets/widgets.dart';

class HostReservationsScreen extends StatefulWidget {
  const HostReservationsScreen({super.key});

  @override
  State<HostReservationsScreen> createState() => _HostReservationsScreenState();
}

class _HostReservationsScreenState extends State<HostReservationsScreen> {
  var _loading = true;
  var _reservationsList = <Reservation>[];

  var _incomingReservationsList = <Reservation>[];
  var _pastReservationsList = <Reservation>[];
  var _inProgressReservationList = <Reservation>[];
  var _toAcceptReservationList = <Reservation>[];

  void onTapReservation(int id) async {
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
    final reservations = await ReservationService.getReservationsByHostId(
        await preferences.getUserId());

    final toAcceptReservations = reservations
        .where((reservation) => reservation.status == ReservationStatus.pending)
        .toList();

    final inProgressReservations = reservations
        .where(
            (reservation) => reservation.status == ReservationStatus.inProgress)
        .toList();

    final incomingReservations = reservations
        .where(
            (reservation) => reservation.status == ReservationStatus.approved)
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
              Tab(text: "Próximas"),
              Tab(text: "En progreso"),
              Tab(text: "Pasadas"),
            ],
          ),
        ),
        body: TabBarView(children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _toAcceptReservationList.length,
            itemBuilder: (context, index) {
              final reservation = _toAcceptReservationList[index];

              if (_toAcceptReservationList.isEmpty) {
                return const Center(
                  child: Text("No tienes reservas por aceptar"),
                );
              }

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const SizedBox();
                    }
                    return ReservationCard(
                      id: reservation.id,
                      status: reservation.status,
                      address: snapshot.data!.location.address,
                      number: snapshot.data!.location.numDirection,
                      hasAction: true,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ReservationService.cancelReservation(
                                  reservation.id);
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
                              await ReservationService.approveReservation(
                                  reservation.id);
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
                      date: reservation.startTime.toDateTime(),
                      startTime: TimeOfDay.fromDateTime(
                          reservation.startTime.toDateTime()),
                      endTime: TimeOfDay.fromDateTime(
                          reservation.endTime.toDateTime()),
                      onTapReservation: onTapReservation,
                    );
                  });
            },
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _incomingReservationsList.length,
            itemBuilder: (context, index) {
              final reservation = _incomingReservationsList[index];
              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const SizedBox();
                    }
                    return ReservationCard(
                      id: reservation.id,
                      status: reservation.status,
                      address: snapshot.data!.location.address,
                      number: snapshot.data!.location.numDirection,
                      date: reservation.startTime.toDateTime(),
                      startTime: TimeOfDay.fromDateTime(
                          reservation.startTime.toDateTime()),
                      endTime: TimeOfDay.fromDateTime(
                          reservation.endTime.toDateTime()),
                      onTapReservation: onTapReservation,
                      hasAction: true,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () async {
                              await ReservationService
                                  .startServiceReservation(
                                  reservation.id);
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
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _inProgressReservationList.length,
            itemBuilder: (context, index) {
              final reservation = _inProgressReservationList[index];

              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const SizedBox();
                    }
                    return ReservationCard(
                      id: reservation.id,
                      status: reservation.status,
                      address: snapshot.data!.location.address,
                      number: snapshot.data!.location.numDirection,
                      date: reservation.startTime.toDateTime(),
                      startTime: TimeOfDay.fromDateTime(
                          reservation.startTime.toDateTime()),
                      endTime: TimeOfDay.fromDateTime(
                          reservation.endTime.toDateTime()),
                      onTapReservation: onTapReservation,
                      hasAction: true,
                      actions: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () async {
                              await ReservationService
                                  .completeReservation(reservation.id);
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
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pastReservationsList.length,
            itemBuilder: (context, index) {
              final reservation = _pastReservationsList[index];
              return FutureBuilder(
                  future: ParkingService.getParkingById(
                      reservation.parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const SizedBox();
                    }
                    return ReservationCard(
                      id: reservation.id,
                      status: reservation.status,
                      address: snapshot.data!.location.address,
                      number: snapshot.data!.location.numDirection,
                      date: reservation.startTime.toDateTime(),
                      startTime: TimeOfDay.fromDateTime(
                          reservation.startTime.toDateTime()),
                      endTime: TimeOfDay.fromDateTime(
                          reservation.endTime.toDateTime()),
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