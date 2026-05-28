import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateServiceFormState {
  final int step;
  final String? categoryId;
  final double? latitude;
  final double? longitude;
  final List<File> images;
  final List<String> existingImageUrls;
  final List<String> removedImageUrls;

  CreateServiceFormState({
    this.step = 0,
    this.categoryId,
    this.latitude,
    this.longitude,
    this.images = const [],
    this.existingImageUrls = const [],
    this.removedImageUrls = const [],
  });

  CreateServiceFormState copyWith({
    int? step, String? categoryId, double? latitude, double? longitude, List<File>? images,
    List<String>? existingImageUrls, List<String>? removedImageUrls,
  }) {
    return CreateServiceFormState(
      step: step ?? this.step,
      categoryId: categoryId ?? this.categoryId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
      removedImageUrls: removedImageUrls ?? this.removedImageUrls,
    );
  }

  List<String> get keptImageUrls =>
      existingImageUrls.where((url) => !removedImageUrls.contains(url)).toList();
}

class CreateServiceFormNotifier extends StateNotifier<CreateServiceFormState> {
  CreateServiceFormNotifier() : super(CreateServiceFormState());

  void setStep(int step) => state = state.copyWith(step: step);
  void setCategory(String id) => state = state.copyWith(categoryId: id);
  void setLocation(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng);
  void addImage(File image) => state = state.copyWith(images: [...state.images, image]);
  void addImages(List<File> newImages) => state = state.copyWith(images: [...state.images, ...newImages]);
  void removeImage(int index) {
    final newImages = List<File>.from(state.images)..removeAt(index);
    state = state.copyWith(images: newImages);
  }
  void removeExistingImage(int index) {
    final url = state.existingImageUrls[index];
    state = state.copyWith(removedImageUrls: [...state.removedImageUrls, url]);
  }
  void removeExistingImageByUrl(String url) {
    state = state.copyWith(removedImageUrls: [...state.removedImageUrls, url]);
  }
  void loadInitialData({String? categoryId, double? lat, double? lng, List<String>? existingImageUrls}) {
    state = state.copyWith(
      categoryId: categoryId,
      latitude: lat,
      longitude: lng,
      existingImageUrls: existingImageUrls ?? [],
    );
  }
}

final createServiceFormProvider = StateNotifierProvider.autoDispose<CreateServiceFormNotifier, CreateServiceFormState>((ref) {
  return CreateServiceFormNotifier();
});