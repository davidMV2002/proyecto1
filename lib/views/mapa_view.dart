import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firebase_admin.dart';
import '../services/gps_admin.dart';
import '../services/perfil_mapa.dart';
import '../services/distancias_service.dart';
import '../insLib/BotBarStyle.dart';

class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final _firebaseAdmin = FirebaseAdmin();
  final _gpsAdmin = GPSAdmin();
  final _controlador = MapController();
  static const _centroInicial = LatLng(40.4168, -3.7038);
  late Stream<List<PerfilMapa>> _perfiles;
  Position? _posicion;
  bool _buscando = false;
  bool _guardando = false;
  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();
    _perfiles = _firebaseAdmin.observarPerfiles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _localizar());
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

  Future<void> _compartir() async {
    final posicion = _posicion;
    if (posicion == null || _guardando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir mi ubicación'),
        content: const Text(
          'Se guardará la última posición obtenida en tu perfil para que aparezca en el mapa de otros usuarios. ¿Quieres compartirla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _guardando = true);
    try {
      await _firebaseAdmin.guardarUbicacion(posicion);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ubicación compartida.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo compartir la ubicación. Comprueba tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarPerfil(PerfilMapa perfil) {
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
                perfil.nombre.isEmpty ? 'Perfil sin nombre' : perfil.nombre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (perfil.edad != null) ...[
                const SizedBox(height: 8),
                Text('Edad: ${perfil.edad}'),
              ],
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
      bottomNavigationBar: Botbarstyle(iBarIndex: 1),
      body: StreamBuilder<List<PerfilMapa>>(
        stream: _perfiles,
        builder: (context, snapshot) {
          final perfiles = snapshot.data ?? [];
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
                      for (final perfil in perfiles)
                        Marker(
                          point: LatLng(
                            perfil.ubicacion.latitude,
                            perfil.ubicacion.longitude,
                          ),
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: 'Ver perfil de ${perfil.nombre}',
                            onPressed: () => _mostrarPerfil(perfil),
                            icon: Icon(
                              Icons.location_on,
                              size: 38,
                              color: colores.error,
                            ),
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
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    if (_buscando)
                      const _Aviso(
                        icono: Icons.location_searching,
                        texto: 'Buscando tu ubicación…',
                      ),
                    if (_errorUbicacion != null)
                      _Aviso(
                        icono: Icons.location_off,
                        texto: _errorUbicacion!,
                        accion: TextButton(
                          onPressed: _localizar,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    if (snapshot.hasError)
                      _Aviso(
                        icono: Icons.cloud_off,
                        texto: 'No se pudieron cargar los perfiles.',
                        accion: TextButton(
                          onPressed: () => setState(
                            () => _perfiles = _firebaseAdmin.observarPerfiles(),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      )
                    else if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const _Aviso(
                        icono: Icons.cloud_download_outlined,
                        texto: 'Cargando perfiles…',
                      )
                    else if (perfiles.isEmpty)
                      const _Aviso(
                        icono: Icons.place_outlined,
                        texto:
                            'Todavía no hay perfiles con ubicación compartida.',
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
              Positioned(
                left: 16,
                bottom: 100,
                child: FilledButton.tonalIcon(
                  onPressed: _posicion == null
                      ? null
                      : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => _CercaDeMi(
                            posicion: _posicion!,
                            perfiles: perfiles
                                .where(
                                  (p) =>
                                      p.uid !=
                                      FirebaseAuth.instance.currentUser?.uid,
                                )
                                .toList(),
                            onSeleccion: (perfil) {
                              Navigator.pop(context);
                              _mostrarPerfil(perfil);
                            },
                          ),
                        ),
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('Cerca de mí'),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 44,
                child: FilledButton.icon(
                  onPressed: _posicion == null || _guardando
                      ? null
                      : _compartir,
                  icon: const Icon(Icons.share_location),
                  label: Text(
                    _guardando ? 'Compartiendo…' : 'Compartir ubicación',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto, this.accion});
  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icono),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
          ?accion,
        ],
      ),
    ),
  );
}

class _CercaDeMi extends StatefulWidget {
  const _CercaDeMi({
    required this.posicion,
    required this.perfiles,
    required this.onSeleccion,
  });
  final Position posicion;
  final List<PerfilMapa> perfiles;
  final ValueChanged<PerfilMapa> onSeleccion;

  @override
  State<_CercaDeMi> createState() => _CercaDeMiState();
}

class _CercaDeMiState extends State<_CercaDeMi> {
  late Future<List<PerfilDistancia>> _resultado;
  double _progreso = 0;

  @override
  void initState() {
    super.initState();
    _resultado = DistanciasService().calcular(
      latitud: widget.posicion.latitude,
      longitud: widget.posicion.longitude,
      perfiles: widget.perfiles,
      onProgress: (valor) {
        if (mounted) setState(() => _progreso = valor);
      },
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .7,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cerca de mí',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<PerfilDistancia>>(
                future: _resultado,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(
                      child: Text('No se pudieron calcular las distancias.'),
                    );
                  if (!snapshot.hasData)
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _progreso > 0 ? _progreso : null,
                          ),
                          const SizedBox(height: 12),
                          const Text('Calculando distancias…'),
                        ],
                      ),
                    );
                  final lista = snapshot.data!;
                  if (lista.isEmpty)
                    return const Center(
                      child: Text(
                        'Todavía no hay otros perfiles con ubicación compartida.',
                      ),
                    );
                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final item = lista[index];
                      final distancia = item.metros < 1000
                          ? '${item.metros.round()} m'
                          : '${(item.metros / 1000).toStringAsFixed(1)} km';
                      return ListTile(
                        leading: const Icon(Icons.person_pin_circle_outlined),
                        title: Text(item.perfil.nombre),
                        subtitle: Text('A $distancia'),
                        onTap: () => widget.onSeleccion(item.perfil),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
