import 'package:flutter/material.dart';
import 'detalle_trabajo.dart';

class Trabajos extends StatelessWidget {
  // Cambié las URLs por rutas locales (asegúrate de tener estas imágenes en assets)
  final List<Map<String, dynamic>> trabajos = [
    {
      "nombre": "Jose Armando Juarez Ruiz",
      "valoracion": "4.5 de 5",
      "calificacion": "4.5",
      "icono": "🔥",
      "descripcion":
          "Tengo una fuga en la tubería de la cocina y el grifo gotea todo el tiempo. Necesito que alguien revise, repare y asegure que no haya más problemas",
      "progreso": 0,
      "costo": "\$3000",
      "imagen": "avatar.png"
    },
    {
      "nombre": "Juan Luis Romero Martinez",
      "valoracion": "5 de 5",
      "calificacion": "5.0",
      "icono": "🔥",
      "descripcion":
          "Quiero construir un muro nuevo en mi jardín y necesito que también reparen algunas partes dañadas de la pared que ya tengo",
      "progreso": 1,
      "costo": "\$5000",
      "imagen": "avatar2.png"
    },
    {
      "nombre": "Rafael Lagunas Perez",
      "valoracion": "3.8 de 5",
      "calificacion": "3.8",
      "icono": "🔥",
      "descripcion":
          "Mi auto hace un ruido extraño cuando freno y siento que no está funcionando como antes. Necesito un diagnóstico y reparación urgente",
      "progreso": 2,
      "costo": "\$1500",
      "imagen": "avatar3.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0099FF),
      body: SafeArea(
        child: Column(
          children: [
            // Flecha y título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 28, color: Colors.black),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Trabajos',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Buscar trabajador',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Trabajo aceptados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    // Lista de trabajos
                    ...trabajos.map((trabajo) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetalleTrabajo(detalle_trabajo: trabajo),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF0099FF),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: (trabajo['imagen'] != null && trabajo['imagen'].toString().startsWith('http'))
                                      ? NetworkImage(trabajo['imagen'])
                                      : AssetImage(trabajo['imagen']),
                                  backgroundColor: Colors.grey[200],
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trabajo['nombre'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Valoracion ${trabajo['valoracion']} ',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          trabajo['icono'],
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1, // Índice 1 para la pantalla de trabajos
        onTap: (index) {
          if (index == 1) return;
          Navigator.pop(context);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/homescreen');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/mensajes');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/cleinte_perf');
              break;
          }
        },
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey,
      backgroundColor: theme.surface,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
