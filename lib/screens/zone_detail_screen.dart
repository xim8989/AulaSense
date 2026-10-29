import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String nombre;
  final String codigo;

  // Se conservan para mantener la navegación actual.
  final String temperatura;
  final String humedad;
  final String iluminacion;

  const ZoneDetailScreen({
    super.key,
    required this.nombre,
    required this.codigo,
    required this.temperatura,
    required this.humedad,
    required this.iluminacion,
  });

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  // COLORES DE AULASENSE
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFF9333EA);
  static const Color moradoClaro = Color(0xFFB366FF);

  // SERVICIO DE SENSORES
  final SensorService sensorService = SensorService();

  // VARIABLES
  SensorReading? lectura;
  String? error;
  bool cargando = true;
  bool actualizando = false;

  List<SensorReading> historial = [];
  bool cargandoHistorial = true;
  String? errorHistorial;
  bool actualizandoHistorial = false;

  // TEMPORIZADOR DE ACTUALIZACIÓN AUTOMÁTICA
  Timer? temporizador;

  // ==========================================
  // INICIALIZACIÓN
  // ==========================================
  @override
  void initState() {
    super.initState();

    // Cargar mediciones al abrir la pantalla
    cargarMedicion();
    cargarHistorial();

    // Consultar nuevas mediciones cada 30 segundos
    temporizador = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (!actualizando) {
          cargarMedicion();
          cargarHistorial();
        }
      },
    );
  }

  // ==========================================
  // DETENER TEMPORIZADOR
  // ==========================================
  @override
  void dispose() {
    temporizador?.cancel();
    super.dispose();
  }

  // ==========================================
  // CARGAR MEDICIONES
  // ==========================================
  Future<void> cargarMedicion() async {
    if (actualizando) return;

    setState(() {
      actualizando = true;
      error = null;

      // Mostrar carga inicial solamente
      if (lectura == null) {
        cargando = true;
      }
    });

    try {
      final resultado = await sensorService.obtenerMedicion(
        widget.codigo,
      );

      if (!mounted) return;

      setState(() {
        lectura = resultado;
        cargando = false;
        actualizando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
        actualizando = false;
      });
    }
  }

  // ==========================================
  // CONSULTAR HISTORIAL REAL
  // ==========================================
  Future<void> cargarHistorial() async {
    if (actualizandoHistorial) return;
    setState(() {
      actualizandoHistorial = true;
      errorHistorial = null;
    });

    try {
      final registros = await sensorService.obtenerHistorial(widget.codigo);
      if (!mounted) return;
      setState(() {
        historial = registros;
        cargandoHistorial = false;
        actualizandoHistorial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorHistorial = e.toString();
        cargandoHistorial = false;
        actualizandoHistorial = false;
      });
    }
  }

  void actualizarTodo() {
    cargarMedicion();
    cargarHistorial();
  }

  // ==========================================
  // FORMATEAR FECHA
  // ==========================================
  String formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();

    String dosDigitos(int numero) {
      return numero.toString().padLeft(2, '0');
    }

    return '${dosDigitos(local.day)}/'
        '${dosDigitos(local.month)}/'
        '${local.year} '
        '${dosDigitos(local.hour)}:'
        '${dosDigitos(local.minute)}:'
        '${dosDigitos(local.second)}';
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      // BARRA SUPERIOR
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar mediciones',
            onPressed: actualizando ? null : actualizarTodo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // CONTENIDO
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================
                // INFORMACIÓN DE LA ZONA
                // =====================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: tarjeta,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: moradoClaro.withAlpha(102),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: morado.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sensors,
                          size: 50,
                          color: moradoClaro,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        widget.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Identificador: ${widget.codigo}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ESTADO DEL SISTEMA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: SensorService.modoDemostracion
                              ? Colors.amber.withAlpha(30)
                              : error == null
                                  ? Colors.green.withAlpha(30)
                                  : Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              SensorService.modoDemostracion
                                  ? Icons.info_outline
                                  : error == null
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                              color: SensorService.modoDemostracion
                                  ? Colors.amberAccent
                                  : error == null
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                              size: 18,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              SensorService.modoDemostracion
                                  ? 'Modo demostración'
                                  : error != null
                                      ? 'Error al consultar datos'
                                      : actualizando
                                          ? 'Consultando mediciones'
                                          : 'API disponible',
                              style: TextStyle(
                                color: SensorService.modoDemostracion
                                    ? Colors.amberAccent
                                    : error == null
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // =====================================
                // TÍTULO DE MEDICIONES
                // =====================================
                const Text(
                  'Mediciones ambientales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // INDICADOR DE ACTUALIZACIÓN
                if (actualizando && lectura != null) ...[
                  const LinearProgressIndicator(
                    color: moradoClaro,
                    backgroundColor: tarjeta,
                  ),
                  const SizedBox(height: 15),
                ],

                // =====================================
                // CARGANDO DATOS
                // =====================================
                if (cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        color: moradoClaro,
                      ),
                    ),
                  )

                // =====================================
                // ERROR SIN DATOS PREVIOS
                // =====================================
                else if (error != null && lectura == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'No se pudieron obtener las mediciones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: actualizando
                              ? null
                              : actualizarTodo,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: morado,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )

                // =====================================
                // MEDICIONES DISPONIBLES
                // =====================================
                else if (lectura != null) ...[
                  // TEMPERATURA
                  tarjetaMedicion(
                    icono: Icons.thermostat,
                    titulo: 'Temperatura',
                    valor:
                        '${lectura!.temperatura.toStringAsFixed(1)} °C',
                    descripcion:
                        'Temperatura ambiental de la zona',
                    color: Colors.redAccent,
                  ),

                  const SizedBox(height: 16),

                  // HUMEDAD
                  tarjetaMedicion(
                    icono: Icons.water_drop_outlined,
                    titulo: 'Humedad',
                    valor:
                        '${lectura!.humedad.toStringAsFixed(0)} %',
                    descripcion:
                        'Humedad relativa del ambiente',
                    color: Colors.lightBlueAccent,
                  ),

                  const SizedBox(height: 16),

                  // ILUMINACIÓN
                  tarjetaMedicion(
                    icono: Icons.wb_sunny_outlined,
                    titulo: 'Iluminación',
                    valor:
                        lectura!.iluminacion.toStringAsFixed(0),
                    descripcion:
                        'Lectura relativa de iluminación',
                    color: Colors.amberAccent,
                  ),

                  const SizedBox(height: 25),

                  // =====================================
                  // FECHA DE LA MEDICIÓN
                  // =====================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: moradoClaro,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Última medición',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          'Zona: ${lectura!.zona}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Fecha: ${formatearFecha(lectura!.fecha)}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ERROR CONSERVANDO ÚLTIMA LECTURA
                  if (error != null) ...[
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent,
                        ),
                      ),
                      child: const Text(
                        'No se pudo actualizar la medición. '
                        'Se muestra la última lectura disponible.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 30),

                // =====================================
                // GRÁFICAS DEL HISTORIAL REAL
                // =====================================
                const Text(
                  'Historial de mediciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zona ${widget.codigo} · ${historial.length} registros guardados',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                if (cargandoHistorial)
                  const Center(
                    child: CircularProgressIndicator(color: moradoClaro),
                  )
                else if (errorHistorial != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No se pudo consultar el historial.\n$errorHistorial',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  )
                else if (historial.length < 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tarjeta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Se necesitan al menos 2 mediciones guardadas '
                      'en esta zona para dibujar las gráficas. '
                      'Las nuevas lecturas se agregarán cuando '
                      'el backend reciba mediciones.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else ...[
                  graficaHistorial(
                    titulo: 'Temperatura',
                    unidad: '°C',
                    color: Colors.redAccent,
                    valores: historial.map((e) => e.temperatura).toList(),
                  ),
                  const SizedBox(height: 16),
                  graficaHistorial(
                    titulo: 'Humedad',
                    unidad: '%',
                    color: Colors.lightBlueAccent,
                    valores: historial.map((e) => e.humedad).toList(),
                  ),
                  const SizedBox(height: 16),
                  graficaHistorial(
                    titulo: 'Iluminación',
                    unidad: 'lectura relativa',
                    color: Colors.amberAccent,
                    valores: historial.map((e) => e.iluminacion).toList(),
                  ),
                ],
                const SizedBox(height: 30),

                // =====================================
                // ESTADO DEL MONITOREO
                // =====================================
                const Text(
                  'Estado del monitoreo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tarjeta,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            SensorService.modoDemostracion
                                ? Icons.info_outline
                                : Icons.cloud_outlined,
                            color: SensorService.modoDemostracion
                                ? Colors.amberAccent
                                : moradoClaro,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              SensorService.modoDemostracion
                                  ? 'Modo demostración'
                                  : 'Consulta mediante API',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        SensorService.modoDemostracion
                            ? 'Las mediciones mostradas son simuladas. '
                              'La pantalla consulta SensorService '
                              'automáticamente cada 30 segundos.'
                            : 'La aplicación consulta el backend '
                              'cada 30 segundos. El estado real '
                              'del Photon se verificará mediante '
                              'Particle Cloud.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // =====================================
                // BOTÓN ACTUALIZAR
                // =====================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: actualizando
                        ? null
                        : actualizarTodo,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      actualizando
                          ? 'Actualizando...'
                          : 'Actualizar mediciones',
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

                // =====================================
                // BOTÓN VOLVER
                // =====================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a zonas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: moradoClaro,
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
    );
  }

  // =====================================
  // TARJETA CON GRÁFICA DEL HISTORIAL
  // =====================================
  Widget graficaHistorial({
    required String titulo,
    required String unidad,
    required Color color,
    required List<double> valores,
  }) {
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$titulo ($unidad)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mín: ${minimo.toStringAsFixed(1)}  ·  '
            'Máx: ${maximo.toStringAsFixed(1)}  ·  '
            'Actual: ${valores.last.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _HistorialPainter(valores: valores, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatearFecha(historial.first.fecha),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                formatearFecha(historial.last.fecha),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================
  // TARJETA DE MEDICIÓN
  // =====================================
  Widget tarjetaMedicion({
    required IconData icono,
    required String titulo,
    required String valor,
    required String descripcion,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(102),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
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

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Gráfica de líneas sin dependencias adicionales.
class _HistorialPainter extends CustomPainter {
  final List<double> valores;
  final Color color;

  const _HistorialPainter({required this.valores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2 || size.width <= 0 || size.height <= 0) return;

    final guia = Paint()
      ..color = Colors.white.withAlpha(25)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guia);
    }

    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final rango = maximo - minimo;
    final margen = rango == 0 ? 1.0 : rango * 0.15;
    final inferior = minimo - margen;
    final superior = maximo + margen;
    final puntos = <Offset>[];

    for (var i = 0; i < valores.length; i++) {
      final x = size.width * i / (valores.length - 1);
      final y = size.height *
          (1 - (valores[i] - inferior) / (superior - inferior));
      puntos.add(Offset(x, y));
    }

    final linea = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (final punto in puntos.skip(1)) {
      linea.lineTo(punto.dx, punto.dy);
    }
    canvas.drawPath(
      linea,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final punto in puntos) {
      canvas.drawCircle(punto, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _HistorialPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.valores.length != valores.length ||
      !_mismosValores(oldDelegate.valores, valores);

  bool _mismosValores(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
