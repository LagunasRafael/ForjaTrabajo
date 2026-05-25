import 'package:flutter/material.dart';

extension CategoryHelper on String {
  
  IconData get toCategoryIcon {
    final name = toLowerCase();
    if (name.contains('plom') || name.contains('fuga')) return Icons.plumbing;
    if (name.contains('electr') || name.contains('luz')) return Icons.electric_bolt;
    if (name.contains('carp') || name.contains('mueb')) return Icons.handyman;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('limp')) return Icons.cleaning_services;
    if (name.contains('mec') || name.contains('auto')) return Icons.car_repair;
        if (name.contains('panad') || name.contains('pan')) return Icons.bakery_dining;
    if (name.contains('jardin') || name.contains('poda')) return Icons.yard;
    if (name.contains('arquitect')) return Icons.architecture;
    if (name.contains('alba') || name.contains('obra')) return Icons.construction;
    if (name.contains('herrero') || name.contains('solda')) return Icons.build;
    if (name.contains('vidrio') || name.contains('ventana')) return Icons.window;
    if (name.contains('cerraj') || name.contains('llave')) return Icons.key;
    return Icons.category; // Ícono por defecto
  }

  Color get toCategoryColor {
    final t = toLowerCase();
    if (t.contains('plom') || t.contains('font')) return Colors.blue; 
    if (t.contains('electr') || t.contains('luz')) return Colors.orange;
    if (t.contains('carp') || t.contains('mueb')) return Colors.brown;
    if (t.contains('pint')) return Colors.teal;
    if (t.contains('limp')) return Colors.lightBlue;
    if (t.contains('mec') || t.contains('auto')) return Colors.blueGrey;
    if (t.contains('panad') || t.contains('pan')) return Colors.deepOrange;
    if (t.contains('jardin') || t.contains('poda')) return Colors.green;
    if (t.contains('arquitect')) return Colors.indigo;
    if (t.contains('alban') || t.contains('obra')) return Colors.brown;
    if (t.contains('herrero') || t.contains('solda')) return Colors.grey;
    if (t.contains('vidri') || t.contains('ventana')) return Colors.cyan;
    if (t.contains('cerraj') || t.contains('llave')) return Colors.amber;
    return const Color(0xFF4F46E5); // Color por defecto
  }
}