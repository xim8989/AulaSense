
//
// AULASENSE - MOTOR DE RECOMENDACIONES
// Análisis ambiental personalizado basado en reglas
//

const ACTIVIDADES = {
  general: 'Actividades generales',
  lectura: 'Lectura y escritura',
  computadora: 'Trabajo en computadora',
  concentracion: 'Estudio y concentración'
};

function analizarAmbiente(zona, medicion, actividad = 'general') {
  const { temperatura, humedad, iluminacion } = medicion;

  // Validar la actividad seleccionada
  const actividadSeleccionada =
    Object.prototype.hasOwnProperty.call(ACTIVIDADES, actividad)
      ? actividad
      : 'general';

  const recomendaciones = [];
  const alertas = [];

  let puntuacion = 100;

  // =====================================
  // ANALIZAR TEMPERATURA
  // =====================================

  if (temperatura < 20) {
    alertas.push('Temperatura baja');

    recomendaciones.push(
      'La temperatura es baja. Considera reducir las corrientes de aire y mejorar el confort térmico del salón.'
    );

    puntuacion -= 20;

  } else if (temperatura > 27) {
    alertas.push('Temperatura elevada');

    recomendaciones.push(
      'La temperatura es elevada. Se recomienda mejorar la ventilación del aula y evitar la exposición directa al sol.'
    );

    puntuacion -= 20;

  } else {
    recomendaciones.push(
      'La temperatura se encuentra dentro del rango de referencia configurado.'
    );
  }

  // =====================================
  // ANALIZAR HUMEDAD
  // =====================================

  if (humedad < 30) {
    alertas.push('Humedad baja');

    recomendaciones.push(
      'La humedad ambiental es baja. Revisa las condiciones de ventilación y confort del salón.'
    );

    puntuacion -= 15;

  } else if (humedad > 60) {
    alertas.push('Humedad elevada');

    recomendaciones.push(
      'La humedad es elevada. Revisa la ventilación y posibles fuentes de humedad.'
    );

    puntuacion -= 15;

  } else {
    recomendaciones.push(
      'La humedad se encuentra dentro del rango de referencia configurado.'
    );
  }

  // =====================================
  // ANALIZAR ILUMINACIÓN
  // =====================================

  if (iluminacion < 300) {
    alertas.push('Iluminación insuficiente');

    recomendaciones.push(
      'La iluminación es baja para el rango de referencia elegido. Considera aumentar la luz disponible para facilitar la lectura y las actividades escolares.'
    );

    puntuacion -= 25;

  } else if (iluminacion > 750) {
    alertas.push('Iluminación elevada');

    recomendaciones.push(
      'La iluminación supera el rango configurado. Revisa si existen reflejos o deslumbramiento en las áreas de trabajo.'
    );

    puntuacion -= 15;

  } else {
    recomendaciones.push(
      'La iluminación se encuentra dentro del rango de referencia configurado.'
    );
  }

  // =====================================
  // RECOMENDACIONES PERSONALIZADAS
  // =====================================

  switch (actividadSeleccionada) {

    case 'lectura':
      if (iluminacion < 300) {
        recomendaciones.push(
          'Para leer y escribir, aumenta la iluminación del área de trabajo y procura que la luz sea uniforme.'
        );
      } else {
        recomendaciones.push(
          'Para lectura y escritura, mantén una iluminación uniforme y evita sombras sobre los cuadernos y libros.'
        );
      }
      break;

    case 'computadora':
      recomendaciones.push(
        'Para trabajar en computadora, ajusta la posición de la pantalla para reducir reflejos y deslumbramientos.'
      );

      if (temperatura > 27) {
        recomendaciones.push(
          'Durante el trabajo en computadora, mejora la ventilación para favorecer el confort térmico.'
        );
      }
      break;

    case 'concentracion':
      recomendaciones.push(
        'Para estudiar y concentrarse, procura mantener una temperatura confortable y reducir las distracciones ambientales.'
      );

      if (iluminacion < 300) {
        recomendaciones.push(
          'Mejora la iluminación disponible para facilitar las actividades de estudio.'
        );
      }
      break;

    default:
      recomendaciones.push(
        'Para las actividades generales del aula, mantén condiciones adecuadas de temperatura, humedad e iluminación.'
      );
      break;
  }

  // =====================================
  // RESULTADO GENERAL
  // =====================================

  puntuacion = Math.max(0, puntuacion);

  let estado = 'Adecuado';

  if (puntuacion < 60) {
    estado = 'Requiere atención';
  } else if (puntuacion < 85) {
    estado = 'Mejorable';
  }

  return {
    zona,

    fechaAnalisis: new Date().toISOString(),

    tipoAnalisis: 'Reglas de referencia personalizadas',

    actividad: actividadSeleccionada,

    nombreActividad: ACTIVIDADES[actividadSeleccionada],

    medicion: {
      temperatura,
      humedad,
      iluminacion
    },

    puntuacion,
    estado,
    alertas,
    recomendaciones,

    mensaje:
      alertas.length === 0
        ? 'Las condiciones del salón cumplen los rangos de referencia configurados.'
        : 'Se identificaron condiciones ambientales que podrían mejorarse.'
  };
}

module.exports = {
  analizarAmbiente
};
