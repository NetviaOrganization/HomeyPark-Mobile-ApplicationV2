import 'package:flutter/material.dart';
import '../model/reservation_status.dart'; // Space removed after .dart

class ReservationBadgeStatus extends StatelessWidget {
  final ReservationStatus status;

  const ReservationBadgeStatus({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeStatusColor = switch (status) {
      ReservationStatus.cancelled => theme.colorScheme.error,
      ReservationStatus.inProgress => const Color.fromRGBO(252, 196, 25, 1),
      ReservationStatus.approved => const Color.fromRGBO(34, 139, 230, 1),
      ReservationStatus.pending => const Color.fromRGBO(133, 142, 150, 1),
      ReservationStatus.completed => theme.colorScheme.primary,
    };

    final badgeIcon = switch (status) {
      ReservationStatus.cancelled => Icons.cancel,
      ReservationStatus.inProgress => Icons.timelapse,
      ReservationStatus.approved => Icons.check_circle,
      ReservationStatus.pending => Icons.hourglass_empty,
      ReservationStatus.completed => Icons.done_all,
    };

    return Tooltip(
      message: statusText(status),
      child: Container(
        decoration: BoxDecoration(
          color: badgeStatusColor,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              statusText(status),
              style: theme.textTheme.bodySmall?.apply(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String statusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.cancelled:
        return "Cancelled";
      case ReservationStatus.inProgress:
        return "In Progress";
      case ReservationStatus.approved:
        return "Approved";
      case ReservationStatus.pending:
        return "Pending";
      case ReservationStatus.completed:
        return "Completed";
    }
  }
}