import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../insLib/BotBarStyle.dart';
import '../services/gps_admin.dart';
import '../services/capitales_cercanas_service.dart';
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
  Future<void>? _localizacionEnCurso;
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

  Future<void> _localizar() {
    final activa = _localizacionEnCurso;
    if (activa != null) return activa;
    final tarea = _ejecutarLocalizacion();
    _localizacionEnCurso = tarea;
    tarea.whenComplete(() => _localizacionEnCurso = null);
    return tarea;
  }

  Future<void> _ejecutarLocalizacion() async {
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
    var reintentando = false;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, actualizarDetalle) {
          final posicion = _posicion;
          final distancia = posicion == null
              ? null
              : _gpsAdmin.distanciaEnMetros(
                  latitudOrigen: posicion.latitude,
                  longitudOrigen: posicion.longitude,
                  latitudDestino: capital.ubicacion.latitude,
                  longitudDestino: capital.ubicacion.longitude,
                );
          return SafeArea(
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
                  Text(
                    capital.pais,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  if (distancia != null)
                    Text(
                      distancia < 1000
                          ? 'A ${distancia.round()} m de tu ubicación (en línea recta)'
                          : 'A ${(distancia / 1000).toStringAsFixed(1).replaceAll('.', ',')} km de tu ubicación (en línea recta)',
                    )
                  else ...[
                    Text(
                      _errorUbicacion ?? 'Necesitamos tu ubicación para calcular la distancia.',
                    ),
                    TextButton.icon(
                      onPressed: reintentando
                          ? null
                          : () async {
                              actualizarDetalle(() => reintentando = true);
                              await _localizar();
                              if (sheetContext.mounted) {
                                actualizarDetalle(() => reintentando = false);
                              }
                            },
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        reintentando
                            ? 'Buscando ubicación…'
                            : 'Reintentar ubicación',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarCercanas() async {
    final capital = await showModalBottomSheet<Capital>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ListaCapitalesCercanas(
        capitales: _capitales,
        posicionInicial: _posicion,
        obtenerPosicion: () async {
          await _localizar();
          return _posicion;
        },
        mensajeUbicacion: () => _errorUbicacion,
      ),
    );
    if (!mounted || capital == null) return;
    _mostrarCapital(capital);
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
                left: 16,
                bottom: 44,
                child: FilledButton.icon(
                  onPressed: _mostrarCercanas,
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('Cerca de mí'),
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

class _ListaCapitalesCercanas extends StatefulWidget {
  const _ListaCapitalesCercanas({
    required this.capitales,
    required this.posicionInicial,
    required this.obtenerPosicion,
    required this.mensajeUbicacion,
  });

  final Stream<List<Capital>> capitales;
  final Position? posicionInicial;
  final Future<Position?> Function() obtenerPosicion;
  final String? Function() mensajeUbicacion;

  @override
  State<_ListaCapitalesCercanas> createState() =>
      _ListaCapitalesCercanasState();
}

class _ListaCapitalesCercanasState extends State<_ListaCapitalesCercanas> {
  final _servicio = CapitalesCercanasService();
  StreamSubscription<List<Capital>>? _suscripcion;
  List<Capital>? _capitales;
  List<CapitalCercana>? _resultados;
  Position? _posicion;
  String? _error;
  bool _errorCapitales = false;
  bool _buscandoUbicacion = false;
  bool _calculando = false;
  double _progreso = 0;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _posicion = widget.posicionInicial;
    _suscripcion = widget.capitales.listen(
      (capitales) {
        if (!mounted) return;
        setState(() {
          _capitales = capitales;
          _errorCapitales = false;
        });
        _calcular();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _errorCapitales = true);
      },
    );
    if (_posicion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buscarUbicacion();
      });
    }
  }

  @override
  void dispose() {
    _revision++;
    _suscripcion?.cancel();
    super.dispose();
  }

  Future<void> _buscarUbicacion() async {
    if (_buscandoUbicacion) return;
    setState(() {
      _buscandoUbicacion = true;
      _error = null;
    });
    try {
      final posicion = await widget.obtenerPosicion();
      if (!mounted) return;
      setState(() {
        _posicion = posicion;
        if (posicion == null) {
          _error =
              widget.mensajeUbicacion() ?? 'No se pudo obtener tu ubicación.';
        }
      });
      _calcular();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo obtener tu ubicación.');
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  Future<void> _calcular() async {
    final posicion = _posicion;
    final capitales = _capitales;
    if (posicion == null || capitales == null) return;
    final revision = ++_revision;
    setState(() {
      _calculando = true;
      _resultados = null;
      _progreso = 0;
    });
    try {
      final lista = await _servicio.calcular(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        capitales: capitales,
        onProgress: (valor) {
          if (mounted && revision == _revision) {
            setState(() => _progreso = valor);
          }
        },
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _resultados = lista;
        _calculando = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _calculando = false;
        _error = 'No se pudieron calcular las distancias.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capitales cerca de mí',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Distancia en línea recta, de menor a mayor.'),
            const SizedBox(height: 16),
            Expanded(child: _contenido()),
          ],
        ),
      ),
    ),
  );

  Widget _contenido() {
    if (_errorCapitales) {
      return const Center(
        child: Text(
          'No se pudieron cargar las capitales. Cierra la lista y reinténtalo en el mapa.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_posicion == null)
              TextButton.icon(
                onPressed: _buscandoUbicacion ? null : _buscarUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Reintentar ubicación'),
              )
            else if (_capitales != null)
              TextButton(onPressed: _calcular, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_buscandoUbicacion ||
        _capitales == null ||
        _calculando ||
        _resultados == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: _calculando && _progreso > 0 ? _progreso : null,
            ),
            const SizedBox(height: 12),
            Text(
              _buscandoUbicacion
                  ? 'Buscando tu ubicación…'
                  : _calculando
                  ? 'Calculando distancias…'
                  : 'Cargando capitales…',
            ),
          ],
        ),
      );
    }
    if (_resultados!.isEmpty) {
      return const Center(child: Text('No hay capitales disponibles.'));
    }
    return ListView.separated(
      itemCount: _resultados!.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _resultados![index];
        final distancia = item.metros < 1000
            ? '${item.metros.round()} m'
            : '${(item.metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
        return ListTile(
          key: ValueKey(item.capital.id),
          leading: const Icon(Icons.location_on_outlined),
          title: Text(item.capital.nombre),
          subtitle: Text(item.capital.pais),
          trailing: Text(distancia),
          onTap: () => Navigator.pop(context, item.capital),
        );
      },
    );
  }
}
