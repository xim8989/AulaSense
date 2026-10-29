import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';
import 'zone_detail_screen.dart';
import 'classroom_map_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  // COLORES DE AULASENSE
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFF9333EA);
  static const Color moradoClaro = Color(0xFFB366FF);

  final SensorService _sensorService = SensorService();

  final Map<String, SensorReading> _mediciones = {};

  Timer? _temporizador;

  bool _cargando = true;
  bool _actualizando = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Primera consulta al abrir la pantalla.
    _actualizarMediciones();

    // Consultar nuevamente cada 30 segundos.
    _temporizador = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _actualizarMediciones(),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  // ==========================================
  // CONSULTAR LAS TRES ZONAS EN EL BACKEND
  // ==========================================

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron actualizar las mediciones.';
        _cargando = false;
      });

      debugPrint('Error consultando las zonas: $e');
    } finally {
      _actualizando = false;
    }
  }

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

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Zonas de monitoreo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar mediciones',
            onPressed: _actualizarMediciones,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _actualizarMediciones,
        color: morado,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis zonas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Consulta las condiciones ambientales '
                    'de cada zona del salón.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ESTADO DE LA CONEXIÓN
                  _avisoEstado(),

                  const SizedBox(height: 25),

                  // =====================================
                  // MAPA INTERACTIVO
                  // =====================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: moradoClaro.withAlpha(102),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: moradoClaro,
                              size: 30,
                            ),

                            SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                'Mapa interactivo del salón',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Visualiza la distribución de los sensores, '
                          'selecciona una zona y arrastra los sensores '
                          'para cambiar su posición en el mapa.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,

                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ClassroomMapScreen(),
                                ),
                              );
                            },

                            icon: const Icon(Icons.map_outlined),

                            label: const Text(
                              'Ver mapa interactivo',
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Zonas disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          color: moradoClaro,
                        ),
                      ),
                    ),

                  // ZONA CENTRAL
                  _tarjetaZona(
                    nombre: 'Zona Central',
                    codigo: 'C',
                    icono: Icons.home_outlined,
                    color: Colors.greenAccent,
                  ),

                  const SizedBox(height: 20),

                  // ZONA S1
                  _tarjetaZona(
                    nombre: 'Zona S1',
                    codigo: 'S1',
                    icono: Icons.sensors,
                    color: moradoClaro,
                  ),

                  const SizedBox(height: 20),

                  // ZONA S2
                  _tarjetaZona(
                    nombre: 'Zona S2',
                    codigo: 'S2',
                    icono: Icons.sensors,
                    color: Colors.orangeAccent,
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: TextButton.icon(
                      onPressed: _actualizarMediciones,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar mediciones'),
                      style: TextButton.styleFrom(
                        foregroundColor: moradoClaro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // AVISO DEL ESTADO DE MONITOREO
  // ==========================================

  Widget _avisoEstado() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent.withAlpha(100),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No hay conexión con el backend. '
                'Se conservan las últimas mediciones disponibles.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(
          SensorService.modoDemostracion
              ? Icons.info_outline
              : Icons.cloud_done_outlined,
          color: SensorService.modoDemostracion
              ? Colors.amberAccent
              : Colors.greenAccent,
          size: 18,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            SensorService.modoDemostracion
                ? 'Datos de demostración'
                : 'Consultando mediciones mediante la API',
            style: TextStyle(
              color: SensorService.modoDemostracion
                  ? Colors.amberAccent
                  : Colors.greenAccent,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TARJETA DE CADA ZONA
  // ==========================================

  Widget _tarjetaZona({
    required String nombre,
    required String codigo,
    required IconData icono,
    required Color color,
  }) {
    final temperatura = _temperatura(codigo);
    final humedad = _humedad(codigo);
    final iluminacion = _iluminacion(codigo);

    final tieneDatos = _mediciones.containsKey(codigo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withAlpha(128),
          width: 1.5,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Identificador: $codigo',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.circle,
                color: tieneDatos
                    ? Colors.greenAccent
                    : Colors.amberAccent,
                size: 12,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(
            color: Colors.white24,
          ),

          const SizedBox(height: 20),

          _filaMedicion(
            icono: Icons.thermostat,
            titulo: 'Temperatura',
            valor: temperatura,
            color: Colors.redAccent,
          ),

          const SizedBox(height: 18),

          _filaMedicion(
            icono: Icons.water_drop_outlined,
            titulo: 'Humedad',
            valor: humedad,
            color: Colors.lightBlueAccent,
          ),

          const SizedBox(height: 18),

          _filaMedicion(
            icono: Icons.wb_sunny_outlined,
            titulo: 'Iluminación (lectura relativa)',
            valor: iluminacion,
            color: Colors.amberAccent,
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 48,

            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ZoneDetailScreen(
                      nombre: nombre,
                      codigo: codigo,
                      temperatura: temperatura,
                      humedad: humedad,
                      iluminacion: iluminacion,
                    ),
                  ),
                );
              },

              icon: const Icon(
                Icons.arrow_forward,
              ),

              label: const Text(
                'Ver detalles',
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
        ],
      ),
    );
  }

  // ==========================================
  // FILA DE MEDICIÓN
  // ==========================================

  Widget _filaMedicion({
    required IconData icono,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icono,
          color: color,
          size: 26,
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ),

        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}