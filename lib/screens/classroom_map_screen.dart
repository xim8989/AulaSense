import 'package:flutter/material.dart';
import 'zone_detail_screen.dart';

class ClassroomMapScreen extends StatefulWidget {
  const ClassroomMapScreen({super.key});

  @override
  State<ClassroomMapScreen> createState() => _ClassroomMapScreenState();
}

class _ClassroomMapScreenState extends State<ClassroomMapScreen> {
  static const Color fondo = Color(0xFF0D0B2B);
  static const Color tarjeta = Color(0xFF1D1B45);
  static const Color morado = Color(0xFF9333EA);
  static const Color moradoClaro = Color(0xFFB366FF);

  // Posiciones relativas de los sensores.
  // Los valores van de 0.0 a 1.0.
  final Map<String, Offset> posiciones = {
    'S1': const Offset(0.20, 0.30),
    'S2': const Offset(0.80, 0.30),
    'C': const Offset(0.50, 0.70),
  };

  String zonaSeleccionada = 'C';

  final Map<String, Map<String, String>> datos = {
    'C': {
      'nombre': 'Zona Central',
      'temperatura': '24.1 °C',
      'humedad': '52 %',
      'iluminacion': '320',
    },
    'S1': {
      'nombre': 'Zona S1',
      'temperatura': '23.5 °C',
      'humedad': '48 %',
      'iluminacion': '210',
    },
    'S2': {
      'nombre': 'Zona S2',
      'temperatura': '25.0 °C',
      'humedad': '55 %',
      'iluminacion': '430',
    },
  };

  Color colorZona(String codigo) {
    switch (codigo) {
      case 'S1':
        return moradoClaro;
      case 'S2':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  void abrirDetalles() {
    final zona = datos[zonaSeleccionada]!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneDetailScreen(
          nombre: zona['nombre']!,
          codigo: zonaSeleccionada,
          temperatura: zona['temperatura']!,
          humedad: zona['humedad']!,
          iluminacion: zona['iluminacion']!,
        ),
      ),
    );
  }

  void restaurarPosiciones() {
    setState(() {
      posiciones['S1'] = const Offset(0.20, 0.30);
      posiciones['S2'] = const Offset(0.80, 0.30);
      posiciones['C'] = const Offset(0.50, 0.70);
    });
  }

  @override
  Widget build(BuildContext context) {
    final zona = datos[zonaSeleccionada]!;

    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        title: const Text('Mapa del salón'),
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapa interactivo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Toca un sensor para consultar sus mediciones. '
                  'También puedes arrastrarlo para cambiar su posición.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Mapa ilustrativo · Datos simulados',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 25),

                // MAPA INTERACTIVO
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double ancho = constraints.maxWidth;
                    final double alto = ancho * 0.75;

                    return Container(
                      width: ancho,
                      height: alto,
                      decoration: BoxDecoration(
                        color: tarjeta,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: moradoClaro.withAlpha(120),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // PIZARRÓN
                          Positioned(
                            top: 12,
                            left: ancho * 0.20,
                            width: ancho * 0.60,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: morado,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PIZARRÓN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // ENTRADA
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.door_front_door_outlined,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'ENTRADA',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SENSORES
                          ...posiciones.keys.map((codigo) {
                            final posicion = posiciones[codigo]!;
                            const double tamano = 66;

                            final double izquierda =
                                posicion.dx * (ancho - tamano);

                            final double arriba =
                                posicion.dy * (alto - tamano);

                            return Positioned(
                              left: izquierda,
                              top: arriba,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    zonaSeleccionada = codigo;
                                  });
                                },

                                onPanUpdate: (details) {
                                  setState(() {
                                    final actual = posiciones[codigo]!;

                                    final nuevaX = (actual.dx +
                                            details.delta.dx /
                                                (ancho - tamano))
                                        .clamp(0.0, 1.0);

                                    final nuevaY = (actual.dy +
                                            details.delta.dy /
                                                (alto - tamano))
                                        .clamp(0.0, 1.0);

                                    posiciones[codigo] =
                                        Offset(nuevaX, nuevaY);
                                  });
                                },

                                child: Container(
                                  width: tamano,
                                  height: tamano,
                                  decoration: BoxDecoration(
                                    color: colorZona(codigo).withAlpha(45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorZona(codigo),
                                      width: zonaSeleccionada == codigo
                                          ? 4
                                          : 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sensors,
                                        color: colorZona(codigo),
                                        size: 23,
                                      ),
                                      Text(
                                        codigo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // RESTAURAR POSICIONES
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: restaurarPosiciones,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restaurar posiciones'),
                    style: TextButton.styleFrom(
                      foregroundColor: moradoClaro,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // INFORMACIÓN DE LA ZONA SELECCIONADA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: tarjeta,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorZona(zonaSeleccionada).withAlpha(120),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sensors,
                            color: colorZona(zonaSeleccionada),
                            size: 28,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              zona['nombre']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Divider(color: Colors.white24),

                      const SizedBox(height: 15),

                      medicion(
                        Icons.thermostat,
                        'Temperatura',
                        zona['temperatura']!,
                        Colors.redAccent,
                      ),

                      const SizedBox(height: 15),

                      medicion(
                        Icons.water_drop,
                        'Humedad',
                        zona['humedad']!,
                        Colors.lightBlueAccent,
                      ),

                      const SizedBox(height: 15),

                      medicion(
                        Icons.wb_sunny_outlined,
                        'Iluminación',
                        zona['iluminacion']!,
                        Colors.amberAccent,
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: abrirDetalles,
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
                ),

                const SizedBox(height: 25),

                const Text(
                  'Las posiciones son ilustrativas y los cambios '
                  'se mantienen solamente mientras esta pantalla '
                  'permanezca abierta.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
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

  // FILA DE MEDICIÓN
  Widget medicion(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Row(
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
    );
  }
}