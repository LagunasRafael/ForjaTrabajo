import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Menú principal del Cliente
final clientNavProvider = StateProvider<int>((ref) => 0);

// 2. Menú principal del Trabajador
final workerNavProvider = StateProvider<int>((ref) => 0);

// 3. 👇 NUEVO: Controla las pestañas internas de "Mis Trabajos" (0=Abiertos, 1=En Proceso, 2=Finalizados)
final myRequestsTabProvider = StateProvider<int>((ref) => 0);