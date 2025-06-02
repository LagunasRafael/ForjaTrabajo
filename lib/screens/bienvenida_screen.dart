import 'package:flutter/material.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),

               // Logo en la parte superior
              Image.asset(
              'assets/logo_300.png',
              height: 150, // puedes ajustar el tamaño
              ),

             const SizedBox(height: 200),


              Container(    //contenedor del bienvenido*******************
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20), // redondear los contornos del contenedor
              ),
              child: Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenido', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, color: Colors.white)),
                  Text('', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white)),

                  const SizedBox(height: 40),

                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a pantalla de inicio de sesión
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      // Navegar a pantalla de registro
                      Navigator.pushNamed(context, '/register');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 25, 111, 182),
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

                ]
              )
              ),
              
              const Spacer(),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
