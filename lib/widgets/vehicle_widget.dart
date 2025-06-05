import 'package:flutter/material.dart';
import '../model/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Placa: ${vehicle.licensePlate}",
              style: theme.textTheme.bodyLarge
                  ?.apply(color: theme.colorScheme.onSurface),
            ),
            Text(
              "Modelo: ${vehicle.model}",
              style: theme.textTheme.bodyMedium
                  ?.apply(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              "Marca: ${vehicle.brand}",
              style: theme.textTheme.bodyMedium
                  ?.apply(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    onDelete(vehicle.id!);
                  },
                  icon: Icon(
                    Icons.delete_outlined,
                    color: theme.colorScheme.error,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(
                    "Borrar",
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    onEdit(vehicle.id!);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text("Editar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}