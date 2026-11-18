
//
// ==========================================
// AULASENSE - BACKEND NODE.JS
// CON RECOMENDACIONES PERSONALIZADAS
// ==========================================
//

// LIBRERÍAS
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

require('dotenv').config();

// MOTOR DE RECOMENDACIONES
const { analizarAmbiente } = require('./recomendaciones');

// ==========================================
// CONFIGURACIÓN DEL SERVIDOR
// ==========================================

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// ==========================================
// ARCHIVO DEL HISTORIAL
// ==========================================

const carpetaDatos = path.join(__dirname, 'data');

const archivoMediciones = path.join(
  carpetaDatos,
  'mediciones.json'
);

// Crear carpeta si no existe
if (!fs.existsSync(carpetaDatos)) {
  fs.mkdirSync(carpetaDatos, { recursive: true });
}

// Crear archivo si no existe
if (!fs.existsSync(archivoMediciones)) {
  fs.writeFileSync(
    archivoMediciones,
    JSON.stringify({ mediciones: [] }, null, 2),
    'utf8'
  );
}

// ==========================================
// FUNCIONES DEL HISTORIAL
// ==========================================

function leerHistorial() {
  const contenido = fs.readFileSync(
    archivoMediciones,
    'utf8'
  );

  const datos = JSON.parse(contenido);

  if (!datos || !Array.isArray(datos.mediciones)) {
    throw new Error(
      'El archivo de historial no tiene un formato válido.'
    );
  }

  return datos.mediciones;
}

function guardarHistorial(historial) {
  const archivoTemporal = `${archivoMediciones}.tmp`;

  fs.writeFileSync(
    archivoTemporal,
    JSON.stringify({ mediciones: historial }, null, 2),
    'utf8'
  );

  fs.renameSync(
    archivoTemporal,
    archivoMediciones
  );
}

// ==========================================
// MEDICIONES DE DEMOSTRACIÓN
// ==========================================

let mediciones = {
  C: {
    temperatura: 24.1,
    humedad: 52,
    iluminacion: 320,
    fecha: null
  },

  S1: {
    temperatura: 23.5,
    humedad: 48,
    iluminacion: 210,
    fecha: null
  },

  S2: {
    temperatura: 25.0,
    humedad: 55,
    iluminacion: 430,
    fecha: null
  }
};

// ==========================================
// RECUPERAR MEDICIONES GUARDADAS
// ==========================================

try {
  const historialGuardado = leerHistorial();

  for (const registro of historialGuardado) {
    const zona = String(
      registro.zona || ''
    ).toUpperCase();

    if (
      Object.prototype.hasOwnProperty.call(mediciones, zona) &&
      typeof registro.temperatura === 'number' &&
      typeof registro.humedad === 'number' &&
      typeof registro.iluminacion === 'number'
    ) {
      mediciones[zona] = {
        temperatura: registro.temperatura,
        humedad: registro.humedad,
        iluminacion: registro.iluminacion,
        fecha: registro.fecha
      };
    }
  }

  console.log(
    `Historial cargado: ${historialGuardado.length} mediciones.`
  );

} catch (error) {
  console.error(
    'No se pudo cargar el historial:',
    error.message
  );

  process.exit(1);
}

// ==========================================
// RUTA PRINCIPAL
// ==========================================

app.get('/', (req, res) => {
  res.json({
    aplicacion: 'AulaSense',
    mensaje: 'Backend funcionando correctamente',
    estado: 'activo',
    recomendaciones: 'habilitadas'
  });
});

// ==========================================
// CONSULTAR TODAS LAS MEDICIONES
// ==========================================

app.get('/api/mediciones', (req, res) => {
  res.json({
    modo: 'demostracion',
    zonas: mediciones
  });
});

// ==========================================
// CONSULTAR HISTORIAL COMPLETO
// ==========================================

app.get('/api/historial', (req, res) => {
  try {
    const historial = leerHistorial();

    res.json({
      total: historial.length,
      mediciones: historial
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: 'No se pudo consultar el historial.'
    });
  }
});

// ==========================================
// CONSULTAR HISTORIAL POR ZONA
// ==========================================

app.get('/api/historial/:zona', (req, res) => {
  const zona = String(
    req.params.zona
  ).toUpperCase();

  if (
    !Object.prototype.hasOwnProperty.call(mediciones, zona)
  ) {
    return res.status(404).json({
      error: 'Zona no encontrada.'
    });
  }

  try {
    const historial = leerHistorial();

    const historialZona = historial.filter(
      (registro) =>
        String(registro.zona || '').toUpperCase() === zona
    );

    res.json({
      zona,
      total: historialZona.length,
      mediciones: historialZona
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: 'No se pudo consultar el historial de la zona.'
    });
  }
});

// ==========================================
// CONSULTAR UNA ZONA ESPECÍFICA
// ==========================================

app.get('/api/mediciones/:zona', (req, res) => {
  const zona = String(
    req.params.zona
  ).toUpperCase();

  if (
    !Object.prototype.hasOwnProperty.call(mediciones, zona)
  ) {
    return res.status(404).json({
      error: 'Zona no encontrada'
    });
  }

  res.json({
    zona,
    medicion: mediciones[zona]
  });
});

// ==========================================
// RECIBIR Y GUARDAR MEDICIONES
// ==========================================

// En el futuro, esta ruta podrá recibir
// mediciones provenientes del Particle Photon.

app.post('/api/mediciones', (req, res) => {
  const {
    zona,
    temperatura,
    humedad,
    iluminacion
  } = req.body || {};

  const codigo = String(
    zona || ''
  ).toUpperCase();

  // Validar zona
  if (
    !Object.prototype.hasOwnProperty.call(mediciones, codigo)
  ) {
    return res.status(400).json({
      error: 'Zona no válida. Utiliza C, S1 o S2.'
    });
  }

  // Validar valores
  if (
    typeof temperatura !== 'number' ||
    !Number.isFinite(temperatura) ||
    typeof humedad !== 'number' ||
    !Number.isFinite(humedad) ||
    typeof iluminacion !== 'number' ||
    !Number.isFinite(iluminacion)
  ) {
    return res.status(400).json({
      error:
        'La temperatura, humedad e iluminación deben ser números válidos.'
    });
  }

  // Crear medición
  const nuevaMedicion = {
    zona: codigo,
    temperatura,
    humedad,
    iluminacion,
    fecha: new Date().toISOString()
  };

  // Guardar en historial
  try {
    const historial = leerHistorial();

    historial.push(nuevaMedicion);

    guardarHistorial(historial);

  } catch (error) {
    console.error(
      'Error al guardar la medición:',
      error.message
    );

    return res.status(500).json({
      error: 'No se pudo guardar la medición.'
    });
  }

  // Actualizar última medición
  mediciones[codigo] = {
    temperatura: nuevaMedicion.temperatura,
    humedad: nuevaMedicion.humedad,
    iluminacion: nuevaMedicion.iluminacion,
    fecha: nuevaMedicion.fecha
  };

  console.log(
    'Nueva medición guardada:',
    nuevaMedicion
  );

  res.json({
    mensaje: 'Medición recibida y guardada correctamente',
    zona: codigo,
    medicion: mediciones[codigo]
  });
});

// ==========================================
// RECOMENDACIONES INTELIGENTES POR SALÓN
// ==========================================

app.get('/api/ia/recomendaciones/:zona', (req, res) => {
  const zona = String(
    req.params.zona
  ).toUpperCase();

  // Validar que exista el salón
  if (
    !Object.prototype.hasOwnProperty.call(mediciones, zona)
  ) {
    return res.status(404).json({
      error: 'Zona no encontrada. Utiliza C, S1 o S2.'
    });
  }

  try {
    // Obtener medición actual
    const medicion = mediciones[zona];

    // Obtener actividad seleccionada
    const actividad =
      typeof req.query.actividad === 'string'
        ? req.query.actividad
        : 'general';

    // Generar recomendaciones personalizadas
    const resultado = analizarAmbiente(
      zona,
      medicion,
      actividad
    );

    // Devolver análisis
    res.json(resultado);

  } catch (error) {
    console.error(
      'Error en el análisis inteligente:',
      error.message
    );

    res.status(500).json({
      error: 'No se pudo generar el análisis ambiental.'
    });
  }
});

// ==========================================
// RECOMENDACIONES DE TODOS LOS SALONES
// ==========================================

app.get('/api/ia/recomendaciones', (req, res) => {
  try {
    const resultados = {};

    // Una misma actividad para las tres zonas
    const actividad =
      typeof req.query.actividad === 'string'
        ? req.query.actividad
        : 'general';

    for (const zona of Object.keys(mediciones)) {
      resultados[zona] = analizarAmbiente(
        zona,
        mediciones[zona],
        actividad
      );
    }

    res.json({
      aplicacion: 'AulaSense',
      tipoAnalisis: 'Reglas de referencia personalizadas',
      actividad: resultados.C.actividad,
      totalZonas: Object.keys(resultados).length,
      resultados
    });

  } catch (error) {
    console.error(
      'Error al analizar las zonas:',
      error.message
    );

    res.status(500).json({
      error: 'No se pudieron generar las recomendaciones.'
    });
  }
});

// ==========================================
// INICIAR SERVIDOR
// ==========================================

app.listen(PORT, () => {
  console.log('====================================');
  console.log('        AULASENSE BACKEND');
  console.log('====================================');
  console.log(`Servidor funcionando en puerto ${PORT}`);
  console.log(`API disponible en http://localhost:${PORT}`);
  console.log('Historial de mediciones habilitado');
  console.log('Recomendaciones inteligentes habilitadas');
  console.log('====================================');
});
