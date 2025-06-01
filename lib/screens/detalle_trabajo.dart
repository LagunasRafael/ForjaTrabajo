import 'package:flutter/material.dart';

class DetalleTrabajo extends StatelessWidget {
  final Map detalle_trabajo;

  const DetalleTrabajo({Key? key, required this.detalle_trabajo}) : super(key: key);

  Color getColor(int step, int activeStep) {
    return step == activeStep ? Color(0xFF005BBB) : Color(0xFFB0C4DE); // azul fuerte y azul claro (gris)
  }

  @override
  Widget build(BuildContext context) {
    int progreso = detalle_trabajo['progreso'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Contenedor azul con sombra y borderRadius
            Container(
              height: 290,
              decoration: BoxDecoration(
                color: Color(0xFF0099FF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(80)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(9, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13.5),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 28, color: Colors.grey[850]),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0, 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 90,
                        backgroundImage: AssetImage('assets/avatar.png'),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Calificación en container azul pequeño con estrella alineado a la izquierda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF0099FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detalle_trabajo['calificacion'] ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.star, color: const Color.fromARGB(255, 238, 255, 2), size: 24),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Nombre alineado a la izquierda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                detalle_trabajo['nombre'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),

            SizedBox(height: 30),

            // Progreso de trabajo - 3 opciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Iniciando
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(0, progreso), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Iniciando',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(0, progreso),
                        ),
                      )
                    ],
                  ),

                  // Por Terminar
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(1, progreso), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Por Terminar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(1, progreso),
                        ),
                      )
                    ],
                  ),

                  // Terminado
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(2, progreso), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Terminado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(2, progreso),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Costo (título y valor alineados a la izquierda)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Costo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    detalle_trabajo['costo'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Descripción / Detalle (título y texto alineados a la izquierda)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    detalle_trabajo['descripcion'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: Container()), // Espacio flexible para que contenido quede arriba
          ],
        ),
      ),
    );
  }
}
