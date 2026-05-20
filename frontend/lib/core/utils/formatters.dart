class Formatters {
  /// Formatea un precio de tipo double o String de forma limpia y profesional.
  /// Si es entero, quita los decimales (ej. 150.0 -> "150").
  /// Si tiene centavos, muestra dos decimales (ej. 150.50 -> "150.50").
  static String formatCurrency(dynamic amount) {
    if (amount == null) return "0";
    
    double? parsed;
    if (amount is double) {
      parsed = amount;
    } else if (amount is int) {
      return amount.toString();
    } else if (amount is String) {
      parsed = double.tryParse(amount);
    }
    
    if (parsed == null) return amount.toString();
    
    // Si no tiene decimales reales, mostrar como entero
    if (parsed % 1 == 0) {
      return parsed.toInt().toString();
    }
    
    // Si tiene decimales, mostrar con dos decimales exactos
    return parsed.toStringAsFixed(2);
  }
}
