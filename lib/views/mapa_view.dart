import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../insLib/BotBarStyle.dart';
import '../services/gps_admin.dart';
import '../services/capitales_service.dart';

class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final _gpsAdmin = GPSAdmin();
  final _capitalesService = CapitalesService();
  late Stream<List<Capital>> _capitales;
  final _controlador = MapController();
  static const _centroInicial = LatLng(40.4168, -3.7038);
  Position? _posicion;
  bool _buscando = false;
  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();
    _capitales = _capitalesService.observarCapitales();
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

  void _mostrarCapital(Capital capital) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capital.nombre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(capital.pais, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      bottomNavigationBar: const Botbarstyle(iBarIndex: 1),
      body: StreamBuilder<List<Capital>>(
        stream: _capitales,
        builder: (context, snapshot) {
          final capitales = snapshot.data ?? <Capital>[];
          return Stack(
            children: [
              FlutterMap(
                mapController: _controlador,
                options: const MapOptions(
                  initialCenter: _centroInicial,
                  initialZoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.proyecto1',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final capital in capitales)
                        Marker(
                          point: LatLng(
                            capital.ubicacion.latitude,
                            capital.ubicacion.longitude,
                          ),
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: 'Ver ${capital.nombre}, ${capital.pais}',
                            onPressed: () => _mostrarCapital(capital),
                            icon: Icon(
                              Icons.location_on,
                              size: 38,
                              color: colores.error,
                            ),
                          ),
                        ),
                      if (_posicion != null)
                        Marker(
                          point: LatLng(
                            _posicion!.latitude,
                            _posicion!.longitude,
                          ),
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
              if (_buscando ||
                  _errorUbicacion != null ||
                  snapshot.hasError ||
                  snapshot.connectionState == ConnectionState.waiting)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      if (_buscando || _errorUbicacion != null)
                        _AvisoMapa(
                          icono: _buscando
                              ? Icons.location_searching
                              : Icons.location_off,
                          texto: _buscando
                              ? 'Buscando tu ubicación…'
                              : _errorUbicacion!,
                          alReintentar: _buscando ? null : _localizar,
                        ),
                      if (snapshot.hasError)
                        _AvisoMapa(
                          icono: Icons.cloud_off,
                          texto: 'No se pudieron cargar las capitales.',
                          alReintentar: () => setState(() {
                            _capitales = _capitalesService.observarCapitales();
                          }),
                        )
                      else if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const _AvisoMapa(
                          icono: Icons.cloud_download_outlined,
                          texto: 'Cargando capitales…',
                        ),
                    ],
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
          );
        },
      ),
    );
  }
}

class _AvisoMapa extends StatelessWidget {
  const _AvisoMapa({
    required this.icono,
    required this.texto,
    this.alReintentar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icono),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
          if (alReintentar != null)
            TextButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    ),
  );
}
