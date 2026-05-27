import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/usecases/location/get_device_location_usecase.dart';

final getDeviceLocationUseCaseProvider = Provider((ref) => GetDeviceLocationUseCase());
