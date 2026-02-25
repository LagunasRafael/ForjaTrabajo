import 'package:flutter_riverpod/flutter_riverpod.dart';

// Creamos un control de pestañas independiente para cada rol
final clientNavProvider = StateProvider<int>((ref) => 0);
final workerNavProvider = StateProvider<int>((ref) => 0);
final adminNavProvider = StateProvider<int>((ref) => 0);