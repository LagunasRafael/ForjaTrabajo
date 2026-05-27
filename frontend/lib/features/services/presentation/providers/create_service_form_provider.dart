import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateServiceFormState {
  final int step;
  final String? categoryId;
  final double? latitude;
  final double? longitude;
  final List<File> images;

  CreateServiceFormState({
    this.step = 0,
    this.categoryId,
    this.latitude,
    this.longitude,
    this.images = const [],
  });

  CreateServiceFormState copyWith({
    int? step, String? categoryId, double? latitude, double? longitude, List<File>? images,
  }) {
    return CreateServiceFormState(
      step: step ?? this.step,
      categoryId: categoryId ?? this.categoryId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
    );
  }
}

class CreateServiceFormNotifier extends StateNotifier<CreateServiceFormState> {
  CreateServiceFormNotifier() : super(CreateServiceFormState());

  void setStep(int step) => state = state.copyWith(step: step);
  void setCategory(String id) => state = state.copyWith(categoryId: id);
  void setLocation(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng);
  void addImage(File image) => state = state.copyWith(images: [...state.images, image]);
  void removeImage(int index) {
    final newImages = List<File>.from(state.images)..removeAt(index);
    state = state.copyWith(images: newImages);
  }
  void loadInitialData({String? categoryId, double? lat, double? lng}) {
    state = state.copyWith(categoryId: categoryId, latitude: lat, longitude: lng);
  }
}

final createServiceFormProvider = StateNotifierProvider.autoDispose<CreateServiceFormNotifier, CreateServiceFormState>((ref) {
  return CreateServiceFormNotifier();
});