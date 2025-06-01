import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isServiceProvider = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Parte superior azul con curva
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Registro",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Completa el formulario para crear tu cuenta",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Formulario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInput("Nombre"),
                  _buildInput("Apellidos"),
                  _buildInput("correo electrónico"),
                  _buildInput("Contraseña", isPassword: true),
                  _buildInput("Confirmar contraseña", isPassword: true),

                  const SizedBox(height: 16),

                  // Switch centrado
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isServiceProvider,
                          onChanged: (value) {
                            setState(() {
                              isServiceProvider = value;
                            });
                          },
                        ),
                        const Text(
                          "Prestador de Servicios",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                      if (isServiceProvider) {
                        //Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Prueba Quest')))));
                        Navigator.pushNamed(context, '/quest');
                      } else {
                        Navigator.pushNamed(context, '/homescreen');
                      }
                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Registrar",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}