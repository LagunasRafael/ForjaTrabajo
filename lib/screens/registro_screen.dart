import 'package:flutter/material.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tus campos de texto aquí...
                    // (Mantén los mismos TextFormField que ya tenías)

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text('Redirigir a mensajes después de registro:'),
                        const Spacer(),
                        Switch(
                          value: _switchValue,
                          onChanged: (bool value) {
                            setState(() {
                              _switchValue = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cuenta creada')),
                        );
                        
                        if (_switchValue) {
                          // Si el switch está activado, ir a mensajes
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/mensajes',
                            (route) => false, // Elimina todas las rutas anteriores
                          );
                        } else {
                          // Si el switch está desactivado, ir al home
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/home_screen',
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}