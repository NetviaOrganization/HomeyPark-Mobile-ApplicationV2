import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeypark_mobile_application/config/constants/constants.dart';
import 'package:homeypark_mobile_application/screens/parking_detail_screen.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/utils/user_location.dart';
import 'package:homeypark_mobile_application/widgets/navigation_menu.dart';
import 'package:homeypark_mobile_application/widgets/nearby_parking_sheet.dart';
import 'package:http/http.dart' as http;

// ignore: constant_identifier_names
const DEFAULT_CENTER = LatLng(DEFAULT_POSITION_MAP_LAT, DEFAULT_POSITION_MAP_LNG);

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final searchQueryFieldController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _center;
  LatLng? _userLocation; // Para guardar la ubicación del usuario
  bool _isSearchLocation = false; // Para identificar si es una ubicación buscada

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showPredictions = false;
  Timer? _debounce;
  int _updateNearbyTrigger = 0;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    searchQueryFieldController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controllerCompleter.complete(controller);
  }

  void _fetchLocation() async {
    try {
      final position = await getUserLocation();
      final userPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _center = userPos;
        _userLocation = userPos;
        _isSearchLocation = false;
      });

      final controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLng(_center!));
    } catch (e) {
      setState(() {
        _center = DEFAULT_CENTER;
        _userLocation = DEFAULT_CENTER;
        _isSearchLocation = false;
      });
    }
  }

  // Método para centrar el mapa en la ubicación del usuario
  void _centerOnUserLocation() async {
    if (_userLocation == null) {
      // Si no tenemos la ubicación del usuario, intentamos obtenerla
      _fetchLocation();
      return;
    }

    final controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 16.0));

    setState(() {
      _center = _userLocation;
      _isSearchLocation = false;
      _updateNearbyTrigger++; // Forzar actualización de estacionamientos cercanos
    });

    // Si hay texto en la barra de búsqueda, lo limpiamos para evitar confusión
    if (searchQueryFieldController.text.isNotEmpty && _isSearchLocation) {
      searchQueryFieldController.clear();
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.length < 3) {
        setState(() {
          _predictions = [];
          _showPredictions = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _showPredictions = true;
      });

      final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
              '?input=$input'
              '&components=country:pe'
              '&language=es'
              '&types=address'
              '&key=$apiKey'
      );

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final predictions = (data['predictions'] as List)
                .map((prediction) => PlacePrediction.fromJson(prediction))
                .toList();

            setState(() {
              _predictions = predictions;
              _isLoading = false;
            });
          } else {
            setState(() {
              _predictions = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _predictions = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _predictions = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=${prediction.placeId}'
            '&fields=geometry,formatted_address'
            '&key=$apiKey'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final formattedAddress = result['formatted_address'];
          final newPosition = LatLng(lat, lng);

          mapController.animateCamera(
              CameraUpdate.newLatLngZoom(newPosition, 16.0)
          );

          setState(() {
            _center = newPosition;
            _isSearchLocation = true; // Marcar como ubicación de búsqueda
            searchQueryFieldController.text = formattedAddress;
            _predictions = [];
            _showPredictions = false;
            _updateNearbyTrigger++;
          });

          _searchFocusNode.unfocus();
        }
      }
    } catch (e) {
      debugPrint('Error en la búsqueda de lugares: $e');
    }
  }

  navigateToParkingDetailScreen(int? parkingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ParkingDetailScreen(parkingId: parkingId!)),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showPredictions) {
          setState(() {
            _showPredictions = false;
          });
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
          key: _scaffoldKey,
          drawer: const NavigationMenu(),
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              FutureBuilder(
                  future: ParkingService.getParkingsLocations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // Crear conjunto de marcadores
                    Set<Marker> markers = {};

                    // Agregar marcadores de estacionamientos
                    if (snapshot.hasData) {
                      markers.addAll(snapshot.data!.map((location) => Marker(
                        markerId: MarkerId(location.id.toString()),
                        position: LatLng(location.latitude, location.longitude),
                        onTap: () => navigateToParkingDetailScreen(location.id),
                      )));
                    }

                    // Solo agregar el marcador del usuario si no estamos mostrando una ubicación buscada
                    if (!_isSearchLocation && _userLocation != null) {
                      markers.add(Marker(
                        markerId: const MarkerId('current'),
                        position: _userLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      ));
                    }

                    return GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                          target: _center ?? DEFAULT_CENTER,
                          zoom: 16.0
                      ),
                      zoomControlsEnabled: false,
                      markers: markers,
                    );
                  }
              ),

              // Botón para centrar en la ubicación del usuario
              Positioned(
                right: 15,
                bottom: 220, // Posicionado encima del panel de estacionamientos cercanos
                child: FloatingActionButton(
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Colors.white,
                  mini: true, // Tamaño más pequeño
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              Positioned(
                top: 40,
                left: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: _showPredictions
                            ? const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)
                        )
                            : BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchQueryFieldController,
                              focusNode: _searchFocusNode,
                              onChanged: _getPlacePredictions,
                              onTap: () {
                                setState(() {
                                  _showPredictions = true;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: "Buscar por nombre o dirección",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    if (_showPredictions)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10)
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: _isLoading
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : _predictions.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Escribe para buscar direcciones"),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _predictions[index];
                            return ListTile(
                              title: Text(
                                prediction.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8
                              ),
                              onTap: () {
                                _selectPlace(prediction);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              FutureBuilder(
                  key: ValueKey('parking_nearby_$_updateNearbyTrigger'),
                  future: _center == null
                      ? null
                      : ParkingService.getNearbyParkings(
                      _center!.latitude, _center!.longitude
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done || _center == null) {
                      return const SizedBox.shrink();
                    }

                    if (snapshot.hasData) {
                      return NearbyParkingSheet(
                        parkings: snapshot.data ?? [],
                        onTapParking: (parking) =>
                            navigateToParkingDetailScreen(parking.id),
                      );
                    }

                    return const SizedBox.shrink();
                  }
              )
            ],
          )
      ),
    );
  }
}