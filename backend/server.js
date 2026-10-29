// ==========================================
// AULASENSE - BACKEND NODE.JS
// ==========================================

// LIBRERÍAS
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

require('dotenv').config();

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

// Crear la carpeta si no existe
if (!fs.existsSync(carpetaDatos)) {
  fs.mkdirSync(carpetaDatos, { recursive: true });
}

// Crear el archivo si no existe
if (!fs.existsSync(archivoMediciones)) {
  fs.writeFileSync(
    archivoMediciones,
    JSON.stringify({ mediciones: [] }, null, 2),
    'utf8'
  );
}

// ==========================================
// FUNCIONES PARA GUARDAR Y LEER EL HISTORIAL
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

  fs.renameSync(archivoTemporal, archivoMediciones);
}

// ==========================================
// MEDICIONES INICIALES DE DEMOSTRACIÓN
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

  // Recuperar la última medición de cada zona
  for (const registro of historialGuardado) {
    const zona = String(registro.zona || '').toUpperCase();

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
    estado: 'activo'
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
  const zona = String(req.params.zona).toUpperCase();

  if (!Object.prototype.hasOwnProperty.call(mediciones, zona)) {
    return res.status(404).json({
      error: 'Zona no encontrada.'
    });
  }

  try {
    const historial = leerHistorial();

    const historialZona = historial.filter(
      (registro) => registro.zona === zona
    );

    res.json({
      zona: zona,
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
  const zona = String(req.params.zona).toUpperCase();

  if (!Object.prototype.hasOwnProperty.call(mediciones, zona)) {
    return res.status(404).json({
      error: 'Zona no encontrada'
    });
  }

  res.json({
    zona: zona,
    medicion: mediciones[zona]
  });
});

// ==========================================
// RECIBIR MEDICIONES
// ==========================================

// Esta ruta permitirá recibir datos del Photon
// a través de Particle Cloud en una etapa posterior.

app.post('/api/mediciones', (req, res) => {
  const {
    zona,
    temperatura,
    humedad,
    iluminacion
  } = req.body || {};

  const codigo = String(zona || '').toUpperCase();

  // VALIDAR QUE LA ZONA EXISTA
  if (!Object.prototype.hasOwnProperty.call(mediciones, codigo)) {
    return res.status(400).json({
      error: 'Zona no válida. Utiliza C, S1 o S2.'
    });
  }

  // VALIDAR LOS VALORES RECIBIDOS
  if (
    typeof temperatura !== 'number' ||
    !Number.isFinite(temperatura) ||
    typeof humedad !== 'number' ||
    !Number.isFinite(humedad) ||
    typeof iluminacion !== 'number' ||
    !Number.isFinite(iluminacion)
  ) {
    return res.status(400).json({
      error: 'La temperatura, humedad e iluminación deben ser números válidos.'
    });
  }

  // CREAR NUEVA MEDICIÓN
  const nuevaMedicion = {
    zona: codigo,
    temperatura: temperatura,
    humedad: humedad,
    iluminacion: iluminacion,
    fecha: new Date().toISOString()
  };

  // GUARDAR EN EL HISTORIAL
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

  // ACTUALIZAR LA MEDICIÓN ACTUAL
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

  // CONFIRMAR QUE SE RECIBIÓ
  res.json({
    mensaje: 'Medición recibida y guardada correctamente',
    zona: codigo,
    medicion: mediciones[codigo]
  });
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
  console.log('====================================');
}); 