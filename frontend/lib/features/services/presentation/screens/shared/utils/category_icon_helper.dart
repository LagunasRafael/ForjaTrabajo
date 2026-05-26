import 'package:flutter/material.dart';

class CategoryData {
  final List<String> keywords;
  final IconData icon;
  final Color color;

  const CategoryData({
    required this.keywords,
    required this.icon,
    required this.color,
  });
}

extension CategoryHelper on String {
  static const List<CategoryData> _categories = [
    CategoryData(
      keywords: ['plom', 'fuga', 'font'],
      icon: Icons.plumbing,
      color: Colors.blue,
    ),
    CategoryData(
      keywords: ['electr', 'luz', 'cable'],
      icon: Icons.electric_bolt,
      color: Colors.orange,
    ),
    CategoryData(
      keywords: ['carp', 'mueb', 'madera'],
      icon: Icons.handyman,
      color: Colors.brown,
    ),
    CategoryData(
      keywords: ['pint'],
      icon: Icons.format_paint,
      color: Colors.teal,
    ),
    CategoryData(
      keywords: ['limp', 'aseo'],
      icon: Icons.cleaning_services,
      color: Colors.lightBlue,
    ),
    CategoryData(
      keywords: ['jardin', 'poda', 'pasto'],
      icon: Icons.yard,
      color: Colors.green,
    ),
    CategoryData(
      keywords: ['alba', 'obra', 'constru'],
      icon: Icons.construction,
      color: Colors.brown,
    ),
    CategoryData(
      keywords: ['herr', 'solda', 'metal'],
      icon: Icons.build,
      color: Colors.grey,
    ),
    CategoryData(
      keywords: ['cerraj', 'llave', 'cerradura'],
      icon: Icons.key,
      color: Colors.amber,
    ),
    CategoryData(
      keywords: ['vidri', 'vidrio', 'ventana'],
      icon: Icons.window,
      color: Colors.cyan,
    ),
    CategoryData(
      keywords: ['imper', 'humedad', 'techo'],
      icon: Icons.water_drop,
      color: Colors.lightBlue,
    ),
    CategoryData(
      keywords: ['mec', 'auto', 'carro'],
      icon: Icons.car_repair,
      color: Colors.blueGrey,
    ),
    CategoryData(
      keywords: ['moto'],
      icon: Icons.two_wheeler,
      color: Colors.red,
    ),
    CategoryData(
      keywords: ['aire', 'clima', 'refrigeracion'],
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
    ),
    CategoryData(
      keywords: ['electrodom', 'lavadora', 'refri'],
      icon: Icons.kitchen,
      color: Colors.deepOrange,
    ),
    CategoryData(
      keywords: ['comput', 'laptop', 'pc', 'tecnologia'],
      icon: Icons.computer,
      color: Colors.deepPurple,
    ),
    CategoryData(
      keywords: ['celular', 'telefono', 'movil'],
      icon: Icons.phone_iphone,
      color: Colors.green,
    ),
    CategoryData(
      keywords: ['internet', 'wifi', 'red'],
      icon: Icons.wifi,
      color: Colors.blue,
    ),
    CategoryData(
      keywords: ['camara', 'seguridad', 'alarma'],
      icon: Icons.videocam,
      color: Colors.redAccent,
    ),
    CategoryData(
      keywords: ['panad', 'pan'],
      icon: Icons.bakery_dining,
      color: Colors.deepOrange,
    ),
    CategoryData(
      keywords: ['comida', 'cocina', 'chef'],
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    CategoryData(
      keywords: ['evento', 'fiesta', 'banquete'],
      icon: Icons.celebration,
      color: Colors.purple,
    ),
    CategoryData(
      keywords: ['foto', 'video'],
      icon: Icons.photo_camera,
      color: Colors.indigo,
    ),
    CategoryData(
      keywords: ['belleza', 'maquill', 'uñas', 'unas', 'barber', 'cabello', 'corte'],
      icon: Icons.face_retouching_natural,
      color: Colors.pinkAccent,
    ),
    CategoryData(
      keywords: ['niñ', 'nino', 'niño', 'canguro'],
      icon: Icons.child_care,
      color: Colors.orangeAccent,
    ),
    CategoryData(
      keywords: ['adulto', 'anciano', 'cuidado'],
      icon: Icons.elderly,
      color: Colors.blueGrey,
    ),
    CategoryData(
      keywords: ['mascota', 'perro', 'gato', 'veterin'],
      icon: Icons.pets,
      color: Colors.brown,
    ),
    CategoryData(
      keywords: ['mudanza', 'carga', 'flete'],
      icon: Icons.local_shipping,
      color: Colors.deepOrange,
    ),
    CategoryData(
      keywords: ['reparto', 'delivery', 'entrega'],
      icon: Icons.delivery_dining,
      color: Colors.orange,
    ),
    CategoryData(
      keywords: ['costura', 'ropa', 'sastre'],
      icon: Icons.checkroom,
      color: Colors.purple,
    ),
    CategoryData(
      keywords: ['lavander', 'plancha'],
      icon: Icons.local_laundry_service,
      color: Colors.lightBlue,
    ),
    CategoryData(
      keywords: ['clase', 'tutor', 'asesor'],
      icon: Icons.school,
      color: Colors.indigo,
    ),
    CategoryData(
      keywords: ['legal', 'abogado'],
      icon: Icons.gavel,
      color: Colors.deepPurple,
    ),
  ];

  CategoryData get _categoryData {
    final text = toLowerCase();

    return _categories.firstWhere(
      (category) => category.keywords.any((keyword) => text.contains(keyword)),
      orElse: () => const CategoryData(
        keywords: [],
        icon: Icons.category,
        color: Color(0xFF4F46E5),
      ),
    );
  }

  IconData get toCategoryIcon => _categoryData.icon;

  Color get toCategoryColor => _categoryData.color;
}