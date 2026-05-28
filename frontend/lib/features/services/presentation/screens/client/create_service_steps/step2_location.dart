import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/create_service_widgets.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/maps/location_picker_widget.dart';

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
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _priceKey = GlobalKey();
  late bool _isLocationLoading;

  @override
  void initState() {
    super.initState();
    _isLocationLoading = widget.lat == null || widget.lng == null;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();

    final priceVal = widget.priceCtrl.text.trim();
    final priceNum = double.tryParse(priceVal);
    final priceInvalid = priceVal.isEmpty || priceNum == null || priceNum <= 0;

    // Trigger form red borders
    Form.maybeOf(context)?.validate();

    if (priceInvalid) {
      final ctx = _priceKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
      return;
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationPickerWidget(
            addressCtrl: widget.addressCtrl,
            lat: widget.lat,
            lng: widget.lng,
            onLocationCaptured: widget.onLocationCaptured,
            onLoadingChanged: (loading) {
              if (mounted) {
                setState(() => _isLocationLoading = loading);
              }
            },
          ),

          const SizedBox(height: 32),

          // ─── Precio ───────────────────────────────────────────
          SizedBox(key: _priceKey),
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
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w300, color: Color(0xFF10B981),
            ),
            decoration: InputDecoration(
              prefixText: "\$ ",
              prefixStyle: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981),
              ),
              hintText: "00.00",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 40),
          StepActionButton(
            text: "Siguiente", 
            onPressed: _handleNext,
            isLoading: _isLocationLoading,
          ),
        ],
      ),
    );
  }
}