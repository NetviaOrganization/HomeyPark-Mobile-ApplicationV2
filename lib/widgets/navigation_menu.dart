import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importa Provider

// Asegúrate de que los imports de tus pantallas y servicios sean correctos
import 'package:homeypark_mobile_application/services/iam_service.dart'; 
import 'package:homeypark_mobile_application/screens/screen.dart'; 
// Ya no necesitas importar SignInScreen ni preferences aquí

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

// --- Las definiciones de tus destinos no cambian ---
const guestDestinations = [
  NavigationDrawerDestination(
      icon: Icon(Icons.search), label: Text("Buscar un garage")),
  NavigationDrawerDestination(
      icon: Icon(Icons.apps), label: Text("Tus reservas"))
];
const hostDestinations = [
  NavigationDrawerDestination(
      icon: Icon(Icons.garage), label: Text("Tus garages")),
  NavigationDrawerDestination(
      icon: Icon(Icons.inbox), label: Text("Reservas entrantes")),
];

// El ítem "Cerrar sesión" sigue aquí, lo cual es perfecto.
const accountDestinations = [
  NavigationDrawerDestination(
    icon: Icon(Icons.account_circle),
    label: Text("Perfil"),
  ),
  NavigationDrawerDestination(
      icon: Icon(Icons.directions_car), label: Text("Vehículos")),
  NavigationDrawerDestination(
      icon: Icon(Icons.credit_card), label: Text("Métodos de pago")),
  NavigationDrawerDestination(
      icon: Icon(Icons.logout), label: Text("Cerrar sesión")),
];

class _NavigationMenuState extends State<NavigationMenu> {
  // El screenIndex ya no es tan crítico para el logout, pero lo mantenemos para las otras navegaciones.
  int screenIndex = 0;

  void handleScreenChanged(int selectedScreen) {
    // Es buena práctica cerrar el drawer primero en la mayoría de los casos
    Navigator.of(context).pop();

    setState(() {
      screenIndex = selectedScreen;
    });

    // Tu lógica de navegación para las otras pantallas
    switch (selectedScreen) {
      case 0: // Buscar un garage
        // Quizás navegar a una pantalla de búsqueda
        break;
      case 1: // Tus reservas
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReservationsScreen()),
        );
        break;
      // ... otros casos para las demás pantallas ...

      // --- 2. AQUÍ ESTÁ LA LÓGICA CORREGIDA PARA CERRAR SESIÓN ---
      // El índice 7 corresponde al último item de la lista combinada.
      case 7: // Cerrar sesión
        // Llama al método del servicio. Usa listen:false porque es una acción puntual.
        // El AuthWrapper se encargará de la redirección automáticamente.
        Provider.of<IAMService>(context, listen: false).signOut();
        break;

      default:
        // No hace nada si se selecciona una opción sin acción definida.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // El build no necesita cambios.
    return NavigationDrawer(
      selectedIndex: screenIndex,
      onDestinationSelected: handleScreenChanged,
      children: [
        ...guestDestinations,
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text("Renta un garaje",
              style: Theme.of(context).textTheme.titleSmall),
        ),
        ...hostDestinations,
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text("Cuenta", style: Theme.of(context).textTheme.titleSmall),
        ),
        ...accountDestinations
      ],
    );
  }
}