// Definimos el Enum aquí mismo para no salirnos de la carpeta services
enum JobStatus { open, matched, completed, cancelled }

class ServiceEntity {
  final String id;
  final String title;
  final String description;
  final double basePrice;
  final String categoryId;
  final String clientId; 
  final JobStatus status;
  final bool isActive;
  final DateTime createdAt;

  ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    required this.clientId,
    required this.status,
    required this.isActive,
    required this.createdAt,
  });
}