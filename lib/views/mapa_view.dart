import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../insLib/BotBarStyle.dart';
import '../services/gps_admin.dart';

class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final _gpsAdmin = GPSAdmin();
  final _controlador = MapController();
  static const _centroInicial = LatLng(40.4168, -3.7038);
  Position? _posicion;
  bool _buscando = false;
  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _localizar();
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _localizar() async {
    if (_buscando) return;
    setState(() {
      _buscando = true;
      _errorUbicacion = null;
    });
    try {
      final posicion = await _gpsAdmin.obtenerUbicacion();
      if (!mounted) return;
      setState(() => _posicion = posicion);
      _controlador.move(LatLng(posicion.latitude, posicion.longitude), 13);
    } on UbicacionException catch (error) {
      if (mounted) setState(() => _errorUbicacion = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _errorUbicacion = 'No se pudo obtener tu ubicación.');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      bottomNavigationBar: const Botbarstyle(iBarIndex: 1),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controlador,
            options: const MapOptions(
              initialCenter: _centroInicial,
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.proyecto1',
              ),
              MarkerLayer(
                markers: [
                  if (_posicion != null)
                    Marker(
                      point: LatLng(_posicion!.latitude, _posicion!.longitude),
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.my_location,
                        color: colores.primary,
                        semanticLabel: 'Tu ubicación',
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_buscando || _errorUbicacion != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _buscando
                            ? Icons.location_searching
                            : Icons.location_off,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buscando
                              ? 'Buscando tu ubicación…'
                              : _errorUbicacion!,
                        ),
                      ),
                      if (!_buscando)
                        TextButton(
                          onPressed: _localizar,
                          child: const Text('Reintentar'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 44,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'mapa_mas',
                  tooltip: 'Acercar',
                  onPressed: () => _controlador.move(
                    _controlador.camera.center,
                    _controlador.camera.zoom + 1,
                  ),
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton.small(
                  heroTag: 'mapa_menos',
                  tooltip: 'Alejar',
                  onPressed: () => _controlador.move(
                    _controlador.camera.center,
                    _controlador.camera.zoom - 1,
                  ),
                  child: const Icon(Icons.remove),
                ),
                FloatingActionButton(
                  heroTag: 'mapa_ubicacion',
                  tooltip: 'Centrar en mi ubicación',
                  onPressed: _buscando ? null : _localizar,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
