import 'package:flutter/material.dart';
import '../model/reservation_status.dart ';
import 'reservation_badge_status.dart';
import '../model/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Function(int)? onTapReservation;
  final Function(int)? onCancel;
  final Function(int)? onAccept;
  final List<Widget>? actions;

  const ReservationCard({
    Key? key,
    required this.reservation,
    this.onTapReservation,
    this.onCancel,
    this.onAccept,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final day = reservation.reservationDate.day.toString().padLeft(2, '0');
    final month = reservation.reservationDate.month.toString().padLeft(2, '0');
    final dateStr = "$day/$month/${reservation.reservationDate.year}";

    return GestureDetector(
      onTap: () {
        onTapReservation?.call(reservation.id);
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        shadowColor: theme.colorScheme.primary.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reservation ID: #${reservation.id.toString().padLeft(7, "0")}",
                            style: theme.textTheme.bodyLarge
                                ?.apply(color: theme.colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis),
                        Text("Parking ID: ${reservation.parkingId}",
                            style: theme.textTheme.bodyMedium?.apply(
                                color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ReservationBadgeStatus(
                    status: reservation.status,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Guest ID: ${reservation.guestId}",
                  style: theme.textTheme.bodyMedium
                      ?.apply(color: theme.colorScheme.onSurface)),
              Text("Host ID: ${reservation.hostId}",
                  style: theme.textTheme.bodyMedium
                      ?.apply(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(248, 249, 250, 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text("Desde:",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 12),
                    Text(
                        "${reservation.startTime.format(context)} - $dateStr",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(248, 249, 250, 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text("Hasta:",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 12),
                    Text(
                        "${reservation.endTime.format(context)} - $dateStr",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text("Total Fare: \$${reservation.totalFare.toStringAsFixed(2)}",
                  style: theme.textTheme.bodyMedium
                      ?.apply(color: theme.colorScheme.onSurface)),
              Text("Payment Receipt URL: ${reservation.paymentReceiptUrl}",
                  style: theme.textTheme.bodySmall
                      ?.apply(color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis),
              Text("Payment Receipt Delete URL: ${reservation.paymentReceiptDeleteUrl}",
                  style: theme.textTheme.bodySmall
                      ?.apply(color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}