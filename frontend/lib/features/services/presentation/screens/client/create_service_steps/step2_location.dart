import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 IMPORTANTE PARA EL FORMATEADOR
import 'package:geolocator/geolocator.dart';

class Step2Location extends StatefulWidget {
  final TextEditingController addressCtrl;
  final TextEditingController priceCtrl;
  final double? lat;
  final double? lng;
  final Function(double lat, double lng) onLocationCaptured;
  final VoidCallback onNext;

  const Step2Location({
    super.key,
    required this.addressCtrl,
    required this.priceCtrl,
    required this.onLocationCaptured,
    required this.onNext,
    this.lat,
    this.lng,
  });

  @override
  State<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends State<Step2Location> {
  bool _isLocating = false;

  // 1. FUNCIÓN MÁGICA PARA OBTENER EL GPS
  Future<void> _handleGetLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'El GPS está desactivado.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permisos denegados.';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Los permisos están denegados permanentemente.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      widget.onLocationCaptured(position.latitude, position.longitude);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📍 Ubicación capturada con éxito"), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = widget.lat != null && widget.lng != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("¿Dónde se realizará?", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          // MAPA INTERACTIVO (CONTENEDOR)
          GestureDetector(
            onTap: _isLocating ? null : _handleGetLocation,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage('https://placehold.co/600x400/e5e7eb/a3a8b8?text=Mapa+Interactivo'), 
                    fit: BoxFit.cover, 
                    opacity: 0.4
                  ),
                border: Border.all(
                  color: hasLocation ? const Color(0xFF10B981) : Colors.grey.shade300,
                  width: hasLocation ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 50, 
                    child: Icon(
                      Icons.location_on, 
                      size: 50, 
                      color: hasLocation ? const Color(0xFF10B981) : const Color(0xFFEF4444)
                    )
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLocating ? Icons.sync : (hasLocation ? Icons.check_circle : Icons.map), 
                            size: 16, 
                            color: const Color(0xFF4F46E5)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLocating ? "Localizando..." : (hasLocation ? "Ubicación lista" : "Capturar ubicación actual"), 
                            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)
                          )
                        ]
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          const Text("Dirección detallada", 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
          const SizedBox(height: 8),
          _buildTextField(
            widget.addressCtrl, 
            "Ej: Calle Morelos #45, Col. Centro", 
            Icons.my_location
          ),
          
          const SizedBox(height: 40),
          const Text("Presupuesto estimado", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          _buildPriceField(widget.priceCtrl),

          const SizedBox(height: 40),
          _buildNextButton(widget.onNext),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: Colors.grey.shade200)
        ),
      ),
    );
  }

  Widget _buildPriceField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // 👇 AQUÍ CONECTAMOS EL FORMATEADOR MÁGICO
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
      decoration: InputDecoration(
        prefixText: "\$ ",
        prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
        hintText: "00.00",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: Colors.grey.shade200)
        ),
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827), 
          padding: const EdgeInsets.symmetric(vertical: 18), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Text("Siguiente", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), 
            SizedBox(width: 8), 
            Icon(Icons.arrow_forward_rounded, color: Colors.white)
          ]
        ),
      ),
    );
  }
}

// 👇 ESTA ES LA CLASE QUE HACE EL TRUCO DEL PRECIO
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Si borramos todo, lo dejamos en blanco
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Quitamos cualquier cosa que no sea número
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si después de limpiar no hay nada, devolvemos 00.00
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '00.00', selection: TextSelection.collapsed(offset: 4));
    }

    // Convertimos los dígitos a decimal dividiendo entre 100
    double value = double.parse(digitsOnly) / 100;
    
    // Lo formateamos a 2 decimales (ej. 12.50)
    String formatted = value.toStringAsFixed(2);

    // Devolvemos el texto con el cursor siempre al final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}