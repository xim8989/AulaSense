import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';

import 'zones_screen.dart';
import 'charts_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import '../services/profile_settings.dart';
import '../widgets/aula_components.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // COLORES DE AULASENSE
  // =====================================

  static const Color fondo = AulaStyle.background;
  static const Color tarjeta = AulaStyle.card;
  static const Color morado = AulaStyle.purple;
  static const Color moradoClaro = AulaStyle.lightPurple;

  // SERVICIO Y MEDICIONES
  final SensorService _sensorService = SensorService();
  final Map<String, SensorReading> _mediciones = {};

  Timer? _temporizador;

  bool _cargando = true;
  bool _actualizando = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    ProfileSettings.instance.addListener(_preferenciasActualizadas);
    _actualizarMediciones();

    _temporizador = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _actualizarMediciones(),
    );
  }

  @override
  void dispose() {
    ProfileSettings.instance.removeListener(_preferenciasActualizadas);
    _temporizador?.cancel();
    super.dispose();
  }

  // CONSULTAR MEDICIONES DEL BACKEND
  // =====================================

  void _preferenciasActualizadas() {
    if (mounted) setState(() {});
  }

  final Set<String> _avisosActivos = {};

  void _comprobarAvisos() {
    final s = ProfileSettings.instance;
    final activos = <String>{};
    final mensajes = <String>[];
    for (final codigo in s.favorites) {
      final lectura = _mediciones[codigo];
      if (lectura == null) continue;
      final mediciones = [
        (
          'temperatura',
          s.temperatureAlerts,
          lectura.temperatura,
          s.minTemperature,
          s.maxTemperature,
        ),
        (
          'humedad',
          s.humidityAlerts,
          lectura.humedad,
          s.minHumidity,
          s.maxHumidity,
        ),
        (
          'iluminación',
          s.lightAlerts,
          lectura.iluminacion,
          s.minLight,
          s.maxLight,
        ),
      ];
      for (final (nombre, habilitado, valor, minimo, maximo) in mediciones) {
        if (habilitado && (valor < minimo || valor > maximo)) {
          final clave = '$codigo:$nombre';
          activos.add(clave);
          if (!_avisosActivos.contains(clave)) {
            mensajes.add(
              '${ProfileSettings.zones[codigo]}: $nombre fuera de rango',
            );
          }
        }
      }
    }
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _avisosActivos
      ..clear()
      ..addAll(activos);
    if (mensajes.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajes.join('\n'))));
    }
  }

  Future<void> _actualizarMediciones() async {
    if (_actualizando) return;

    _actualizando = true;

    try {
      final resultados = await Future.wait([
        _sensorService.obtenerMedicion('C'),
        _sensorService.obtenerMedicion('S1'),
        _sensorService.obtenerMedicion('S2'),
      ]);

      if (!mounted) return;

      setState(() {
        _mediciones['C'] = resultados[0];
        _mediciones['S1'] = resultados[1];
        _mediciones['S2'] = resultados[2];

        _error = null;
        _cargando = false;
      });
      _comprobarAvisos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo establecer conexión con el backend.';
        _cargando = false;
      });

      debugPrint('Error al actualizar Dashboard: $e');
    } finally {
      _actualizando = false;
    }
  }

  // FORMATEAR MEDICIONES
  String _temperatura(String codigo) {
    final lectura = _mediciones[codigo];

    if (lectura == null) return '-- °C';

    return '${lectura.temperatura.toStringAsFixed(1)} °C';
  }

  String _humedad(String codigo) {
    final lectura = _mediciones[codigo];

    if (lectura == null) return '-- %';

    return '${lectura.humedad.toStringAsFixed(0)} %';
  }

  String _iluminacion(String codigo) {
    final lectura = _mediciones[codigo];

    if (lectura == null) return '--';

    return lectura.iluminacion.toStringAsFixed(0);
  }

  // NAVEGACIÓN
  void _abrirZonas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ZonesScreen()),
    );
  }

  void _abrirGraficas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChartsScreen()),
    );
  }

  void _abrirAnalisisIA() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIAnalysisScreen()),
    );
  }

  // CENTRO DE ALERTAS AMBIENTALES
  void _abrirAlertas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertsScreen(),
      ),
    );
  }

  void _navegar(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        _abrirZonas();
        break;
      case 2:
        _abrirGraficas();
        break;
      case 3:
        _abrirAnalisisIA();
        break;
    }
  }

  // PANTALLA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      // ENCABEZADO
      // =====================================
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Row(
          children: [
            Icon(Icons.cloud_outlined, color: moradoClaro),
            SizedBox(width: 10),
            Text(
              'AulaSense',
              style: TextStyle(fontWeight: FontWeight.bold, color: moradoClaro),
            ),
          ],
        ),

        actions: [
          // CAMPANITA DE ALERTAS
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: moradoClaro,
            ),
            tooltip: 'Centro de alertas ambientales',
            onPressed: _abrirAlertas,
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mediciones',
            onPressed: _actualizarMediciones,
          ),

          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      // CONTENIDO PRINCIPAL
      // =====================================
      body: RefreshIndicator(
        onRefresh: _actualizarMediciones,
        color: morado,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Monitoreo ambiental',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Resumen general',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Condiciones ambientales del salón de clases',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),

                  const SizedBox(height: 25),

                  _estadoConexion(),

                  const SizedBox(height: 25),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: moradoClaro),
                      ),
                    ),

                  // TARJETAS DE LAS TRES ZONAS
                  // =====================================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double ancho = constraints.maxWidth;

                      final int columnas = ancho >= 850
                          ? 3
                          : ancho >= 550
                          ? 2
                          : 1;

                      final double anchoTarjeta =
                          (ancho - (columnas - 1) * 16) / columnas;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,

                        children: [
                          for (final codigo in _ordenZonas())
                            _tarjetaZona(
                              ancho: anchoTarjeta,
                              zona: ProfileSettings.zones[codigo]!,
                              codigo: codigo,
                              color: codigo == 'C'
                                  ? Colors.greenAccent
                                  : codigo == 'S1'
                                  ? Colors.purpleAccent
                                  : Colors.orangeAccent,
                              icono: codigo == 'C'
                                  ? Icons.home_outlined
                                  : Icons.sensors,
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // AVISO INFORMATIVO
                  // =====================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: morado.withAlpha(102)),
                    ),

                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: moradoClaro, size: 26),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'AulaSense consulta las mediciones '
                            'mediante el backend Node.js. '
                            'Actualmente utilizamos datos de prueba. '
                            'Las mediciones reales estarán disponibles '
                            'cuando conectemos el Particle Photon.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BOTÓN VER TODAS LAS ZONAS
                  // =====================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton.icon(
                      onPressed: _abrirZonas,

                      icon: const Icon(Icons.location_on_outlined),

                      label: const Text(
                        'Ver todas las zonas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: morado,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // BOTÓN CENTRO DE ALERTAS
                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: OutlinedButton.icon(
                      onPressed: _abrirAlertas,

                      icon: const Icon(
                        Icons.notifications_active_outlined,
                      ),

                      label: const Text(
                        'Centro de alertas ambientales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: moradoClaro,
                        side: const BorderSide(
                          color: morado,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),

      // BARRA DE NAVEGACIÓN INFERIOR
      // =====================================
      bottomNavigationBar: AulaNavigation(currentIndex: 0, onTap: _navegar),
    );
  }

  // ESTADO DE CONEXIÓN
  // =====================================

  List<String> _ordenZonas() {
    final primera = ProfileSettings.instance.firstZone;
    return [
      ?primera,
      ...['C', 'S1', 'S2'].where((codigo) => codigo != primera),
    ];
  }

  Widget _estadoConexion() {
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withAlpha(100)),
        ),

        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'No se pudo conectar con el backend. '
                'Se conservarán las últimas mediciones disponibles.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.cloud_done_outlined,
          color: Colors.greenAccent,
          size: 20,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            _cargando
                ? 'Consultando mediciones...'
                : 'Consulta mediante API REST · '
                      'Actualización cada 30 segundos',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // TARJETAS DE LAS ZONAS
  Widget _tarjetaZona({
    required double ancho,
    required String zona,
    required String codigo,
    required Color color,
    required IconData icono,
  }) {
    final lectura = _mediciones[codigo];

    final temperatura = _temperatura(codigo);
    final humedad = _humedad(codigo);
    final iluminacion = _iluminacion(codigo);

    return Container(
      width: ancho,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: color.withAlpha(153), width: 1.5),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 26),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  zona,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.circle,
                color: lectura != null
                    ? Colors.greenAccent
                    : Colors.amberAccent,
                size: 10,
              ),

              const SizedBox(width: 6),

              Text(
                lectura != null ? 'Medición disponible' : 'Esperando medición',
                style: TextStyle(
                  color: lectura != null
                      ? Colors.greenAccent
                      : Colors.amberAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,

            children: [
              _medicion(
                Icons.thermostat,
                'Temperatura',
                temperatura,
                Colors.redAccent,
              ),

              _medicion(
                Icons.water_drop,
                'Humedad',
                humedad,
                Colors.lightBlueAccent,
              ),

              _medicion(
                Icons.wb_sunny_outlined,
                'Iluminación',
                iluminacion,
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DISEÑO DE CADA MEDICIÓN
  // =====================================

  Widget _medicion(IconData icono, String titulo, String valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icono, color: color, size: 20),

            const SizedBox(width: 5),

            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          titulo,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
