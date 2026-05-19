import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/create_service_widgets.dart'; 
import 'package:forja_trabajo/features/services/domain/usecases/location/get_device_location_usecase.dart';

class Step2Location extends ConsumerStatefulWidget {
  final TextEditingController addressCtrl;
  final TextEditingController priceCtrl;
  final double? lat;
  final double? lng;
  final Function(double lat, double lng) onLocationCaptured;
  final VoidCallback onNext;

  const Step2Location({
    super.key, required this.addressCtrl, required this.priceCtrl,
    required this.onLocationCaptured, required this.onNext, this.lat, this.lng,
  });

  @override
  ConsumerState<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends ConsumerState<Step2Location> {
  bool _isLocating = false;

  Future<void> _handleGetLocation() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLocating = true);

    try {
      final locationUseCase = ref.read(getDeviceLocationUseCaseProvider);
      
      // 🚀 AÑADIMOS EL .timeout() PARA EVITAR EL CONGELAMIENTO
      final (latitude, longitude, address) = await locationUseCase.execute().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Si pasan 10 segundos y no hay GPS, forzamos la salida
          throw Exception("No se pudo encontrar la ubicación. Revisa tu GPS o intenta de nuevo.");
        },
      );

      widget.onLocationCaptured(latitude, longitude);
      
      if (mounted) {
        if (address.isNotEmpty && address != "Dirección no encontrada automáticamente") {
           widget.addressCtrl.text = address;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "📍 Ubicación y dirección capturadas",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4F46E5)),
            ),
            backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 120,
              left: 24,
              right: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = widget.lat != null && widget.lng != null;

    // 🛡️ ESCUDO ANTI-CRASH: AbsorbPointer
    // Si _isLocating es true, el usuario NO PUEDE tocar nada en esta pantalla.
    return AbsorbPointer(
      absorbing: _isLocating,
      child: Stack( // Usamos un stack para poner un efecto visual de carga
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ServiceSectionLabel("¿Dónde se realizará?"),
                
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
                        fit: BoxFit.cover, opacity: 0.4
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
                            Icons.location_on, size: 50, 
                            color: hasLocation ? const Color(0xFF10B981) : const Color(0xFFEF4444)
                          )
                        ),
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isLocating ? Icons.sync : (hasLocation ? Icons.check_circle : Icons.map), 
                                  size: 16, color: const Color(0xFF4F46E5)
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
                const ServiceSectionLabel("Dirección detallada"),
                
                // El campo se llenará solo, pero el usuario puede editarlo
                ServiceTextField(
                  controller: widget.addressCtrl, 
                  hint: "Ej: Calle Morelos #45, Col. Centro", 
                  icon: Icons.my_location
                ),
                
                const SizedBox(height: 32),
                const ServiceSectionLabel("Presupuesto estimado"),
                
                TextFormField(
                  controller: widget.priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Indica un precio';
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) return 'El precio debe ser mayor a 0';
                    return null;
                  },
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Color(0xFF10B981)),
                  decoration: InputDecoration(
                    prefixText: "\$ ",
                    prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    hintText: "00.00",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                StepActionButton(text: "Siguiente", onPressed: widget.onNext),
              ],
            ),
          ),
          
          // 🌫️ EFECTO VISUAL: Si está cargando, ponemos una capa semitransparente
          if (_isLocating)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            ),
        ],
      ),
    );
  }
}