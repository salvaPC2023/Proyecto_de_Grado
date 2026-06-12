abstract class AppConstants {
  // Shift windows: shiftNumber -> (startHour, endHour) — mirrors server-side SHIFT_WINDOWS
  static const shiftWindows = {
    1: (23, 7),  // crosses midnight: 23:00–07:00
    2: (7, 15),  // 07:00–15:00
    3: (15, 23), // 15:00–23:00
  };

  static const shiftLabels = {
    1: '23:00 – 07:00',
    2: '07:00 – 15:00',
    3: '15:00 – 23:00',
  };

  // Fixed PM step descriptions injected at positions 1-3 by the server use case
  static const fixedStepDescriptions = [
    'PM01 - Inspección inicial y verificación de seguridad',
    'PM02 - Ejecución de mantenimiento preventivo',
    'PM03 - Pruebas de funcionamiento y cierre',
  ];

  // Priority labels (1 = highest)
  static const priorityLabels = {
    1: 'Urgente',
    2: 'Alta',
    3: 'Normal',
    4: 'Baja',
  };

  // Deviation keys displayed in the closure form — must match backend DeviationKey enum values
  static const deviationKeys = [
    ('PM01 Executed', 'PM01 Ejecutado'),
    ('PM01 Not Executed', 'PM01 No ejecutado'),
  ];
}
