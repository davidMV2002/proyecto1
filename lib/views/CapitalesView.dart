import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../insLib/BotBarStyle.dart';
import '../services/consultas_capitales_service.dart';

enum _Consulta { filtros, poblacion, fechas, todas }

class CapitalesView extends StatefulWidget {
  const CapitalesView({super.key});

  @override
  State<CapitalesView> createState() => _CapitalesViewState();
}

class _CapitalesViewState extends State<CapitalesView> {
  final _servicio = ConsultasCapitalesService();
  final _poblacion = TextEditingController(text: '500000');
  final _formulario = GlobalKey<FormState>();
  static const _tamanoPagina = 10;
  _Consulta _consulta = _Consulta.filtros;
  String _zona = 'Sur';
  DateTimeRange? _rango;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _resultados = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMas = false;
  String? _error;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void dispose() {
    _revision++;
    _poblacion.dispose();
    super.dispose();
  }

  Future<void> _consultar({bool siguiente = false}) async {
    if (siguiente &&
        (_cargando || _cargandoMas || !_hayMas || _resultados.isEmpty)) {
      return;
    }
    final consulta = _consulta;
    final poblacion = int.tryParse(_poblacion.text.trim());
    if (consulta == _Consulta.filtros && (poblacion == null || poblacion < 0)) {
      _formulario.currentState?.validate();
      return;
    }
    if (consulta == _Consulta.fechas && _rango == null) return;
    final revision = ++_revision;
    final ultimo = siguiente ? _resultados.last : null;
    setState(() {
      _error = null;
      _cargando = !siguiente;
      _cargandoMas = siguiente;
      if (!siguiente) {
        _resultados = [];
        _hayMas = false;
      }
    });
    try {
      final QuerySnapshot<Map<String, dynamic>> respuesta;
      switch (consulta) {
        case _Consulta.filtros:
          respuesta = await _servicio.filtrarZonaPoblacion(
            zona: _zona,
            poblacionMinima: poblacion!,
          );
        case _Consulta.poblacion:
          respuesta = await _servicio.masPobladas(limite: 10);
        case _Consulta.fechas:
          respuesta = await _servicio.porFechas(
            desde: _rango!.start,
            hasta: _rango!.end,
          );
        case _Consulta.todas:
          respuesta = await _servicio.pagina(
            despues: ultimo,
            limite: _tamanoPagina,
          );
      }
      if (!mounted || revision != _revision) return;
      setState(() {
        if (siguiente) {
          final existentes = _resultados
              .map((documento) => documento.id)
              .toSet();
          _resultados = [
            ..._resultados,
            ...respuesta.docs.where(
              (documento) => !existentes.contains(documento.id),
            ),
          ];
        } else {
          _resultados = respuesta.docs;
        }
        _hayMas =
            consulta == _Consulta.todas &&
            respuesta.docs.length == _tamanoPagina;
        _cargando = false;
        _cargandoMas = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _error = 'No se pudieron cargar las capitales. Comprueba tu conexión e inténtalo de nuevo.';
        _cargando = false;
        _cargandoMas = false;
      });
    }
  }

  void _elegirConsulta(_Consulta? consulta) {
    if (consulta == null || consulta == _consulta) return;
    setState(() {
      _consulta = consulta;
      _error = null;
      if (consulta == _Consulta.fechas && _rango == null) {
        final hoy = DateTime.now();
        _rango = DateTimeRange(
          start: DateTime(hoy.year - 1, hoy.month, hoy.day),
          end: DateTime(hoy.year, hoy.month, hoy.day),
        );
      }
    });
    _consultar();
  }

  Future<void> _elegirFechas() async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year + 1),
      initialDateRange: _rango,
      helpText: 'Selecciona las fechas de incorporación',
    );
    if (!mounted || rango == null) return;
    setState(() => _rango = rango);
    _consultar();
  }

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  void _mostrarDetalle(QueryDocumentSnapshot<Map<String, dynamic>> documento) {
    final datos = documento.data();
    final nombre = datos['nombre'];
    final pais = datos['pais'];
    final zona = datos['zona'];
    final poblacion = datos['poblacion'];
    final anio = datos['anioPoblacion'];
    final fuente = datos['fuentePoblacion'];
    final fecha = datos['fechaAnadida'];
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
                nombre is String ? nombre : 'Capital',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(pais is String ? pais : 'País no disponible'),
              if (zona is String) ...[
                const SizedBox(height: 8),
                Text('Zona: $zona'),
              ],
              if (poblacion is num) ...[
                const SizedBox(height: 8),
                Text(
                  'Población registrada: ${_formatearNumero(poblacion.toInt())} habitantes${anio is num ? ' (${anio.toInt()})' : ''}',
                ),
              ],
              if (fuente is String && fuente.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Fuente: $fuente'),
              ],
              if (fecha is Timestamp) ...[
                const SizedBox(height: 8),
                Text('Añadida el ${_fecha(fecha.toDate())}'),
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

  String _formatearNumero(int numero) {
    final digitos = numero.toString();
    final salida = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) salida.write('.');
      salida.write(digitos[i]);
    }
    return salida.toString();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Capitales')),
    bottomNavigationBar: const Botbarstyle(iBarIndex: 2),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Explora las capitales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige una consulta para filtrar y ordenar las capitales.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _opcion(_Consulta.filtros, 'Zona y población'),
                  _opcion(_Consulta.poblacion, 'Más pobladas'),
                  _opcion(_Consulta.fechas, 'Por fechas'),
                  _opcion(_Consulta.todas, 'Todas'),
                ],
              ),
              const SizedBox(height: 20),
              if (_consulta == _Consulta.filtros) _filtros(),
              if (_consulta == _Consulta.poblacion)
                const Text('Las 10 capitales con mayor población registrada.'),
              if (_consulta == _Consulta.fechas) _filtroFechas(),
              if (_consulta == _Consulta.todas)
                const Text('Capitales por orden alfabético.'),
              const SizedBox(height: 16),
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _resultados.isEmpty)
                _mensajeError()
              else if (_resultados.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No hay capitales que coincidan con la consulta.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                Text(
                  '${_resultados.length} ${_resultados.length == 1 ? 'resultado' : 'resultados'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final documento in _resultados) _capital(documento),
                if (_error != null) _mensajeError(),
                if (_consulta == _Consulta.todas && _hayMas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: OutlinedButton(
                      onPressed: _cargandoMas
                          ? null
                          : () => _consultar(siguiente: true),
                      child: _cargandoMas
                          ? const Text('Cargando…')
                          : const Text('Cargar más'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _opcion(_Consulta valor, String texto) => ChoiceChip(
    label: Text(texto),
    selected: _consulta == valor,
    onSelected: (_) => _elegirConsulta(valor),
  );

  Widget _filtros() => Form(
    key: _formulario,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _zona,
          decoration: const InputDecoration(
            labelText: 'Zona de Europa',
            border: OutlineInputBorder(),
          ),
          items: const ['Norte', 'Sur', 'Este', 'Oeste', 'Centro']
              .map((zona) => DropdownMenuItem(value: zona, child: Text(zona)))
              .toList(),
          onChanged: (zona) {
            if (zona != null) setState(() => _zona = zona);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _poblacion,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Población mínima',
            suffixText: 'habitantes',
            border: OutlineInputBorder(),
          ),
          validator: (valor) => int.tryParse(valor ?? '') == null
              ? 'Introduce una población válida.'
              : null,
          onFieldSubmitted: (_) {
            if (_formulario.currentState!.validate()) _consultar();
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _cargando
              ? null
              : () {
                  if (_formulario.currentState!.validate()) _consultar();
                },
          icon: const Icon(Icons.search),
          label: const Text('Buscar capitales'),
        ),
      ],
    ),
  );

  Widget _filtroFechas() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Fecha de incorporación a la aplicación'),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _elegirFechas,
        icon: const Icon(Icons.date_range),
        label: Text(
          _rango == null
              ? 'Elegir fechas'
              : '${_fecha(_rango!.start)} – ${_fecha(_rango!.end)}',
        ),
      ),
    ],
  );

  Widget _mensajeError() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(
          onPressed: () => _consultar(
            siguiente: _consulta == _Consulta.todas && _resultados.isNotEmpty,
          ),
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );

  Widget _capital(QueryDocumentSnapshot<Map<String, dynamic>> documento) {
    final datos = documento.data();
    final nombre = datos['nombre'];
    final pais = datos['pais'];
    final poblacion = datos['poblacion'];
    return Card(
      child: ListTile(
        title: Text(
          nombre is String && nombre.isNotEmpty ? nombre : 'Capital sin nombre',
        ),
        subtitle: Text(pais is String ? pais : 'País no disponible'),
        trailing: poblacion is num
            ? Text(
                _formatearNumero(poblacion.toInt()),
                textAlign: TextAlign.end,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _mostrarDetalle(documento),
      ),
    );
  }
}
