import 'package:flutter/material.dart';
import 'quest_Screen.dart'; // Asegúrate de importar correctamente el archivo del formulario

class ProfileIntroPage extends StatelessWidget {
  const ProfileIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón de retroceso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Imagen
            Center(
              child: Image.asset(
                'assets/logo_300.png', // Asegúrate que exista en esa ruta
                height: 200,
              ),
            ),

            const SizedBox(height: 30),

            // Texto principal
            const Text(
              'Termina el llenado\nde tu perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Subtítulo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Al registrarte como prestador de servicios es estrictamente necesario mostrar documentación oficial vigente para verificar tu identidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

            const Spacer(),

            // Botón Comenzar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaborFormPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}