import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Menú principal del Cliente
final clientNavProvider = StateProvider<int>((ref) => 0);

// 2. Menú principal del Trabajador
final workerNavProvider = StateProvider<int>((ref) => 0);

// 3. Controla las pestañas internas del Cliente (0=Abiertos, 1=En Proceso, 2=Finalizados)
final myRequestsTabProvider = StateProvider<int>((ref) => 0);

// 4. Controla las pestañas internas del Trabajador (0=Postulaciones, 1=En Curso, 2=Historial)
final workerJobsTabProvider = StateProvider<int>((ref) => 0);