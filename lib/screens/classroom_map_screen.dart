
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';
import 'zone_detail_screen.dart';

class ClassroomMapScreen extends StatefulWidget {
  const ClassroomMapScreen({super.key});

  @override
  State<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends State<ClassroomMapScreen>
    with SingleTickerProviderStateMixin {
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFF9333EA);
  static const Color moradoClaro = Color(0xFFB366FF);

  final SensorService _servicio = SensorService();
  final Map<String, SensorReading> _lecturas = {};

  late final AnimationController _animacion;
  Timer? _temporizador;

  int pisoSeleccionado = 2;
  String zonaSeleccionada = 'C';

  bool cargando = true;
  String? error;

  // Ubicación de los íconos originales en la imagen.
  // Coordenadas proporcionales al ancho y alto del mapa.
  final Map<String, Offset> posiciones = {
    'S1': const Offset(0.50, 0.12),
    'S2': const Offset(0.20, 0.52),
    'C': const Offset(0.80, 0.52),
  };

  @override
  void initState() {
    super.initState();

    _animacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    cargarMediciones();

    _temporizador = Timer.periodic(
      const Duration(seconds: 30),
      (_) => cargarMediciones(),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _animacion.dispose();
    super.dispose();
  }

  // =========================================
  // CARGAR MEDICIONES
  // =========================================

  Future<void> cargarMediciones() async {
    try {
      final resultados = await Future.wait([
        _servicio.obtenerMedicion('C'),
        _servicio.obtenerMedicion('S1'),
        _servicio.obtenerMedicion('S2'),
      ]);

      if (!mounted) return;

      setState(() {
        _lecturas['C'] = resultados[0];
        _lecturas['S1'] = resultados[1];
        _lecturas['S2'] = resultados[2];

        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron actualizar las mediciones.';
      });

      debugPrint('Error al cargar sensores: $e');
    }
  }

  // =========================================
  // ESTADO DE CADA SENSOR
  // =========================================

  Color colorSensor(String codigo) {
    final lectura = _lecturas[codigo];

    if (lectura == null) {
      return Colors.grey;
    }

    final fueraDeRango =
        lectura.temperatura > 28 ||
        lectura.temperatura < 18 ||
        lectura.humedad > 60 ||
        lectura.humedad < 30 ||
        lectura.iluminacion < 300;

    return fueraDeRango
        ? Colors.orangeAccent
        : Colors.greenAccent;
  }

  String obtenerTemperatura(String codigo) {
    final lectura = _lecturas[codigo];

    if (lectura == null) return '-- °C';

    return '${lectura.temperatura.toStringAsFixed(1)} °C';
  }

  String obtenerHumedad(String codigo) {
    final lectura = _lecturas[codigo];

    if (lectura == null) return '-- %';

    return '${lectura.humedad.toStringAsFixed(0)} %';
  }

  String obtenerIluminacion(String codigo) {
    final lectura = _lecturas[codigo];

    if (lectura == null) return '--';

    return lectura.iluminacion.toStringAsFixed(0);
  }

  String nombreZona(String codigo) {
    if (codigo == 'C') {
      return 'Salón C - Zona Central';
    }

    return 'Salón $codigo';
  }

  // =========================================
  // NAVEGACIÓN A DETALLES
  // =========================================

  void abrirDetalles(String codigo) {
    setState(() {
      zonaSeleccionada = codigo;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneDetailScreen(
          nombre: nombreZona(codigo),
          codigo: codigo,
          temperatura: obtenerTemperatura(codigo),
          humedad: obtenerHumedad(codigo),
          iluminacion: obtenerIluminacion(codigo),
        ),
      ),
    );
  }

  // =========================================
  // BOTONES PARA CAMBIAR DE PISO
  // =========================================

  Widget botonPiso(int piso) {
    final seleccionado = pisoSeleccionado == piso;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              pisoSeleccionado = piso;
            });
          },
          icon: const Icon(
            Icons.layers_outlined,
            size: 18,
          ),
          label: Text('Piso $piso'),
          style: ElevatedButton.styleFrom(
            backgroundColor: seleccionado ? morado : tarjeta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // =========================================
  // SENSOR CON ANIMACIÓN
  // =========================================

  Widget sensorAnimado(
    String codigo,
    double progreso,
    double tamano,
  ) {
    final color = colorSensor(codigo);
    final seleccionado = zonaSeleccionada == codigo;

    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo que tapa el ícono original del PNG.
          Container(
            width: tamano * 0.94,
            height: tamano * 0.94,
            decoration: BoxDecoration(
              color: tarjeta,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
          ),

          // Anillo luminoso animado.
          Container(
            width: tamano * (0.55 + progreso * 0.43),
            height: tamano * (0.55 + progreso * 0.43),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(
                  alpha: 1 - progreso,
                ),
                width: 3,
              ),
            ),
          ),

          // Ícono principal.
          Container(
            width: tamano * 0.68,
            height: tamano * 0.68,
            decoration: BoxDecoration(
              color: fondo,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: seleccionado ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.wifi,
                color: color,
                size: tamano * 0.34,
              ),
            ),
          ),

          // Nombre del salón.
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
              ),
              child: Text(
                codigo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: math.max(11, tamano * 0.17),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // MAPA 3D
  // =========================================

  Widget mapa3D() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        const proporcion = 1199 / 645;
        final alto = ancho / proporcion;

        return Container(
          width: ancho,
          height: alto,
          decoration: BoxDecoration(
            color: tarjeta,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: moradoClaro.withValues(alpha: 0.4),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // Imagen 3D del edificio.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/aulasense_edificio_solo.png',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: tarjeta,
                        alignment: Alignment.center,
                        child: const Text(
                          'No se encontró la imagen 3D.\n'
                          'Revisa assets/images.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),

                // Primer piso: pendiente de imagen propia.
                if (pisoSeleccionado == 1)
                  Positioned.fill(
                    child: Container(
                      color: fondo.withValues(alpha: 0.80),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: tarjeta,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment,
                                color: moradoClaro,
                                size: 40,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Primer piso',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vista 3D del primer piso pendiente.\n'
                                'Los sensores actuales están arriba.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Sensores interactivos del segundo piso.
                if (pisoSeleccionado == 2)
                  ...posiciones.entries.map((entrada) {
                    final codigo = entrada.key;
                    final posicion = entrada.value;

                    // Tamaño proporcional a la imagen.
                    final tamano = math.max(44.0, ancho * 0.105);

                    return Positioned(
                      left: posicion.dx * ancho - tamano / 2,
                      top: posicion.dy * alto - tamano / 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => abrirDetalles(codigo),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedBuilder(
                            animation: _animacion,
                            builder: (context, child) {
                              return sensorAnimado(
                                codigo,
                                _animacion.value,
                                tamano,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================
  // FILAS DE MEDICIONES
  // =========================================

  Widget medicion(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF302B59),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
            size: 25,
          ),
          const SizedBox(width: 12),
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
      ),
    );
  }

  // =========================================
  // TARJETA DE INFORMACIÓN
  // =========================================

  Widget tarjetaInformacion() {
    final codigo = zonaSeleccionada;
    final color = colorSensor(codigo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moradoClaro.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                color: color,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreZona(codigo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Segundo piso',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          medicion(
            Icons.thermostat,
            'Temperatura',
            obtenerTemperatura(codigo),
            Colors.pinkAccent,
          ),

          const SizedBox(height: 12),

          medicion(
            Icons.water_drop,
            'Humedad',
            obtenerHumedad(codigo),
            Colors.lightBlueAccent,
          ),

          const SizedBox(height: 12),

          medicion(
            Icons.wb_sunny_outlined,
            'Iluminación',
            obtenerIluminacion(codigo),
            Colors.amberAccent,
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => abrirDetalles(codigo),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver detalles de la zona'),
              style: ElevatedButton.styleFrom(
                backgroundColor: morado,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // LEYENDA
  // =========================================

  Widget leyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================
  // PANTALLA PRINCIPAL
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Mapa de la Facultad'),
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: cargarMediciones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mediciones',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargarMediciones,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Mapa interactivo 3D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Facultad de Ingeniería Electromecánica',
              style: TextStyle(
                color: moradoClaro,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Visualización arquitectónica de dos pisos '
              'con patio central.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                botonPiso(1),
                botonPiso(2),
              ],
            ),

            const SizedBox(height: 20),

            mapa3D(),

            const SizedBox(height: 15),

            Text(
              pisoSeleccionado == 2
                  ? 'Toca un sensor para abrir los detalles del salón.'
                  : 'Selecciona el segundo piso para ver los sensores.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 22),

            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                leyenda(
                  Colors.greenAccent,
                  'Dentro de rango',
                ),
                leyenda(
                  Colors.orangeAccent,
                  'Requiere revisión',
                ),
                leyenda(
                  Colors.grey,
                  'Sin datos',
                ),
              ],
            ),

            const SizedBox(height: 22),

            if (cargando)
              const Center(
                child: CircularProgressIndicator(
                  color: moradoClaro,
                ),
              ),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                  ),
                ),
              ),

            if (pisoSeleccionado == 2)
              tarjetaInformacion(),

            const SizedBox(height: 25),

            const Text(
              'Modelo arquitectónico ilustrativo. '
              'Las posiciones de los sensores son provisionales. '
              'Las mediciones continúan en modo demostración '
              'hasta conectar el Particle Photon.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
